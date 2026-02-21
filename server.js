const crypto = require("node:crypto");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");

require("dotenv").config({ path: path.join(__dirname, ".env"), override: true });

const bcrypt = require("bcryptjs");
const compression = require("compression");
const cookieParser = require("cookie-parser");
const express = require("express");
const jwt = require("jsonwebtoken");
const webPush = require("web-push");
const { WebSocketServer } = require("ws");

const { JsonStore } = require("./storage");

function readRequiredEnv(name, { minLength = 1, forbiddenValues = [] } = {}) {
  const value = String(process.env[name] || "").trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  if (value.length < minLength) {
    throw new Error(`Environment variable ${name} must be at least ${minLength} characters`);
  }
  if (forbiddenValues.includes(value)) {
    throw new Error(`Environment variable ${name} must be rotated and cannot use the default value`);
  }
  return value;
}

const PORT = Number(process.env.PORT || 3000);
const HOST = process.env.HOST || "0.0.0.0";
const JWT_SECRET = readRequiredEnv("JWT_SECRET", {
  minLength: 32,
  forbiddenValues: [
    "change_me",
    "dev_secret_change_me",
  ],
});
const COOKIE_SECURE_MODE = String(process.env.COOKIE_SECURE || "auto")
  .trim()
  .toLowerCase();
const TRUST_PROXY = Number(process.env.TRUST_PROXY || 1);
const PUBLIC_URL = String(process.env.PUBLIC_URL || "").trim();
const TOKEN_COOKIE_NAME = "messenger_token";
const TOKEN_LIFETIME_MS = 1000 * 60 * 60 * 24 * 7;
const BCRYPT_ROUNDS = Number(process.env.BCRYPT_ROUNDS || 10);
const MAX_MESSAGE_LENGTH = 2000;
const MAX_TRANSLATE_LENGTH = 4000;
const MAX_DISPLAY_NAME_LENGTH = 32;
const DISPLAY_NAME_ALLOWED_PATTERN = /^[\p{L}\p{N}_.\- ']+$/u;
const TRANSLATE_API_URL =
  process.env.TRANSLATE_API_URL || "https://api.mymemory.translated.net/get";
const ALLOWED_TRANSLATION_LANGS = new Set([
  "en",
  "ru",
  "de",
  "fr",
  "es",
  "it",
  "tr",
  "uk",
  "pl",
]);
const HEARTBEAT_INTERVAL_MS = 30000;
const OFFLINE_QUEUE_MAX = 100;
const OFFLINE_QUEUE_TTL_MS = 5 * 60 * 1000;
const LOGIN_2FA_CHALLENGE_TTL = "5m";
const TOTP_WINDOW = 1;
const TOTP_PERIOD_MS = 30 * 1000;
const TOTP_DIGITS = 6;
const TOTP_BASE32_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
const TWO_FA_ISSUER = "Wave Messenger";
const MAX_AVATAR_BYTES = Math.floor(1.5 * 1024 * 1024);
const AVATAR_BASE64_LENGTH_LIMIT = Math.ceil((MAX_AVATAR_BYTES * 4) / 3) + 4;
const AVATAR_DATA_URL_PATTERN = /^data:(image\/(?:png|jpeg|jpg|webp|gif));base64,([A-Za-z0-9+/=\s]+)$/i;
const REACTION_PATTERN = /^[\p{Extended_Pictographic}\u200d\uFE0F]+$/u;
const AUTH_RATE_LIMIT_MESSAGE = "Слишком много попыток. Попробуйте позже.";
const SECURITY_CSP = [
  "default-src 'self'",
  "base-uri 'self'",
  "frame-ancestors 'none'",
  "form-action 'self'",
  "script-src 'self'",
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
  "font-src 'self' https://fonts.gstatic.com",
  "img-src 'self' data: blob: https://api.qrserver.com",
  "media-src 'self' data: blob:",
  "connect-src 'self' ws: wss:",
  "manifest-src 'self'",
  "worker-src 'self'",
  "object-src 'none'",
].join("; ");

const VAPID_PUBLIC_KEY = readRequiredEnv("VAPID_PUBLIC_KEY", {
  minLength: 60,
  forbiddenValues: [
    "BMrCnig_P00U_1oqQ5g8ZDGdh4VjMEfMeiHgSOcrRZPPR_Z3fIDOqqMI0dC71IQASKYKR8de4YSkSlCXibWILAg",
  ],
});
const VAPID_PRIVATE_KEY = readRequiredEnv("VAPID_PRIVATE_KEY", {
  minLength: 30,
  forbiddenValues: [
    "x6uSkjR_Aq2b1T4QTiY1J48COvv34mYPqHh7iBGgEuE",
  ],
});
const VAPID_EMAIL = readRequiredEnv("VAPID_EMAIL", { minLength: 10 });

try {
  webPush.setVapidDetails(VAPID_EMAIL, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);
} catch (error) {
  throw new Error(`Failed to configure Web Push VAPID keys: ${error.message}`);
}

const pushSubscriptionsByUser = new Map();
const authRateLimitBuckets = new Map();

const store = new JsonStore(path.join(__dirname, "data", "db.json"), {
  users: [],
  conversations: [],
  messages: [],
  pushSubscriptions: [],
});

const app = express();
app.disable("x-powered-by");
app.set("trust proxy", TRUST_PROXY);
app.use(compression());
app.use(express.json({ limit: "5mb" }));
app.use(cookieParser());
app.use((req, res, next) => {
  res.setHeader("Content-Security-Policy", SECURITY_CSP);
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
  res.setHeader("Cross-Origin-Resource-Policy", "same-origin");
  if (req.secure || req.headers["x-forwarded-proto"] === "https") {
    res.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
  }
  return next();
});

function normalize(value) {
  return String(value || "").trim();
}

function normalizeLower(value) {
  return normalize(value).toLowerCase();
}

function normalizeDisplayName(value) {
  return String(value ?? "")
    .trim()
    .replace(/\s+/g, " ");
}

function getDisplayNameLower(user) {
  const existingLower = normalizeLower(user?.displayNameLower);
  if (existingLower) {
    return existingLower;
  }
  return normalizeDisplayName(user?.displayName).toLowerCase();
}

function getPublicName(user) {
  const displayName = normalizeDisplayName(user?.displayName);
  if (displayName) {
    return displayName;
  }
  return normalize(user?.username);
}

function validateDisplayName(displayName) {
  if (!displayName) {
    return null;
  }

  if (displayName.length > MAX_DISPLAY_NAME_LENGTH) {
    return `Никнейм не может быть длиннее ${MAX_DISPLAY_NAME_LENGTH} символов`;
  }

  if (/[\u0000-\u001f\u007f]/.test(displayName)) {
    return "Никнейм содержит недопустимые символы";
  }

  if (!DISPLAY_NAME_ALLOWED_PATTERN.test(displayName)) {
    return "Никнейм может содержать буквы, цифры, пробел, точку, дефис, апостроф и _";
  }

  if (!/[\p{L}\p{N}]/u.test(displayName)) {
    return "Никнейм должен содержать хотя бы одну букву или цифру";
  }

  return null;
}

function normalizeReactionEmoji(value) {
  const emoji = String(value || "").trim();
  if (!emoji || emoji.length > 16) {
    return "";
  }
  return REACTION_PATTERN.test(emoji) ? emoji : "";
}

function sanitizeAvatarDataUrlForResponse(value) {
  const avatar = String(value || "").trim();
  if (!avatar || !AVATAR_DATA_URL_PATTERN.test(avatar)) {
    return null;
  }
  return avatar;
}

function validateAndNormalizeAvatarDataUrl(value, { allowEmpty = false } = {}) {
  const avatar = String(value || "").trim();
  if (!avatar) {
    if (allowEmpty) {
      return { ok: true, value: null };
    }
    return { ok: false, error: "Нет данных аватарки" };
  }

  const match = avatar.match(AVATAR_DATA_URL_PATTERN);
  if (!match) {
    return {
      ok: false,
      error: "Поддерживаются только изображения PNG/JPEG/WEBP/GIF в формате data URL",
    };
  }

  const mime = match[1].toLowerCase() === "image/jpg" ? "image/jpeg" : match[1].toLowerCase();
  const base64Body = match[2].replace(/\s+/g, "");
  if (!base64Body) {
    return { ok: false, error: "Пустые данные аватарки" };
  }
  if (base64Body.length > AVATAR_BASE64_LENGTH_LIMIT) {
    return { ok: false, error: "Аватарка слишком большая (макс 1.5MB)" };
  }
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(base64Body) || base64Body.length % 4 !== 0) {
    return { ok: false, error: "Некорректный формат аватарки" };
  }

  let decoded;
  try {
    decoded = Buffer.from(base64Body, "base64");
  } catch {
    return { ok: false, error: "Некорректные данные аватарки" };
  }

  if (!decoded.length) {
    return { ok: false, error: "Некорректные данные аватарки" };
  }
  if (decoded.length > MAX_AVATAR_BYTES) {
    return { ok: false, error: "Аватарка слишком большая (макс 1.5MB)" };
  }

  const canonicalBase64 = decoded.toString("base64");
  if (canonicalBase64.replace(/=+$/g, "") !== base64Body.replace(/=+$/g, "")) {
    return { ok: false, error: "Некорректные данные аватарки" };
  }

  return { ok: true, value: `data:${mime};base64,${canonicalBase64}` };
}

