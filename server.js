const crypto = require("node:crypto");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");

const bcrypt = require("bcryptjs");
const cookieParser = require("cookie-parser");
const express = require("express");
const jwt = require("jsonwebtoken");
const { WebSocketServer } = require("ws");

const { JsonStore } = require("./storage");

const PORT = Number(process.env.PORT || 3000);
const HOST = process.env.HOST || "0.0.0.0";
const JWT_SECRET = process.env.JWT_SECRET || "dev_secret_change_me";
const COOKIE_SECURE_MODE = String(process.env.COOKIE_SECURE || "auto")
  .trim()
  .toLowerCase();
const TRUST_PROXY = Number(process.env.TRUST_PROXY || 1);
const PUBLIC_URL = String(process.env.PUBLIC_URL || "").trim();
const TOKEN_COOKIE_NAME = "messenger_token";
const TOKEN_LIFETIME_MS = 1000 * 60 * 60 * 24 * 7;
const MAX_MESSAGE_LENGTH = 2000;

const store = new JsonStore(path.join(__dirname, "data", "db.json"), {
  users: [],
  conversations: [],
  messages: [],
});

const app = express();
app.set("trust proxy", TRUST_PROXY);
app.use(express.json({ limit: "1mb" }));
app.use(cookieParser());

function normalize(value) {
  return String(value || "").trim();
}

function normalizeLower(value) {
  return normalize(value).toLowerCase();
}

function toPublicUser(user) {
  return {
    id: user.id,
    username: user.username,
    email: user.email,
    createdAt: user.createdAt,
  };
}

function parseCookies(cookieHeader = "") {
  return cookieHeader.split(";").reduce((acc, part) => {
    const [rawKey, ...rest] = part.trim().split("=");
    if (!rawKey) {
      return acc;
    }
    acc[rawKey] = decodeURIComponent(rest.join("="));
    return acc;
  }, {});
}

function shouldUseSecureCookie(req) {
  if (COOKIE_SECURE_MODE === "true" || COOKIE_SECURE_MODE === "1") {
    return true;
  }

  if (COOKIE_SECURE_MODE === "false" || COOKIE_SECURE_MODE === "0") {
    return false;
  }

  return req.secure || req.headers["x-forwarded-proto"] === "https";
}

function setAuthCookie(req, res, userId) {
  const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: "7d" });
  res.cookie(TOKEN_COOKIE_NAME, token, {
    httpOnly: true,
    sameSite: "lax",
    maxAge: TOKEN_LIFETIME_MS,
    secure: shouldUseSecureCookie(req),
  });
}

function clearAuthCookie(req, res) {
  res.clearCookie(TOKEN_COOKIE_NAME, {
    httpOnly: true,
    sameSite: "lax",
    secure: shouldUseSecureCookie(req),
  });
}

async function getAuthUserFromToken(token) {
  if (!token) {
    return null;
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const state = await store.read();
    return state.users.find((user) => user.id === payload.userId) || null;
  } catch {
    return null;
  }
}

async function requireAuth(req, res, next) {
  const token = req.cookies[TOKEN_COOKIE_NAME];
  const user = await getAuthUserFromToken(token);

  if (!user) {
    return res.status(401).json({ error: "Требуется авторизация" });
  }

  req.user = user;
  return next();
}

function findDirectConversation(data, firstUserId, secondUserId) {
  const pair = [firstUserId, secondUserId].sort();
  return data.conversations.find((conversation) => {
    return (
      conversation.type === "direct" &&
      conversation.participantIds.length === 2 &&
      conversation.participantIds[0] === pair[0] &&
      conversation.participantIds[1] === pair[1]
    );
  });
}