function getAuthRateLimitKey(req, scope) {
  const ip = normalize(req.ip || req.socket?.remoteAddress || "unknown");
  let identity = "";
  if (scope === "register") {
    identity = normalizeLower(req.body?.email || req.body?.username);
  } else if (scope === "login") {
    identity = normalizeLower(req.body?.login);
  } else if (scope === "login-2fa") {
    identity = normalize(String(req.body?.challengeToken || "")).slice(0, 64);
  }
  return `${scope}:${ip}:${identity}`;
}

function cleanupAuthRateLimitBuckets(now = Date.now()) {
  for (const [key, bucket] of authRateLimitBuckets.entries()) {
    const activeAttempts = bucket.attempts.filter((timestamp) => now - timestamp <= bucket.windowMs);
    const blocked = bucket.blockedUntil > now;
    if (!blocked && activeAttempts.length === 0) {
      authRateLimitBuckets.delete(key);
      continue;
    }
    bucket.attempts = activeAttempts;
    authRateLimitBuckets.set(key, bucket);
  }
}

function createAuthRateLimiter(scope, { windowMs, maxAttempts, blockMs }) {
  return (req, res, next) => {
    const now = Date.now();
    const key = getAuthRateLimitKey(req, scope);
    const bucket = authRateLimitBuckets.get(key) || {
      attempts: [],
      blockedUntil: 0,
      windowMs,
    };

    if (bucket.blockedUntil > now) {
      const retryAfterSeconds = Math.ceil((bucket.blockedUntil - now) / 1000);
      res.setHeader("Retry-After", String(retryAfterSeconds));
      return res.status(429).json({ error: AUTH_RATE_LIMIT_MESSAGE });
    }

    bucket.attempts = bucket.attempts.filter(
      (timestamp) => now - timestamp <= windowMs
    );

    if (bucket.attempts.length >= maxAttempts) {
      bucket.attempts = [];
      bucket.blockedUntil = now + blockMs;
      bucket.windowMs = windowMs;
      authRateLimitBuckets.set(key, bucket);
      res.setHeader("Retry-After", String(Math.ceil(blockMs / 1000)));
      return res.status(429).json({ error: AUTH_RATE_LIMIT_MESSAGE });
    }

    bucket.attempts.push(now);
    bucket.windowMs = windowMs;
    authRateLimitBuckets.set(key, bucket);

    if (authRateLimitBuckets.size > 5000 || Math.random() < 0.01) {
      cleanupAuthRateLimitBuckets(now);
    }

    return next();
  };
}

const registerAuthRateLimit = createAuthRateLimiter("register", {
  windowMs: 15 * 60 * 1000,
  maxAttempts: 10,
  blockMs: 30 * 60 * 1000,
});
const loginAuthRateLimit = createAuthRateLimiter("login", {
  windowMs: 15 * 60 * 1000,
  maxAttempts: 20,
  blockMs: 30 * 60 * 1000,
});
const login2faAuthRateLimit = createAuthRateLimiter("login-2fa", {
  windowMs: 10 * 60 * 1000,
  maxAttempts: 10,
  blockMs: 30 * 60 * 1000,
});

function decodeHtmlEntities(value) {
  return String(value || "")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#(\d+);/g, (_, code) => {
      const numericCode = Number(code);
      if (!Number.isFinite(numericCode)) {
        return "";
      }
      return String.fromCharCode(numericCode);
    });
}

function detectSourceLanguage(text) {
  const normalized = String(text || "");

  if (/[\u0454\u0456\u0457\u0491\u0404\u0406\u0407\u0490]/u.test(normalized)) {
    return "uk";
  }

  if (/\p{Script=Cyrillic}/u.test(normalized)) {
    return "ru";
  }

  if (/[a-zA-Z]/.test(normalized)) {
    return "en";
  }

  return "en";
}

function normalizeOtpToken(value) {
  return String(value || "")
    .replace(/\D+/g, "")
    .slice(0, TOTP_DIGITS);
}

function generateBase32Secret(size = 32) {
  const bytes = crypto.randomBytes(size);
  let output = "";
  for (const byte of bytes) {
    output += TOTP_BASE32_ALPHABET[byte % TOTP_BASE32_ALPHABET.length];
  }
  return output;
}

function base32ToBuffer(value) {
  const normalized = String(value || "")
    .toUpperCase()
    .replace(/=+$/g, "")
    .replace(/[^A-Z2-7]/g, "");

  let bits = "";
  for (const char of normalized) {
    const index = TOTP_BASE32_ALPHABET.indexOf(char);
    if (index < 0) {
      continue;
    }
    bits += index.toString(2).padStart(5, "0");
  }

  const bytes = [];
  for (let index = 0; index + 8 <= bits.length; index += 8) {
    bytes.push(parseInt(bits.slice(index, index + 8), 2));
  }

  return Buffer.from(bytes);
}

function generateTotpToken(secret, timestamp = Date.now()) {
  const key = base32ToBuffer(secret);
  if (!key.length) {
    return "";
  }

  const counter = Math.floor(timestamp / TOTP_PERIOD_MS);
  const counterBuffer = Buffer.alloc(8);
  const high = Math.floor(counter / 0x100000000);
  const low = counter % 0x100000000;
  counterBuffer.writeUInt32BE(high >>> 0, 0);
  counterBuffer.writeUInt32BE(low >>> 0, 4);

  const hmac = crypto.createHmac("sha1", key).update(counterBuffer).digest();
  const offset = hmac[hmac.length - 1] & 0x0f;
  const binaryCode =
    ((hmac[offset] & 0x7f) << 24) |
    ((hmac[offset + 1] & 0xff) << 16) |
    ((hmac[offset + 2] & 0xff) << 8) |
    (hmac[offset + 3] & 0xff);

  const code = binaryCode % 10 ** TOTP_DIGITS;
  return String(code).padStart(TOTP_DIGITS, "0");
}

function verifyTotpToken(secret, token, timestamp = Date.now()) {
  const normalizedToken = normalizeOtpToken(token);
  if (normalizedToken.length !== TOTP_DIGITS || !secret) {
    return false;
  }

  for (let offset = -TOTP_WINDOW; offset <= TOTP_WINDOW; offset += 1) {
    const candidate = generateTotpToken(secret, timestamp + offset * TOTP_PERIOD_MS);
    if (candidate === normalizedToken) {
      return true;
    }
  }

  return false;
}

function createLoginChallengeToken(userId) {
  return jwt.sign(
    {
      type: "login-2fa",
      userId,
    },
    JWT_SECRET,
    { expiresIn: LOGIN_2FA_CHALLENGE_TTL }
  );
}

function verifyLoginChallengeToken(token) {
  try {
    const payload = jwt.verify(String(token || ""), JWT_SECRET);
    if (payload.type !== "login-2fa") {
      return null;
    }
    return String(payload.userId || "");
  } catch {
    return null;
  }
}

function createOtpAuthUrl(user) {
  const label = encodeURIComponent(`${TWO_FA_ISSUER}:${user.username}`);
  const issuer = encodeURIComponent(TWO_FA_ISSUER);
  const secret = encodeURIComponent(user.twoFactorPendingSecret || "");
  return `otpauth://totp/${label}?secret=${secret}&issuer=${issuer}&algorithm=SHA1&digits=${TOTP_DIGITS}&period=30`;
}

function toPublicUser(user) {
  return {
    id: user.id,
    username: user.username,
    displayName: normalizeDisplayName(user.displayName) || null,
    email: user.email,
    createdAt: user.createdAt,
    twoFactorEnabled: Boolean(user.twoFactor?.enabled),
    avatarUrl: sanitizeAvatarDataUrlForResponse(user.avatarUrl),
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

function getBlockedUserIds(user) {
  if (!Array.isArray(user?.blockedUserIds)) {
    return new Set();
  }
  return new Set(user.blockedUserIds.map((id) => normalize(id)).filter(Boolean));
}

function isUserBlockedBy(blockerUser, targetUserId) {
  return getBlockedUserIds(blockerUser).has(String(targetUserId || ""));
}

function getProtectedConversationIds(user) {
  if (!Array.isArray(user?.chatProtectedConversationIds)) {
    return new Set();
  }
  return new Set(
    user.chatProtectedConversationIds.map((id) => String(id || "")).filter(Boolean)
  );
}

function buildConversationPayload(
  conversation,
  viewerId,
  usersById,
  messagesById
) {
  const viewer = usersById.get(viewerId);
  const lastMessage = conversation.lastMessageId
    ? messagesById.get(conversation.lastMessageId)
    : null;

  if (conversation.type === "group") {
    const participants = conversation.participantIds
      .map((id) => usersById.get(id))
      .filter(Boolean)
      .map((u) => ({ ...toPublicUser(u), online: isUserOnline(u.id), lastSeenAt: lastSeenByUser.get(u.id) || null }));
    return {
      id: conversation.id,
      type: "group",
      name: conversation.name || "Группа",
      avatarUrl: sanitizeAvatarDataUrlForResponse(conversation.avatarUrl),
      creatorId: conversation.creatorId || conversation.participantIds[0] || null,
      participants,
      participantIds: conversation.participantIds,
      updatedAt: conversation.updatedAt,
      createdAt: conversation.createdAt,
      lastMessage: lastMessage
        ? { id: lastMessage.id, conversationId: lastMessage.conversationId, senderId: lastMessage.senderId, text: lastMessage.text, messageType: lastMessage.messageType || "text", encryption: lastMessage.encryption || null, readAt: lastMessage.readAt || null, createdAt: lastMessage.createdAt }
        : null,
    };
  }

  const partnerId = conversation.participantIds.find((id) => id !== viewerId);
  const partner = usersById.get(partnerId);
  const blockedByMe = Boolean(viewer && partnerId && isUserBlockedBy(viewer, partnerId));
  const blockedMe = Boolean(partner && isUserBlockedBy(partner, viewerId));
  const chatProtected = Boolean(
    viewer && getProtectedConversationIds(viewer).has(String(conversation.id || ""))
  );

  return {
    id: conversation.id,
    type: conversation.type,
    participant: partner
      ? {
        ...toPublicUser(partner),
        online: isUserOnline(partnerId),
        lastSeenAt: lastSeenByUser.get(partnerId) || null,
      }
      : null,
    blockedByMe,
    blockedMe,
    chatProtected,
    updatedAt: conversation.updatedAt,
    createdAt: conversation.createdAt,
    lastMessage: lastMessage
      ? {
        id: lastMessage.id,
        conversationId: lastMessage.conversationId,
        senderId: lastMessage.senderId,
        text: lastMessage.text,
        messageType: lastMessage.messageType || "text",
        encryption: lastMessage.encryption || null,
        readAt: lastMessage.readAt || null,
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
const lastSeenByUser = new Map();

const offlineMessageQueue = new Map();
const NON_QUEUEABLE_TYPES = new Set(["typing", "call:signal", "presence:update", "pong"]);

function queueMessageForUser(userId, payload) {
  if (NON_QUEUEABLE_TYPES.has(payload?.type)) return;
  if (!offlineMessageQueue.has(userId)) {
    offlineMessageQueue.set(userId, []);
  }
  const queue = offlineMessageQueue.get(userId);
  const now = Date.now();
  const trimmed = queue.filter((item) => now - item.queuedAt < OFFLINE_QUEUE_TTL_MS);
  if (trimmed.length >= OFFLINE_QUEUE_MAX) {
    trimmed.shift();
  }
  trimmed.push({ payload, queuedAt: now });
  offlineMessageQueue.set(userId, trimmed);
}

function flushQueuedMessages(userId, socket) {
  const queue = offlineMessageQueue.get(userId);
  if (!queue || queue.length === 0) return;
  const now = Date.now();
  for (const item of queue) {
    if (now - item.queuedAt < OFFLINE_QUEUE_TTL_MS && socket.readyState === socket.OPEN) {
      socket.send(JSON.stringify(item.payload));
    }
  }
  offlineMessageQueue.delete(userId);
}

function addSocket(userId, socket) {
  if (!socketsByUser.has(userId)) {
    socketsByUser.set(userId, new Set());
  }
  const sockets = socketsByUser.get(userId);
  const wasOffline = sockets.size === 0;
  sockets.add(socket);
  return wasOffline;
}

function removeSocket(userId, socket) {
  const sockets = socketsByUser.get(userId);
  if (!sockets) {
    return false;
  }
  sockets.delete(socket);
  if (sockets.size === 0) {
    socketsByUser.delete(userId);
    return true;
  }
  return false;
}

function isUserOnline(userId) {
  const sockets = socketsByUser.get(userId);
  return Boolean(sockets && sockets.size > 0);
}

function sendToUser(userId, payload) {
  const sockets = socketsByUser.get(userId);
  if (!sockets || sockets.size === 0) {
    queueMessageForUser(userId, payload);
    return;
  }
  const serialized = JSON.stringify(payload);
  for (const socket of sockets) {
    if (socket.readyState === socket.OPEN) {
      socket.send(serialized);
    }
  }
}

function closeAllUserSockets(userId, code = 1000, reason = "Session ended") {
  const sockets = socketsByUser.get(userId);
  if (!sockets) {
    return;
  }

  for (const socket of [...sockets]) {
    try {
      socket.close(code, reason);
    } catch {
    }
  }
}

function getContactIds(stateData, userId) {
  const contactIds = new Set();
  for (const conversation of stateData.conversations) {
    if (!conversation.participantIds.includes(userId)) continue;
    for (const pid of conversation.participantIds) {
      if (pid !== userId) contactIds.add(pid);
    }
  }
  return contactIds;
}

async function broadcastPresenceChange(userId, online) {
  try {
    if (!online) lastSeenByUser.set(userId, new Date().toISOString());
    const state = await store.read();
    const contactIds = getContactIds(state, userId);
    for (const contactId of contactIds) {
      sendToUser(contactId, {
        type: "presence:update",
        userId,
        online: Boolean(online),
        lastSeenAt: lastSeenByUser.get(userId) || null,
      });
    }
  } catch (error) {
    console.error("Failed to broadcast presence update", error);
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

app.post("/api/auth/register", registerAuthRateLimit, async (req, res) => {
  const username = normalize(req.body.username);
  const email = normalize(req.body.email);
  const password = String(req.body.password || "");

  const validationError = validateRegistration(username, email, password);
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }

  const usernameLower = username.toLowerCase();
  const emailLower = email.toLowerCase();
  const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);

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
        displayName: null,
        displayNameLower: null,
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

app.post("/api/auth/login", loginAuthRateLimit, async (req, res) => {
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

  if (!user.passwordHash) {
    return res.status(401).json({
      error: "Password is not set for this account",
    });
  }

  const passwordMatch = await bcrypt.compare(password, user.passwordHash);
  if (!passwordMatch) {
    return res.status(401).json({ error: "Неверный логин или пароль" });
  }

  if (user.twoFactor?.enabled) {
    const challengeToken = createLoginChallengeToken(user.id);
    return res.status(202).json({
      requires2fa: true,
      challengeToken,
    });
  }

  setAuthCookie(req, res, user.id);
  return res.json({ user: toPublicUser(user) });
});

app.post("/api/auth/login/2fa", login2faAuthRateLimit, async (req, res) => {
  const challengeToken = String(req.body.challengeToken || "");
  const token = normalizeOtpToken(req.body.token);

  if (!challengeToken || token.length !== TOTP_DIGITS) {
    return res.status(400).json({ error: "Invalid 2FA code or challenge token" });
  }

  const userId = verifyLoginChallengeToken(challengeToken);
  if (!userId) {
    return res.status(401).json({ error: "2FA challenge has expired" });
  }

  const state = await store.read();
  const user = state.users.find((item) => item.id === userId);
  if (!user || !user.twoFactor?.enabled || !user.twoFactor.secret) {
    return res.status(401).json({ error: "2FA is not enabled for this account" });
  }

  if (!verifyTotpToken(user.twoFactor.secret, token)) {
    return res.status(401).json({ error: "Invalid 2FA code" });
  }

  setAuthCookie(req, res, user.id);
  return res.json({ user: toPublicUser(user) });
});

app.post("/api/auth/logout", (req, res) => {
  clearAuthCookie(req, res);
  res.json({ success: true });
});

app.delete("/api/auth/account", requireAuth, async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await store.withWriteLock((data) => {
      const userIndex = data.users.findIndex((user) => user.id === userId);
      if (userIndex < 0) {
        const error = new Error("Пользователь не найден");
        error.code = "USER_NOT_FOUND";
        throw error;
      }

      const deletedConversationIds = [];
      const participantIds = new Set();

      for (const conversation of data.conversations) {
        if (!conversation.participantIds.includes(userId)) {
          continue;
        }
        deletedConversationIds.push(conversation.id);
        for (const participantId of conversation.participantIds) {
          if (participantId !== userId) {
            participantIds.add(participantId);
          }
        }
      }

      const deletedConversationSet = new Set(deletedConversationIds);
      data.conversations = data.conversations.filter(
        (conversation) => !deletedConversationSet.has(conversation.id)
      );
      data.messages = data.messages.filter(
        (message) => !deletedConversationSet.has(message.conversationId)
      );

      const normalizedUserId = normalize(userId);
      for (const user of data.users) {
        if (user.id !== userId && Array.isArray(user.blockedUserIds)) {
          user.blockedUserIds = user.blockedUserIds.filter(
            (id) => normalize(id) !== normalizedUserId
          );
        }
        if (Array.isArray(user.chatProtectedConversationIds)) {
          user.chatProtectedConversationIds = user.chatProtectedConversationIds.filter(
            (conversationId) => !deletedConversationSet.has(conversationId)
          );
        }
      }

      data.users.splice(userIndex, 1);

      return {
        deletedConversationIds,
        participantIds: [...participantIds],
      };
    });

    clearAuthCookie(req, res);

    for (const participantId of result.participantIds) {
      for (const conversationId of result.deletedConversationIds) {
        sendToUser(participantId, {
          type: "conversation:deleted",
          conversationId,
        });
      }
    }

    closeAllUserSockets(userId, 1000, "Account deleted");
    return res.json({ deleted: true });
  } catch (error) {
    if (error.code === "USER_NOT_FOUND") {
      clearAuthCookie(req, res);
      return res.status(404).json({ error: error.message });
    }
    console.error(error);
    return res.status(500).json({ error: "Не удалось удалить аккаунт" });
  }
});

app.get("/api/auth/me", requireAuth, (req, res) => {
  res.json({ user: toPublicUser(req.user) });
});

app.get("/api/auth/2fa/status", requireAuth, (req, res) => {
  return res.json({ enabled: Boolean(req.user.twoFactor?.enabled) });
});

app.post("/api/auth/2fa/verify", requireAuth, async (req, res) => {
  const token = normalizeOtpToken(req.body.token);
  if (token.length !== TOTP_DIGITS) {
    return res.status(400).json({ error: "Invalid 2FA code" });
  }

  try {
    const state = await store.read();
    const user = state.users.find((item) => item.id === req.user.id);
    if (!user || !user.twoFactor?.enabled || !user.twoFactor.secret) {
      return res.status(400).json({ error: "2FA is not enabled" });
    }

    if (!verifyTotpToken(user.twoFactor.secret, token)) {
      return res.status(401).json({ error: "Invalid 2FA code" });
    }

    return res.json({ verified: true });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: "Failed to verify 2FA code" });
  }
});

app.post("/api/auth/2fa/setup", requireAuth, async (req, res) => {
  try {
    const result = await store.withWriteLock((data) => {
      const user = data.users.find((item) => item.id === req.user.id);
      if (!user) {
        const error = new Error("User not found");
        error.code = "USER_NOT_FOUND";
        throw error;
      }

      user.twoFactorPendingSecret = generateBase32Secret(32);
      const otpauthUrl = createOtpAuthUrl(user);
      return {
        secret: user.twoFactorPendingSecret,
        otpauthUrl,
      };
    });

    return res.json(result);
  } catch (error) {
    if (error.code === "USER_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }
    console.error(error);
    return res.status(500).json({ error: "Failed to create 2FA setup" });
  }
});

app.post("/api/auth/2fa/enable", requireAuth, async (req, res) => {
  const token = normalizeOtpToken(req.body.token);
  if (token.length !== TOTP_DIGITS) {
    return res.status(400).json({ error: "Invalid 2FA code" });
  }

  try {
    await store.withWriteLock((data) => {
      const user = data.users.find((item) => item.id === req.user.id);
      if (!user || !user.twoFactorPendingSecret) {
        const error = new Error("2FA setup is not initialized");
        error.code = "TWOFA_SETUP_MISSING";
        throw error;
      }

      if (!verifyTotpToken(user.twoFactorPendingSecret, token)) {
        const error = new Error("Invalid 2FA code");
        error.code = "INVALID_2FA_CODE";
        throw error;
      }

      user.twoFactor = {
        enabled: true,
        secret: user.twoFactorPendingSecret,
      };
      delete user.twoFactorPendingSecret;
      return null;
    });

    return res.json({ enabled: true });
  } catch (error) {
    if (error.code === "TWOFA_SETUP_MISSING") {
      return res.status(400).json({ error: error.message });
    }
    if (error.code === "INVALID_2FA_CODE") {
      return res.status(401).json({ error: error.message });
    }
    console.error(error);
    return res.status(500).json({ error: "Failed to enable 2FA" });
  }
});

app.post("/api/auth/2fa/disable", requireAuth, async (req, res) => {
  const token = normalizeOtpToken(req.body.token);
  if (token.length !== TOTP_DIGITS) {
    return res.status(400).json({ error: "Invalid 2FA code" });
  }

  try {
    await store.withWriteLock((data) => {
      const user = data.users.find((item) => item.id === req.user.id);
      if (!user || !user.twoFactor?.enabled || !user.twoFactor.secret) {
        const error = new Error("2FA is not enabled");
        error.code = "TWOFA_DISABLED";
        throw error;
      }

      if (!verifyTotpToken(user.twoFactor.secret, token)) {
        const error = new Error("Invalid 2FA code");
        error.code = "INVALID_2FA_CODE";
        throw error;
      }

      delete user.twoFactor;
      delete user.twoFactorPendingSecret;
      delete user.chatProtectedConversationIds;
      return null;
    });

    return res.json({ enabled: false });
  } catch (error) {
    if (error.code === "TWOFA_DISABLED") {
      return res.status(400).json({ error: error.message });
    }
    if (error.code === "INVALID_2FA_CODE") {
      return res.status(401).json({ error: error.message });
    }
    console.error(error);
    return res.status(500).json({ error: "Failed to disable 2FA" });
  }
});

app.post("/api/translate", requireAuth, async (req, res) => {
  const text = String(req.body.text || "").trim();
  const targetLang = normalizeLower(req.body.targetLang);
  const sourceLangInput = normalizeLower(req.body.sourceLang);

  if (!text) {
    return res.status(400).json({ error: "Пустой текст для перевода" });
  }

  if (text.length > MAX_TRANSLATE_LENGTH) {
    return res
      .status(400)
      .json({ error: `Максимум ${MAX_TRANSLATE_LENGTH} символов для перевода` });
  }

  if (!ALLOWED_TRANSLATION_LANGS.has(targetLang)) {
    return res.status(400).json({ error: "Неподдерживаемый язык перевода" });
  }

  const sourceLang = ALLOWED_TRANSLATION_LANGS.has(sourceLangInput)
    ? sourceLangInput
    : detectSourceLanguage(text);

  if (sourceLang === targetLang) {
    return res.json({ translatedText: text });
  }

  try {
    const url = new URL(TRANSLATE_API_URL);
    url.searchParams.set("q", text);
    url.searchParams.set("langpair", `${sourceLang}|${targetLang}`);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);
    let response;
    try {
      response = await fetch(url, {
        method: "GET",
        headers: { Accept: "application/json" },
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeoutId);
    }

    if (!response.ok) {
      throw new Error(`Translate API HTTP ${response.status}`);
    }

    let payload = {};
    try {
      payload = await response.json();
    } catch {
      payload = {};
    }

    if (payload.responseStatus && Number(payload.responseStatus) !== 200) {
      return res.json({ translatedText: text });
    }

    const translatedText = normalize(
      decodeHtmlEntities(payload?.responseData?.translatedText || "")
    );

    if (!translatedText || /invalid source language/i.test(translatedText)) {
      return res.json({ translatedText: text });
    }

    return res.json({ translatedText });
  } catch (error) {
    console.error("Translation request failed", error);
    return res.status(502).json({ error: "Не удалось выполнить перевод" });
  }
});

async function handleUsersSearch(req, res) {
  const search = normalizeLower(req.query.search || req.query.q);
  if (search.length < 2) {
    return res.json({ users: [] });
  }

  const state = await store.read();
  const users = state.users
    .filter((user) => user.id !== req.user.id)
    .filter((user) => {
      const usernameLower = normalizeLower(user.usernameLower || user.username);
      const emailLower = normalizeLower(user.emailLower || user.email);
      const displayNameLower = getDisplayNameLower(user);
      return (
        usernameLower.includes(search) ||
        emailLower.includes(search) ||
        displayNameLower.includes(search)
      );
    })
    .slice(0, 30)
    .map(toPublicUser);

  return res.json({ users });
}

app.get("/api/users", requireAuth, handleUsersSearch);
app.get("/api/users/search", requireAuth, handleUsersSearch);

async function toggleUserBlock(req, res, shouldBlock) {
  const targetUserId = normalize(req.params.id);
  const userId = req.user.id;

  if (!targetUserId || targetUserId === userId) {
    return res.status(400).json({ error: "Некорректный пользователь для блокировки" });
  }

  try {
    const result = await store.withWriteLock((data) => {
      const me = data.users.find((user) => user.id === userId);
      const target = data.users.find((user) => user.id === targetUserId);
      if (!me || !target) {
        const error = new Error("Пользователь не найден");
        error.code = "USER_NOT_FOUND";
        throw error;
      }

      const normalizedTargetUserId = normalize(targetUserId);
      const blockedUserIds = new Set(
        (Array.isArray(me.blockedUserIds) ? me.blockedUserIds : [])
          .map((id) => normalize(id))
          .filter(Boolean)
      );
      if (shouldBlock) {
        blockedUserIds.add(normalizedTargetUserId);
      } else {
        blockedUserIds.delete(normalizedTargetUserId);
      }
      me.blockedUserIds = [...blockedUserIds];

      const conversation = findDirectConversation(data, userId, targetUserId);
      return {
        conversationId: conversation ? conversation.id : null,
      };
    });

    let conversationPayload = null;
    if (result.conversationId) {
      const state = await store.read();
      const usersById = new Map(state.users.map((user) => [user.id, user]));
      const messagesById = new Map(
        state.messages.map((message) => [message.id, message])
      );
      const conversation = state.conversations.find(
        (item) => item.id === result.conversationId
      );

      if (conversation) {
        for (const participantId of conversation.participantIds) {
          const payload = buildConversationPayload(
            conversation,
            participantId,
            usersById,
            messagesById
          );
          sendToUser(participantId, {
            type: "conversation:update",
            conversation: payload,
          });
          if (participantId === userId) {
            conversationPayload = payload;
          }
        }
      }
    }

    return res.json({
      success: true,
      blocked: Boolean(shouldBlock),
      conversation: conversationPayload,
    });
  } catch (error) {
    if (error.code === "USER_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }
    console.error(error);
    return res.status(500).json({ error: "Не удалось обновить блокировку пользователя" });
  }
}

app.post("/api/users/:id/block", requireAuth, async (req, res) => {
  return toggleUserBlock(req, res, true);
});

app.post("/api/users/:id/unblock", requireAuth, async (req, res) => {
  return toggleUserBlock(req, res, false);
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

app.post("/api/conversations/:id/protection", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  const locked = Boolean(req.body?.locked);

  try {
    await store.withWriteLock((data) => {
      const user = data.users.find((item) => item.id === req.user.id);
      const conversation = data.conversations.find((item) => item.id === conversationId);

      if (!user || !conversation || !conversation.participantIds.includes(req.user.id)) {
        const error = new Error("Р”РёР°Р»РѕРі РЅРµ РЅР°Р№РґРµРЅ");
        error.code = "CONVERSATION_NOT_FOUND";
        throw error;
      }

      if (locked && !user.twoFactor?.enabled) {
        const error = new Error("Р”Р»СЏ Р·Р°С‰РёС‚С‹ С‡Р°С‚Р° РЅСѓР¶РЅР° РІРєР»СЋС‡РµРЅРЅР°СЏ 2FA");
        error.code = "TWOFA_REQUIRED";
        throw error;
      }

      if (!Array.isArray(user.chatProtectedConversationIds)) {
        user.chatProtectedConversationIds = [];
      }

      if (locked) {
        if (!user.chatProtectedConversationIds.includes(conversationId)) {
          user.chatProtectedConversationIds.push(conversationId);
        }
      } else {
        user.chatProtectedConversationIds = user.chatProtectedConversationIds.filter(
          (id) => id !== conversationId
        );
      }

      return null;
    });

    const state = await store.read();
    const usersById = new Map(state.users.map((user) => [user.id, user]));
    const messagesById = new Map(
      state.messages.map((message) => [message.id, message])
    );
    const conversation = state.conversations.find((item) => item.id === conversationId);
    if (!conversation || !conversation.participantIds.includes(req.user.id)) {
      return res.status(404).json({ error: "Р”РёР°Р»РѕРі РЅРµ РЅР°Р№РґРµРЅ" });
    }

    const conversationPayload = buildConversationPayload(
      conversation,
      req.user.id,
      usersById,
      messagesById
    );
    sendToUser(req.user.id, {
      type: "conversation:update",
      conversation: conversationPayload,
    });

    return res.json({ conversation: conversationPayload });
  } catch (error) {
    if (error.code === "CONVERSATION_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }
    if (error.code === "TWOFA_REQUIRED") {
      return res.status(400).json({ error: error.message });
    }
    console.error(error);
    return res.status(500).json({ error: "РќРµ СѓРґР°Р»РѕСЃСЊ РѕР±РЅРѕРІРёС‚СЊ Р·Р°С‰РёС‚Сѓ С‡Р°С‚Р°" });
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
      messageType: message.messageType || "text",
      encryption: message.encryption || null,
      replyToId: message.replyToId || null,
      forwardFromId: message.forwardFromId || null,
      clientMessageId: message.clientMessageId || null,
      imageData: message.imageData || null,
      voiceData: message.voiceData || null,
      reactions: message.reactions || [],
      editedAt: message.editedAt || null,
      readAt: message.readAt || null,
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
  const encryptionType = normalizeLower(req.body.encryption?.type);
  const replyToId = normalize(req.body.replyToId);
  const forwardFromId = normalize(req.body.forwardFromId);
  const clientMessageId = normalize(req.body.clientMessageId).slice(0, 128);
  const imageData = String(req.body.imageData || "").trim();
  const voiceData = String(req.body.voiceData || "").trim();
  const messageType = imageData ? "image" : voiceData ? "voice" : "text";
  const encryption =
    messageType === "text" && encryptionType === "vigenere"
      ? { type: "vigenere" }
      : null;

  if (!text && !voiceData && !imageData) {
    return res.status(400).json({ error: "Сообщение пустое" });
  }

  if (imageData && !imageData.startsWith("data:image/png;base64,")) {
    return res.status(400).json({ error: "Через Ctrl+V поддерживаются только скриншоты PNG" });
  }

  if (imageData && voiceData) {
    return res.status(400).json({ error: "Нельзя отправить скриншот и голосовое в одном сообщении" });
  }

  if (imageData && imageData.length > 4_200_000) {
    return res.status(400).json({ error: "Скриншот слишком большой" });
  }

  if (text && text.length > MAX_MESSAGE_LENGTH) {
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

      if (conversation.type === "direct") {
        const receiverId = conversation.participantIds.find((id) => id !== req.user.id);
        const receiver = data.users.find((user) => user.id === receiverId);
        if (receiver && isUserBlockedBy(receiver, req.user.id)) {
          const error = new Error("Собеседник вас заблокировал");
          error.code = "BLOCKED_BY_RECEIVER";
          throw error;
        }
      }

      const now = new Date().toISOString();
      const message = {
        id: crypto.randomUUID(),
        conversationId,
        senderId: req.user.id,
        text: text || (messageType === "image" ? "🖼 Скриншот" : ""),
        messageType,
        encryption,
        replyToId: replyToId || null,
        forwardFromId: forwardFromId || null,
        clientMessageId: clientMessageId || null,
        imageData: imageData || null,
        voiceData: voiceData || null,
        reactions: [],
        readAt: null,
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
      messageType: result.message.messageType || "text",
      encryption: result.message.encryption || null,
      replyToId: result.message.replyToId || null,
      forwardFromId: result.message.forwardFromId || null,
      clientMessageId: result.message.clientMessageId || null,
      imageData: result.message.imageData || null,
      voiceData: result.message.voiceData || null,
      reactions: result.message.reactions || [],
      editedAt: result.message.editedAt || null,
      readAt: result.message.readAt || null,
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

      if (participantId !== req.user.id) {
        sendPushNotificationToUser(participantId, {
          title: sender ? getPublicName(sender) : "Новое сообщение",
          body: messagePayload.messageType === "voice"
            ? "🎤 Голосовое сообщение"
            : messagePayload.messageType === "image"
              ? "🖼 Скриншот"
              : (messagePayload.text || "").slice(0, 100),
          tag: `wave-msg-${conversationId}`,
          conversationId,
          url: "/",
        });
      }
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
    if (error.code === "BLOCKED_BY_RECEIVER") {
      return res.status(403).json({ error: error.message });
    }

    console.error(error);
    return res.status(500).json({ error: "Не удалось отправить сообщение" });
  }
});

app.post("/api/conversations/:id/read", requireAuth, async (req, res) => {
  const conversationId = req.params.id;

  try {
    const result = await store.withWriteLock((data) => {
      const conversation = data.conversations.find((item) => item.id === conversationId);
      if (!conversation || !conversation.participantIds.includes(req.user.id)) {
        const error = new Error("Диалог не найден");
        error.code = "CONVERSATION_NOT_FOUND";
        throw error;
      }

      const unreadMessages = data.messages.filter(
        (message) =>
          message.conversationId === conversationId &&
          message.senderId !== req.user.id &&
          !message.readAt
      );

      if (unreadMessages.length === 0) {
        return {
          readMessageIds: [],
          participantIds: [...conversation.participantIds],
          readAt: null,
        };
      }

      const readAt = new Date().toISOString();
      for (const message of unreadMessages) {
        message.readAt = readAt;
      }

      return {
        readMessageIds: unreadMessages.map((message) => message.id),
        participantIds: [...conversation.participantIds],
        readAt,
      };
    });

    const state = await store.read();
    const usersById = new Map(state.users.map((user) => [user.id, user]));
    const messagesById = new Map(
      state.messages.map((message) => [message.id, message])
    );
    const conversation = state.conversations.find((item) => item.id === conversationId);

    if (result.readMessageIds.length > 0) {
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
          type: "message:read",
          conversationId,
          readerId: req.user.id,
          readAt: result.readAt,
          messageIds: result.readMessageIds,
        });
      }
    }

    const currentUserConversationPayload = buildConversationPayload(
      conversation,
      req.user.id,
      usersById,
      messagesById
    );

    return res.json({
      readMessageIds: result.readMessageIds,
      readAt: result.readAt,
      conversation: currentUserConversationPayload,
    });
  } catch (error) {
    if (error.code === "CONVERSATION_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }

    console.error(error);
    return res.status(500).json({ error: "Не удалось обновить статус прочтения" });
  }
});

app.delete("/api/conversations/:id/messages", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  const rawMessageIds = Array.isArray(req.body?.messageIds) ? req.body.messageIds : [];
  const messageIds = [...new Set(rawMessageIds.map((item) => normalize(item)).filter(Boolean))];

  if (messageIds.length === 0) {
    return res.status(400).json({ error: "Не выбраны сообщения для удаления" });
  }

  try {
    const result = await store.withWriteLock((data) => {
      const conversation = data.conversations.find((item) => item.id === conversationId);
      if (!conversation || !conversation.participantIds.includes(req.user.id)) {
        const error = new Error("Диалог не найден");
        error.code = "CONVERSATION_NOT_FOUND";
        throw error;
      }

      const targetIds = new Set(messageIds);
      const existingToDelete = data.messages.filter(
        (message) =>
          message.conversationId === conversationId && targetIds.has(message.id)
      );

      if (existingToDelete.length === 0) {
        const error = new Error("Сообщения не найдены");
        error.code = "MESSAGES_NOT_FOUND";
        throw error;
      }

      const deletedIds = existingToDelete.map((message) => message.id);
      const deletedSet = new Set(deletedIds);
      data.messages = data.messages.filter(
        (message) =>
          !(message.conversationId === conversationId && deletedSet.has(message.id))
      );

      const remaining = data.messages
        .filter((message) => message.conversationId === conversationId)
        .sort((a, b) => a.createdAt.localeCompare(b.createdAt));
      const lastMessage = remaining.length > 0 ? remaining[remaining.length - 1] : null;
      conversation.lastMessageId = lastMessage ? lastMessage.id : null;
      conversation.updatedAt = lastMessage
        ? lastMessage.createdAt
        : new Date().toISOString();

      return {
        deletedMessageIds: deletedIds,
        participantIds: [...conversation.participantIds],
      };
    });

    const state = await store.read();
    const usersById = new Map(state.users.map((user) => [user.id, user]));
    const messagesById = new Map(
      state.messages.map((message) => [message.id, message])
    );
    const conversation = state.conversations.find((item) => item.id === conversationId);

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
        type: "message:deleted",
        conversationId,
        messageIds: result.deletedMessageIds,
      });
    }

    const currentUserConversationPayload = buildConversationPayload(
      conversation,
      req.user.id,
      usersById,
      messagesById
    );

    return res.json({
      deletedMessageIds: result.deletedMessageIds,
      conversation: currentUserConversationPayload,
    });
  } catch (error) {
    if (error.code === "CONVERSATION_NOT_FOUND" || error.code === "MESSAGES_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }

    console.error(error);
    return res.status(500).json({ error: "Не удалось удалить сообщения" });
  }
});

app.delete("/api/conversations/:id/messages/all", requireAuth, async (req, res) => {
  const conversationId = req.params.id;

  try {
    const result = await store.withWriteLock((data) => {
      const conversation = data.conversations.find((item) => item.id === conversationId);
      if (!conversation || !conversation.participantIds.includes(req.user.id)) {
        const error = new Error("Ð”Ð¸Ð°Ð»Ð¾Ð³ Ð½Ðµ Ð½Ð°Ð¹Ð´ÐµÐ½");
        error.code = "CONVERSATION_NOT_FOUND";
        throw error;
      }

      const deletedMessageIds = data.messages
        .filter((message) => message.conversationId === conversationId)
        .map((message) => message.id);

      if (deletedMessageIds.length > 0) {
        const deletedSet = new Set(deletedMessageIds);
        data.messages = data.messages.filter(
          (message) =>
            !(message.conversationId === conversationId && deletedSet.has(message.id))
        );
      }

      conversation.lastMessageId = null;
      conversation.updatedAt = new Date().toISOString();

      return {
        deletedMessageIds,
        participantIds: [...conversation.participantIds],
      };
    });

    const state = await store.read();
    const usersById = new Map(state.users.map((user) => [user.id, user]));
    const messagesById = new Map(
      state.messages.map((message) => [message.id, message])
    );
    const conversation = state.conversations.find((item) => item.id === conversationId);

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
      if (result.deletedMessageIds.length > 0) {
        sendToUser(participantId, {
          type: "message:deleted",
          conversationId,
          messageIds: result.deletedMessageIds,
        });
      }
    }

    const currentUserConversationPayload = buildConversationPayload(
      conversation,
      req.user.id,
      usersById,
      messagesById
    );

    return res.json({
      deletedMessageIds: result.deletedMessageIds,
      conversation: currentUserConversationPayload,
    });
  } catch (error) {
    if (error.code === "CONVERSATION_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }

    console.error(error);
    return res.status(500).json({ error: "ÐÐµ ÑƒÐ´Ð°Ð»Ð¾ÑÑŒ Ð¾Ñ‡Ð¸ÑÑ‚Ð¸Ñ‚ÑŒ Ð¸ÑÑ‚Ð¾Ñ€Ð¸ÑŽ Ñ‡Ð°Ñ‚Ð°" });
  }
});

app.delete("/api/conversations/:id", requireAuth, async (req, res) => {
  const conversationId = req.params.id;

  try {
    const result = await store.withWriteLock((data) => {
      const conversation = data.conversations.find((item) => item.id === conversationId);
      if (!conversation || !conversation.participantIds.includes(req.user.id)) {
        const error = new Error("Диалог не найден");
        error.code = "CONVERSATION_NOT_FOUND";
        throw error;
      }

      const participantIds = [...conversation.participantIds];
      data.conversations = data.conversations.filter((item) => item.id !== conversationId);
      data.messages = data.messages.filter(
        (message) => message.conversationId !== conversationId
      );
      for (const user of data.users) {
        if (!Array.isArray(user.chatProtectedConversationIds)) {
          continue;
        }
        user.chatProtectedConversationIds = user.chatProtectedConversationIds.filter(
          (id) => id !== conversationId
        );
      }

      return { participantIds };
    });

    for (const participantId of result.participantIds) {
      sendToUser(participantId, {
        type: "conversation:deleted",
        conversationId,
      });
    }

    return res.json({ deletedConversationId: conversationId });
  } catch (error) {
    if (error.code === "CONVERSATION_NOT_FOUND") {
      return res.status(404).json({ error: error.message });
    }

    console.error(error);
    return res.status(500).json({ error: "Не удалось удалить чат" });
  }
});

// --- Avatar upload ---
app.post("/api/auth/avatar", requireAuth, async (req, res) => {
  const avatarResult = validateAndNormalizeAvatarDataUrl(req.body.avatar);
  if (!avatarResult.ok) {
    return res.status(400).json({ error: avatarResult.error });
  }
  const avatarData = avatarResult.value;
  try {
    await store.withWriteLock((data) => {
      const user = data.users.find((u) => u.id === req.user.id);
      if (!user) throw Object.assign(new Error("User not found"), { code: "NOT_FOUND" });
      user.avatarUrl = avatarData;
    });
    return res.json({ avatarUrl: avatarData });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Не удалось сохранить аватарку" });
  }
});

// --- Profile update (displayName) ---
app.put("/api/auth/profile", requireAuth, async (req, res) => {
  const displayName = normalizeDisplayName(req.body.displayName);
  const displayNameValidationError = validateDisplayName(displayName);
  if (displayNameValidationError) {
    return res.status(400).json({ error: displayNameValidationError });
  }

  const displayNameLower = displayName ? displayName.toLowerCase() : null;

  try {
    const result = await store.withWriteLock((data) => {
      const user = data.users.find((u) => u.id === req.user.id);
      if (!user) throw Object.assign(new Error("User not found"), { code: "NOT_FOUND" });

      if (displayNameLower) {
        const displayNameTaken = data.users.some((candidate) => {
          if (candidate.id === req.user.id) {
            return false;
          }

          return (
            getDisplayNameLower(candidate) === displayNameLower ||
            normalizeLower(candidate.usernameLower || candidate.username) === displayNameLower
          );
        });

        if (displayNameTaken) {
          throw Object.assign(
            new Error("\u042d\u0442\u043e\u0442 \u043d\u0438\u043a\u043d\u0435\u0439\u043c \u0443\u0436\u0435 \u0437\u0430\u043d\u044f\u0442"),
            {
              code: "DISPLAY_NAME_TAKEN",
            }
          );
        }
      }

      user.displayName = displayName || null;
      user.displayNameLower = displayNameLower;

      const conversationIds = data.conversations
        .filter((conversation) => conversation.participantIds.includes(req.user.id))
        .map((conversation) => conversation.id);

      return {
        displayName: user.displayName || null,
        conversationIds,
      };
    });

    if (result.conversationIds.length > 0) {
      const state = await store.read();
      const usersById = new Map(state.users.map((user) => [user.id, user]));
      const messagesById = new Map(
        state.messages.map((message) => [message.id, message])
      );
      const conversationsById = new Map(
        state.conversations.map((conversation) => [conversation.id, conversation])
      );

      for (const conversationId of result.conversationIds) {
        const conversation = conversationsById.get(conversationId);
        if (!conversation) {
          continue;
        }

        for (const participantId of conversation.participantIds) {
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
        }
      }
    }

    return res.json({ displayName: result.displayName });
  } catch (e) {
    if (e.code === "DISPLAY_NAME_TAKEN") {
      return res.status(409).json({ error: e.message });
    }

    console.error(e);
    return res
      .status(500)
      .json({ error: "\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c \u043d\u0438\u043a\u043d\u0435\u0439\u043c" });
  }
});

// --- Group chat creation ---
app.post("/api/conversations/group", requireAuth, async (req, res) => {
  const name = normalize(req.body.name);
  const memberIds = Array.isArray(req.body.memberIds) ? [...new Set(req.body.memberIds.map((id) => normalize(id)).filter(Boolean))] : [];
  if (!name || name.length > 64) return res.status(400).json({ error: "Название группы: 1-64 символа" });
  if (memberIds.length === 0) return res.status(400).json({ error: "Добавьте хотя бы одного участника" });
  const allIds = [req.user.id, ...memberIds.filter((id) => id !== req.user.id)];
  try {
    const result = await store.withWriteLock((data) => {
      for (const mid of allIds) {
        if (mid !== req.user.id && !data.users.some((u) => u.id === mid)) {
          throw Object.assign(new Error("Пользователь не найден"), { code: "NOT_FOUND" });
        }
      }
      const now = new Date().toISOString();
      const conv = { id: crypto.randomUUID(), type: "group", name, participantIds: allIds, creatorId: req.user.id, avatarUrl: null, createdAt: now, updatedAt: now, lastMessageId: null };
      data.conversations.push(conv);
      return { conversationId: conv.id };
    });
    const state = await store.read();
    const conv = state.conversations.find((c) => c.id === result.conversationId);
    const usersById = new Map(state.users.map((u) => [u.id, u]));
    const messagesById = new Map(state.messages.map((m) => [m.id, m]));
    const payload = buildConversationPayload(conv, req.user.id, usersById, messagesById);
    for (const pid of allIds) {
      if (pid !== req.user.id) {
        const p = buildConversationPayload(conv, pid, usersById, messagesById);
        sendToUser(pid, { type: "conversation:update", conversation: p });
      }
    }
    return res.status(201).json({ conversation: payload });
  } catch (e) {
    if (e.code === "NOT_FOUND") return res.status(404).json({ error: e.message });
    console.error(e);
    return res.status(500).json({ error: "Не удалось создать группу" });
  }
});

// --- Group settings: rename ---
app.patch("/api/conversations/:id/group", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  const newName = normalize(req.body.name);
  let normalizedAvatarUrl;
  if (newName !== undefined && newName !== null && req.body.name !== undefined) {
    if (!newName || newName.length > 64) return res.status(400).json({ error: "Название группы: 1-64 символа" });
  }
  if (req.body.avatarUrl !== undefined) {
    const avatarResult = validateAndNormalizeAvatarDataUrl(req.body.avatarUrl, { allowEmpty: true });
    if (!avatarResult.ok) {
      return res.status(400).json({ error: avatarResult.error });
    }
    normalizedAvatarUrl = avatarResult.value;
  }
  try {
    await store.withWriteLock((data) => {
      const conv = data.conversations.find((c) => c.id === conversationId);
      if (!conv || conv.type !== "group") throw Object.assign(new Error("Группа не найдена"), { code: "NOT_FOUND" });
      if (!conv.participantIds.includes(req.user.id)) throw Object.assign(new Error("Вы не участник группы"), { code: "FORBIDDEN" });
      if (newName) conv.name = newName;
      if (req.body.avatarUrl !== undefined) {
        conv.avatarUrl = normalizedAvatarUrl;
      }
      conv.updatedAt = new Date().toISOString();
    });
    const state = await store.read();
    const conv = state.conversations.find((c) => c.id === conversationId);
    const usersById = new Map(state.users.map((u) => [u.id, u]));
    const messagesById = new Map(state.messages.map((m) => [m.id, m]));
    for (const pid of conv.participantIds) {
      const p = buildConversationPayload(conv, pid, usersById, messagesById);
      sendToUser(pid, { type: "conversation:update", conversation: p });
    }
    const payload = buildConversationPayload(conv, req.user.id, usersById, messagesById);
    return res.json({ conversation: payload });
  } catch (e) {
    if (e.code === "NOT_FOUND" || e.code === "FORBIDDEN") return res.status(e.code === "FORBIDDEN" ? 403 : 404).json({ error: e.message });
    console.error(e);
    return res.status(500).json({ error: "Не удалось обновить группу" });
  }
});

// --- Group: add member ---
app.post("/api/conversations/:id/members", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  const userId = normalize(req.body.userId);
  if (!userId) return res.status(400).json({ error: "Не указан userId" });
  try {
    await store.withWriteLock((data) => {
      const conv = data.conversations.find((c) => c.id === conversationId);
      if (!conv || conv.type !== "group") throw Object.assign(new Error("Группа не найдена"), { code: "NOT_FOUND" });
      if (!conv.participantIds.includes(req.user.id)) throw Object.assign(new Error("Вы не участник группы"), { code: "FORBIDDEN" });
      if (conv.participantIds.includes(userId)) throw Object.assign(new Error("Пользователь уже в группе"), { code: "ALREADY" });
      if (!data.users.some((u) => u.id === userId)) throw Object.assign(new Error("Пользователь не найден"), { code: "USER_NF" });
      conv.participantIds.push(userId);
      conv.updatedAt = new Date().toISOString();
    });
    const state = await store.read();
    const conv = state.conversations.find((c) => c.id === conversationId);
    const usersById = new Map(state.users.map((u) => [u.id, u]));
    const messagesById = new Map(state.messages.map((m) => [m.id, m]));
    for (const pid of conv.participantIds) {
      const p = buildConversationPayload(conv, pid, usersById, messagesById);
      sendToUser(pid, { type: "conversation:update", conversation: p });
    }
    const payload = buildConversationPayload(conv, req.user.id, usersById, messagesById);
    return res.json({ conversation: payload });
  } catch (e) {
    if (["NOT_FOUND", "FORBIDDEN", "ALREADY", "USER_NF"].includes(e.code)) {
      return res.status(e.code === "FORBIDDEN" ? 403 : e.code === "ALREADY" ? 409 : 404).json({ error: e.message });
    }
    console.error(e);
    return res.status(500).json({ error: "Не удалось добавить участника" });
  }
});

// --- Group: remove member (kick) ---
app.delete("/api/conversations/:id/members/:userId", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  const targetUserId = req.params.userId;
  try {
    const removedId = await store.withWriteLock((data) => {
      const conv = data.conversations.find((c) => c.id === conversationId);
      if (!conv || conv.type !== "group") throw Object.assign(new Error("Группа не найдена"), { code: "NOT_FOUND" });
      if (!conv.participantIds.includes(req.user.id)) throw Object.assign(new Error("Вы не участник группы"), { code: "FORBIDDEN" });
      const creatorId = conv.creatorId || conv.participantIds[0];
      if (req.user.id !== creatorId) throw Object.assign(new Error("Только создатель может удалять участников"), { code: "FORBIDDEN" });
      if (targetUserId === creatorId) throw Object.assign(new Error("Нельзя удалить создателя"), { code: "FORBIDDEN" });
      if (!conv.participantIds.includes(targetUserId)) throw Object.assign(new Error("Участник не найден"), { code: "USER_NF" });
      conv.participantIds = conv.participantIds.filter((id) => id !== targetUserId);
      conv.updatedAt = new Date().toISOString();
      return targetUserId;
    });
    const state = await store.read();
    const conv = state.conversations.find((c) => c.id === conversationId);
    const usersById = new Map(state.users.map((u) => [u.id, u]));
    const messagesById = new Map(state.messages.map((m) => [m.id, m]));
    // Notify remaining members
    for (const pid of conv.participantIds) {
      const p = buildConversationPayload(conv, pid, usersById, messagesById);
      sendToUser(pid, { type: "conversation:update", conversation: p });
    }
    // Notify removed member
    sendToUser(removedId, { type: "conversation:deleted", conversationId });
    const payload = buildConversationPayload(conv, req.user.id, usersById, messagesById);
    return res.json({ conversation: payload });
  } catch (e) {
    if (["NOT_FOUND", "FORBIDDEN", "USER_NF"].includes(e.code)) {
      return res.status(e.code === "FORBIDDEN" ? 403 : 404).json({ error: e.message });
    }
    console.error(e);
    return res.status(500).json({ error: "Не удалось удалить участника" });
  }
});

// --- Group: leave ---
app.post("/api/conversations/:id/leave", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  try {
    const remainingIds = await store.withWriteLock((data) => {
      const conv = data.conversations.find((c) => c.id === conversationId);
      if (!conv || conv.type !== "group") throw Object.assign(new Error("Группа не найдена"), { code: "NOT_FOUND" });
      if (!conv.participantIds.includes(req.user.id)) throw Object.assign(new Error("Вы не участник"), { code: "FORBIDDEN" });
      conv.participantIds = conv.participantIds.filter((id) => id !== req.user.id);
      conv.updatedAt = new Date().toISOString();
      if (conv.participantIds.length === 0) {
        data.conversations = data.conversations.filter((c) => c.id !== conversationId);
        data.messages = data.messages.filter((m) => m.conversationId !== conversationId);
        return [];
      }
      // If the leaver was creator, transfer to next
      if (conv.creatorId === req.user.id) {
        conv.creatorId = conv.participantIds[0];
      }
      return [...conv.participantIds];
    });
    const state = await store.read();
    const usersById = new Map(state.users.map((u) => [u.id, u]));
    const messagesById = new Map(state.messages.map((m) => [m.id, m]));
    // Notify remaining members
    if (remainingIds.length > 0) {
      const conv = state.conversations.find((c) => c.id === conversationId);
      if (conv) {
        for (const pid of remainingIds) {
          const p = buildConversationPayload(conv, pid, usersById, messagesById);
          sendToUser(pid, { type: "conversation:update", conversation: p });
        }
      }
    }
    return res.json({ success: true });
  } catch (e) {
    if (["NOT_FOUND", "FORBIDDEN"].includes(e.code)) {
      return res.status(e.code === "FORBIDDEN" ? 403 : 404).json({ error: e.message });
    }
    console.error(e);
    return res.status(500).json({ error: "Не удалось покинуть группу" });
  }
});