function buildConversationPayload(
  conversation,
  viewerId,
  usersById,
  messagesById
) {
  const partnerId = conversation.participantIds.find((id) => id !== viewerId);
  const partner = usersById.get(partnerId);
  const lastMessage = conversation.lastMessageId
    ? messagesById.get(conversation.lastMessageId)
    : null;

  return {
    id: conversation.id,
    type: conversation.type,
    participant: partner ? toPublicUser(partner) : null,
    updatedAt: conversation.updatedAt,
    createdAt: conversation.createdAt,
    lastMessage: lastMessage
      ? {
          id: lastMessage.id,
          conversationId: lastMessage.conversationId,
          senderId: lastMessage.senderId,
          text: lastMessage.text,
          createdAt: lastMessage.createdAt,
        }
      : null,
  };
}

function validateRegistration(username, email, password) {
  if (!/^[a-zA-Z0-9_]{3,24}$/.test(username)) {
    return "Логин: 3-24 символа, буквы/цифры/подчеркивание";
  }

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return "Введите корректный email";
  }

  if (password.length < 6) {
    return "Пароль должен быть минимум 6 символов";
  }

  return null;
}

const socketsByUser = new Map();

function addSocket(userId, socket) {
  if (!socketsByUser.has(userId)) {
    socketsByUser.set(userId, new Set());
  }
  socketsByUser.get(userId).add(socket);
}

function removeSocket(userId, socket) {
  const sockets = socketsByUser.get(userId);
  if (!sockets) {
    return;
  }
  sockets.delete(socket);
  if (sockets.size === 0) {
    socketsByUser.delete(userId);
  }
}

function sendToUser(userId, payload) {
  const sockets = socketsByUser.get(userId);
  if (!sockets) {
    return;
  }
  const serialized = JSON.stringify(payload);
  for (const socket of sockets) {
    if (socket.readyState === socket.OPEN) {
      socket.send(serialized);
    }
  }
}

function getLanAddresses() {
  const interfaces = os.networkInterfaces();
  const addresses = [];

  for (const rows of Object.values(interfaces)) {
    if (!rows) {
      continue;
    }

    for (const item of rows) {
      if (item.family === "IPv4" && !item.internal) {
        addresses.push(item.address);
      }
    }
  }

  return [...new Set(addresses)];
}

app.post("/api/auth/register", async (req, res) => {
  const username = normalize(req.body.username);
  const email = normalize(req.body.email);
  const password = String(req.body.password || "");

  const validationError = validateRegistration(username, email, password);
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }

  const usernameLower = username.toLowerCase();
  const emailLower = email.toLowerCase();
  const passwordHash = await bcrypt.hash(password, 10);

  try {
    const result = await store.withWriteLock((data) => {
      if (data.users.some((user) => user.usernameLower === usernameLower)) {
        const error = new Error("Этот логин уже занят");
        error.code = "USERNAME_TAKEN";
        throw error;
      }

      if (data.users.some((user) => user.emailLower === emailLower)) {
        const error = new Error("Пользователь с таким email уже есть");
        error.code = "EMAIL_TAKEN";
        throw error;
      }

      const now = new Date().toISOString();
      const user = {
        id: crypto.randomUUID(),
        username,
        usernameLower,
        email,
        emailLower,
        passwordHash,
        createdAt: now,
      };

      data.users.push(user);
      return { user: toPublicUser(user) };
    });

    setAuthCookie(req, res, result.user.id);
    return res.status(201).json({ user: result.user });
  } catch (error) {
    if (error.code === "USERNAME_TAKEN" || error.code === "EMAIL_TAKEN") {
      return res.status(409).json({ error: error.message });
    }

    console.error(error);
    return res.status(500).json({ error: "Не удалось создать аккаунт" });
  }
});

app.post("/api/auth/login", async (req, res) => {
  const login = normalizeLower(req.body.login);
  const password = String(req.body.password || "");

  if (!login || !password) {
    return res.status(400).json({ error: "Введите логин/email и пароль" });
  }

  const state = await store.read();
  const user = state.users.find(
    (item) => item.usernameLower === login || item.emailLower === login
  );

  if (!user) {
    return res.status(401).json({ error: "Неверный логин или пароль" });
  }

  const passwordMatch = await bcrypt.compare(password, user.passwordHash);
  if (!passwordMatch) {
    return res.status(401).json({ error: "Неверный логин или пароль" });
  }

  setAuthCookie(req, res, user.id);
  return res.json({ user: toPublicUser(user) });
});