// --- Edit message ---
app.patch("/api/conversations/:id/messages/:messageId", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  const messageId = req.params.messageId;
  const newText = normalize(req.body.text);
  if (!newText) return res.status(400).json({ error: "Текст не может быть пустым" });
  if (newText.length > MAX_MESSAGE_LENGTH) return res.status(400).json({ error: `Максимум ${MAX_MESSAGE_LENGTH} символов` });
  try {
    const result = await store.withWriteLock((data) => {
      const conv = data.conversations.find((c) => c.id === conversationId);
      if (!conv || !conv.participantIds.includes(req.user.id)) throw Object.assign(new Error("Диалог не найден"), { code: "CONV_NF" });
      const msg = data.messages.find((m) => m.id === messageId && m.conversationId === conversationId);
      if (!msg) throw Object.assign(new Error("Сообщение не найдено"), { code: "MSG_NF" });
      if (msg.senderId !== req.user.id) throw Object.assign(new Error("Нельзя редактировать чужое сообщение"), { code: "FORBIDDEN" });
      if ((msg.messageType || "text") !== "text") throw Object.assign(new Error("Это сообщение нельзя редактировать"), { code: "FORBIDDEN" });
      msg.text = newText;
      msg.editedAt = new Date().toISOString();
      return { message: { ...msg }, participantIds: [...conv.participantIds] };
    });
    const state = await store.read();
    const sender = state.users.find((u) => u.id === req.user.id);
    const msgPayload = { ...result.message, sender: sender ? toPublicUser(sender) : null };
    for (const pid of result.participantIds) {
      sendToUser(pid, { type: "message:edited", message: msgPayload });
    }
    return res.json({ message: msgPayload });
  } catch (e) {
    if (["CONV_NF", "MSG_NF", "FORBIDDEN"].includes(e.code)) return res.status(e.code === "FORBIDDEN" ? 403 : 404).json({ error: e.message });
    console.error(e);
    return res.status(500).json({ error: "Не удалось отредактировать" });
  }
});