app.post("/api/auth/logout", (req, res) => {
  clearAuthCookie(req, res);
  res.json({ success: true });
});

app.get("/api/auth/me", requireAuth, (req, res) => {
  res.json({ user: toPublicUser(req.user) });
});

app.get("/api/users", requireAuth, async (req, res) => {
  const search = normalizeLower(req.query.search);
  if (search.length < 2) {
    return res.json({ users: [] });
  }

  const state = await store.read();
  const users = state.users
    .filter((user) => user.id !== req.user.id)
    .filter(
      (user) =>
        user.usernameLower.includes(search) || user.emailLower.includes(search)
    )
    .slice(0, 30)
    .map(toPublicUser);

  return res.json({ users });
});

app.get("/api/conversations", requireAuth, async (req, res) => {
  const state = await store.read();
  const usersById = new Map(state.users.map((user) => [user.id, user]));
  const messagesById = new Map(
    state.messages.map((message) => [message.id, message])
  );

  const conversations = state.conversations
    .filter((conversation) => conversation.participantIds.includes(req.user.id))
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
    .map((conversation) =>
      buildConversationPayload(conversation, req.user.id, usersById, messagesById)
    );

  return res.json({ conversations });
});

app.post("/api/conversations/direct", requireAuth, async (req, res) => {
  const targetUserId = normalize(req.body.userId);

  if (!targetUserId) {
    return res.status(400).json({ error: "Не указан userId" });
  }

  if (targetUserId === req.user.id) {
    return res.status(400).json({ error: "Нельзя создать чат с самим собой" });
  }

  try {
    const result = await store.withWriteLock((data) => {
      const targetUserExists = data.users.some((user) => user.id === targetUserId);
      if (!targetUserExists) {
        const error = new Error("Пользователь не найден");
        error.code = "USER_NOT_FOUND";
        throw error;
      }

      let conversation = findDirectConversation(data, req.user.id, targetUserId);
      let created = false;

      if (!conversation) {
        const now = new Date().toISOString();
        conversation = {
          id: crypto.randomUUID(),
          type: "direct",
          participantIds: [req.user.id, targetUserId].sort(),
          createdAt: now,
          updatedAt: now,
          lastMessageId: null,
        };
        data.conversations.push(conversation);
        created = true;
      }

      return { conversationId: conversation.id, created };
    });

    const state = await store.read();
    const conversation = state.conversations.find(
      (item) => item.id === result.conversationId
    );
    const usersById = new Map(state.users.map((user) => [user.id, user]));
    const messagesById = new Map(
      state.messages.map((message) => [message.id, message])
    );

    const payload = buildConversationPayload(
      conversation,
      req.user.id,
      usersById,
      messagesById
    );

    return res.status(result.created ? 201 : 200).json({ conversation: payload });
  } catch (error) {
    if (error.code === "USER_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }

    console.error(error);
    return res.status(500).json({ error: "Не удалось открыть диалог" });
  }
});

app.get("/api/conversations/:id/messages", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  const limit = Math.min(Number(req.query.limit) || 100, 200);

  const state = await store.read();
  const conversation = state.conversations.find((item) => item.id === conversationId);

  if (!conversation || !conversation.participantIds.includes(req.user.id)) {
    return res.status(404).json({ error: "Диалог не найден" });
  }

  const usersById = new Map(state.users.map((user) => [user.id, user]));
  const messages = state.messages
    .filter((message) => message.conversationId === conversationId)
    .sort((a, b) => a.createdAt.localeCompare(b.createdAt))
    .slice(-limit)
    .map((message) => ({
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      text: message.text,
      createdAt: message.createdAt,
      sender: usersById.get(message.senderId)
        ? toPublicUser(usersById.get(message.senderId))
        : null,
    }));

  return res.json({ messages });
});