// --- Reactions ---
app.post("/api/conversations/:id/messages/:messageId/reactions", requireAuth, async (req, res) => {
  const conversationId = req.params.id;
  const messageId = req.params.messageId;
  const emoji = normalizeReactionEmoji(req.body.emoji);
  if (!emoji) return res.status(400).json({ error: "Некорректная реакция" });
  try {
    const result = await store.withWriteLock((data) => {
      const conv = data.conversations.find((c) => c.id === conversationId);
      if (!conv || !conv.participantIds.includes(req.user.id)) throw Object.assign(new Error("NF"), { code: "NF" });
      const msg = data.messages.find((m) => m.id === messageId && m.conversationId === conversationId);
      if (!msg) throw Object.assign(new Error("NF"), { code: "NF" });
      if (!Array.isArray(msg.reactions)) msg.reactions = [];
      const existing = msg.reactions.findIndex((r) => r.userId === req.user.id && r.emoji === emoji);
      if (existing >= 0) msg.reactions.splice(existing, 1);
      else msg.reactions.push({ userId: req.user.id, emoji, createdAt: new Date().toISOString() });
      return { reactions: [...msg.reactions], participantIds: [...conv.participantIds] };
    });
    for (const pid of result.participantIds) {
      sendToUser(pid, { type: "message:reactions", conversationId, messageId, reactions: result.reactions });
    }
    return res.json({ reactions: result.reactions });
  } catch (e) {
    if (e.code === "NF") return res.status(404).json({ error: "Не найдено" });
    console.error(e);
    return res.status(500).json({ error: "Ошибка" });
  }
});

// --- Push subscription management ---
app.get("/api/push/vapid-key", (req, res) => {
  return res.json({ publicKey: VAPID_PUBLIC_KEY });
});

app.post("/api/push/subscribe", requireAuth, async (req, res) => {
  const subscription = req.body.subscription;
  if (!subscription || !subscription.endpoint) {
    return res.status(400).json({ error: "Некорректная подписка" });
  }

  try {
    await store.withWriteLock((data) => {
      if (!Array.isArray(data.pushSubscriptions)) {
        data.pushSubscriptions = [];
      }

      data.pushSubscriptions = data.pushSubscriptions.filter(
        (sub) => sub.subscription.endpoint !== subscription.endpoint
      );

      data.pushSubscriptions.push({
        userId: req.user.id,
        subscription,
        createdAt: new Date().toISOString(),
      });
    });

    if (!pushSubscriptionsByUser.has(req.user.id)) {
      pushSubscriptionsByUser.set(req.user.id, []);
    }
    const subs = pushSubscriptionsByUser.get(req.user.id);
    const existingIdx = subs.findIndex((s) => s.endpoint === subscription.endpoint);
    if (existingIdx >= 0) {
      subs[existingIdx] = subscription;
    } else {
      subs.push(subscription);
    }

    return res.json({ success: true });
  } catch (error) {
    console.error("Failed to save push subscription", error);
    return res.status(500).json({ error: "Не удалось сохранить подписку" });
  }
});