app.post("/api/conversations/:id/messages", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  const text = normalize(req.body.text);

  if (!text) {
    return res.status(400).json({ error: "Сообщение пустое" });
  }

  if (text.length > MAX_MESSAGE_LENGTH) {
    return res
      .status(400)
      .json({ error: `Максимум ${MAX_MESSAGE_LENGTH} символов` });
  }

  try {
    const result = await store.withWriteLock((data) => {
      const conversation = data.conversations.find((item) => item.id === conversationId);
      if (!conversation || !conversation.participantIds.includes(req.user.id)) {
        const error = new Error("Диалог не найден");
        error.code = "CONVERSATION_NOT_FOUND";
        throw error;
      }

      const now = new Date().toISOString();
      const message = {
        id: crypto.randomUUID(),
        conversationId,
        senderId: req.user.id,
        text,
        createdAt: now,
      };

      data.messages.push(message);
      conversation.updatedAt = now;
      conversation.lastMessageId = message.id;

      return {
        message,
        participantIds: [...conversation.participantIds],
      };
    });

    const state = await store.read();
    const usersById = new Map(state.users.map((user) => [user.id, user]));
    const messagesById = new Map(
      state.messages.map((message) => [message.id, message])
    );
    const conversation = state.conversations.find((item) => item.id === conversationId);
    const sender = usersById.get(req.user.id);

    const messagePayload = {
      id: result.message.id,
      conversationId: result.message.conversationId,
      senderId: result.message.senderId,
      text: result.message.text,
      createdAt: result.message.createdAt,
      sender: sender ? toPublicUser(sender) : null,
    };

    for (const participantId of result.participantIds) {
      const conversationPayload = buildConversationPayload(
        conversation,
        participantId,
        usersById,
        messagesById
      );
      sendToUser(participantId, {
        type: "conversation:update",
        conversation: conversationPayload,
      });
      sendToUser(participantId, {
        type: "message:new",
        message: messagePayload,
      });
    }

    const currentUserConversationPayload = buildConversationPayload(
      conversation,
      req.user.id,
      usersById,
      messagesById
    );

    return res.status(201).json({
      message: messagePayload,
      conversation: currentUserConversationPayload,
    });
  } catch (error) {
    if (error.code === "CONVERSATION_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }

    console.error(error);
    return res.status(500).json({ error: "Не удалось отправить сообщение" });
  }
});

app.use(express.static(path.join(__dirname, "public")));

app.get("*", (req, res, next) => {
  if (req.path.startsWith("/api")) {
    return next();
  }
  return res.sendFile(path.join(__dirname, "public", "index.html"));
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: "/ws" });

wss.on("connection", async (socket, req) => {
  const cookies = parseCookies(req.headers.cookie || "");
  const token = cookies[TOKEN_COOKIE_NAME];
  const user = await getAuthUserFromToken(token);

  if (!user) {
    socket.close(1008, "Unauthorized");
    return;
  }

  addSocket(user.id, socket);
  socket.send(
    JSON.stringify({
      type: "ready",
      user: toPublicUser(user),
    })
  );

  socket.on("message", (raw) => {
    let payload;
    try {
      payload = JSON.parse(raw.toString());
    } catch {
      return;
    }

    if (payload.type === "ping") {
      socket.send(JSON.stringify({ type: "pong" }));
    }
  });

  socket.on("close", () => {
    removeSocket(user.id, socket);
  });

  socket.on("error", () => {
    removeSocket(user.id, socket);
  });
});

store
  .init()
  .then(() => {
    server.listen(PORT, HOST, () => {
      const localEntryHost =
        HOST === "0.0.0.0" || HOST === "::" ? "localhost" : HOST;

      console.log(`Messenger started on http://${localEntryHost}:${PORT}`);

      if (HOST === "0.0.0.0" || HOST === "::") {
        const lanAddresses = getLanAddresses();
        for (const address of lanAddresses) {
          console.log(`LAN: http://${address}:${PORT}`);
        }
      }

      if (PUBLIC_URL) {
        console.log(`Public URL: ${PUBLIC_URL}`);
      }
    });
  })
  .catch((error) => {
    console.error("Failed to initialize storage", error);
    process.exit(1);
  });