app.post("/api/push/unsubscribe", requireAuth, async (req, res) => {
  const endpoint = String(req.body.endpoint || "");
  if (!endpoint) {
    return res.status(400).json({ error: "Не указан endpoint" });
  }

  try {
    await store.withWriteLock((data) => {
      if (!Array.isArray(data.pushSubscriptions)) return;
      data.pushSubscriptions = data.pushSubscriptions.filter(
        (sub) => !(sub.userId === req.user.id && sub.subscription.endpoint === endpoint)
      );
    });

    const subs = pushSubscriptionsByUser.get(req.user.id);
    if (subs) {
      const idx = subs.findIndex((s) => s.endpoint === endpoint);
      if (idx >= 0) subs.splice(idx, 1);
      if (subs.length === 0) pushSubscriptionsByUser.delete(req.user.id);
    }

    return res.json({ success: true });
  } catch (error) {
    console.error("Failed to remove push subscription", error);
    return res.status(500).json({ error: "Не удалось удалить подписку" });
  }
});

async function sendPushNotificationToUser(userId, payload) {
  const subs = pushSubscriptionsByUser.get(userId) || [];
  if (subs.length === 0) {
    try {
      const state = await store.read();
      if (Array.isArray(state.pushSubscriptions)) {
        const dbSubs = state.pushSubscriptions.filter((s) => s.userId === userId);
        for (const entry of dbSubs) {
          subs.push(entry.subscription);
        }
        if (subs.length > 0) {
          pushSubscriptionsByUser.set(userId, subs);
        }
      }
    } catch { }
  }

  if (subs.length === 0) return;

  const jsonPayload = JSON.stringify(payload);
  const expiredEndpoints = [];

  for (const sub of subs) {
    try {
      await webPush.sendNotification(sub, jsonPayload);
    } catch (error) {
      if (error.statusCode === 404 || error.statusCode === 410) {
        expiredEndpoints.push(sub.endpoint);
      }
    }
  }

  if (expiredEndpoints.length > 0) {
    const remaining = subs.filter((s) => !expiredEndpoints.includes(s.endpoint));
    if (remaining.length > 0) {
      pushSubscriptionsByUser.set(userId, remaining);
    } else {
      pushSubscriptionsByUser.delete(userId);
    }

    try {
      await store.withWriteLock((data) => {
        if (!Array.isArray(data.pushSubscriptions)) return;
        data.pushSubscriptions = data.pushSubscriptions.filter(
          (entry) => !expiredEndpoints.includes(entry.subscription.endpoint)
        );
      });
    } catch { }
  }
}

app.use(express.static(path.join(__dirname, "public"), {
  // 1 hour for versioned assets; sw.js and index.html must always revalidate
  setHeaders(res, filePath) {
    const name = path.basename(filePath);
    if (name === "sw.js" || name === "index.html") {
      res.setHeader("Cache-Control", "no-cache");
    } else {
      res.setHeader("Cache-Control", "public, max-age=3600");
    }
  },
}));

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

  socket.isAlive = true;
  socket.on("pong", () => { socket.isAlive = true; });

  const cameOnline = addSocket(user.id, socket);
  if (cameOnline) {
    broadcastPresenceChange(user.id, true);
  }
  console.log(`[WS] connected: ${user.username} (${user.id})`);
  socket.send(
    JSON.stringify({
      type: "ready",
      user: toPublicUser(user),
    })
  );
  flushQueuedMessages(user.id, socket);

  socket.on("message", async (raw) => {
    let payload;
    try {
      payload = JSON.parse(raw.toString());
    } catch {
      return;
    }

    if (payload.type === "ping") {
      socket.send(JSON.stringify({ type: "pong" }));
      return;
    }

    if (payload.type === "typing") {
      const convId = normalize(payload.conversationId);
      if (!convId) return;
      try {
        const s = await store.read();
        const conv = s.conversations.find((c) => c.id === convId);
        if (!conv || !conv.participantIds.includes(user.id)) return;
        const currentUser = s.users.find((item) => item.id === user.id) || user;
        for (const pid of conv.participantIds) {
          if (pid !== user.id) {
            sendToUser(pid, {
              type: "typing",
              conversationId: convId,
              userId: user.id,
              username: currentUser.username,
              displayName: getPublicName(currentUser),
            });
          }
        }
      } catch { }
      return;
    }

    if (payload.type === "call:signal") {
      const targetUserId = normalize(payload.targetUserId);
      const signalType = normalizeLower(payload.signalType);
      const allowedSignalTypes = new Set([
        "offer",
        "answer",
        "ice",
        "reject",
        "busy",
        "end",
      ]);
      if (!targetUserId || !allowedSignalTypes.has(signalType)) {
        return;
      }

      try {
        const state = await store.read();
        const caller = state.users.find((item) => item.id === user.id);
        const targetUser = state.users.find((item) => item.id === targetUserId);
        const conversation = findDirectConversation(state, user.id, targetUserId);
        if (!caller || !targetUser || !conversation) {
          return;
        }
        if (isUserBlockedBy(caller, targetUserId)) {
          return;
        }
        if (isUserBlockedBy(targetUser, user.id)) {
          return;
        }

        sendToUser(targetUserId, {
          type: "call:signal",
          fromUserId: user.id,
          signalType,
          conversationId: conversation.id,
          data: payload.data || {},
        });
      } catch (error) {
        console.error("Failed to relay call signal", error);
      }
    }
  });

  socket.on("close", () => {
    const wentOffline = removeSocket(user.id, socket);
    if (wentOffline) {
      console.log(`[WS] disconnected: ${user.username} (${user.id})`);
      broadcastPresenceChange(user.id, false);
    }
  });

  socket.on("error", (err) => {
    console.error(`[WS] socket error for ${user.username} (${user.id}):`, err.message);
    const wentOffline = removeSocket(user.id, socket);
    if (wentOffline) {
      broadcastPresenceChange(user.id, false);
    }
  });
});

const heartbeatTimer = setInterval(() => {
  for (const client of wss.clients) {
    if (!client.isAlive) {
      client.terminate();
      continue;
    }
    client.isAlive = false;
    client.ping();
  }
}, HEARTBEAT_INTERVAL_MS);
wss.on("close", () => clearInterval(heartbeatTimer));

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

