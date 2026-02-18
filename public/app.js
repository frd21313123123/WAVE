const authView = document.getElementById("authView");
const chatView = document.getElementById("chatView");
const authStatus = document.getElementById("authStatus");
const tabLogin = document.getElementById("tabLogin");
const tabRegister = document.getElementById("tabRegister");
const loginForm = document.getElementById("loginForm");
const registerForm = document.getElementById("registerForm");
const logoutBtn = document.getElementById("logoutBtn");
const meName = document.getElementById("meName");
const userSearch = document.getElementById("userSearch");
const searchResults = document.getElementById("searchResults");
const conversationList = document.getElementById("conversationList");
const chatTitle = document.getElementById("chatTitle");
const messagesEl = document.getElementById("messages");
const messageForm = document.getElementById("messageForm");
const messageInput = document.getElementById("messageInput");
const mobileBack = document.getElementById("mobileBack");

const state = {
  me: null,
  conversations: [],
  activeConversationId: null,
  messagesByConversation: new Map(),
  socket: null,
  searchDebounce: null,
};

function setAuthTab(tab) {
  const isLogin = tab === "login";
  tabLogin.classList.toggle("active", isLogin);
  tabRegister.classList.toggle("active", !isLogin);
  loginForm.classList.toggle("hidden", !isLogin);
  registerForm.classList.toggle("hidden", isLogin);
  authStatus.textContent = "";
}

async function api(path, options = {}) {
  const response = await fetch(path, {
    method: options.method || "GET",
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  let payload = {};
  try {
    payload = await response.json();
  } catch {
    payload = {};
  }

  if (!response.ok) {
    throw new Error(payload.error || "Ошибка запроса");
  }
  return payload;
}

function showAuth() {
  chatView.classList.add("hidden");
  authView.classList.remove("hidden");
  closeSocket();
  state.me = null;
  state.conversations = [];
  state.activeConversationId = null;
  state.messagesByConversation = new Map();
}

function showChat() {
  authView.classList.add("hidden");
  chatView.classList.remove("hidden");
}

function resetMobileChatState() {
  chatView.classList.remove("chat-open");
}

function openMobileChatState() {
  chatView.classList.add("chat-open");
}

function formatTime(dateString) {
  if (!dateString) {
    return "";
  }

  const date = new Date(dateString);
  return date.toLocaleTimeString("ru-RU", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatDateTime(dateString) {
  if (!dateString) {
    return "";
  }

  const date = new Date(dateString);
  return date.toLocaleString("ru-RU", {
    day: "2-digit",
    month: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function createEmptyListNote(text) {
  const item = document.createElement("li");
  item.className = "empty-note";
  item.textContent = text;
  return item;
}

function upsertConversation(conversation) {
  const index = state.conversations.findIndex((item) => item.id === conversation.id);
  if (index >= 0) {
    state.conversations[index] = conversation;
  } else {
    state.conversations.push(conversation);
  }

  state.conversations.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
}

function getConversationById(conversationId) {
  return state.conversations.find((conversation) => conversation.id === conversationId);
}

function renderConversationList() {
  conversationList.innerHTML = "";

  if (state.conversations.length === 0) {
    conversationList.appendChild(
      createEmptyListNote("Пока нет чатов. Найдите пользователя выше.")
    );
    return;
  }

  for (const conversation of state.conversations) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "list-item";
    if (state.activeConversationId === conversation.id) {
      button.classList.add("active");
    }

    const title = conversation.participant
      ? conversation.participant.username
      : "Диалог";
    const preview = conversation.lastMessage
      ? conversation.lastMessage.text
      : "Сообщений еще нет";

    const row = document.createElement("div");
    row.className = "item-row";

    const titleEl = document.createElement("p");
    titleEl.className = "item-title";
    titleEl.textContent = title;

    const timeEl = document.createElement("p");
    timeEl.className = "item-time";
    timeEl.textContent = formatTime(conversation.updatedAt);

    row.appendChild(titleEl);
    row.appendChild(timeEl);

    const previewEl = document.createElement("p");
    previewEl.className = "item-sub";
    previewEl.textContent = preview;

    button.appendChild(row);
    button.appendChild(previewEl);

    button.addEventListener("click", () => {
      selectConversation(conversation.id);
    });

    const wrapper = document.createElement("li");
    wrapper.appendChild(button);
    conversationList.appendChild(wrapper);
  }
}

function addMessage(message) {
  const existing = state.messagesByConversation.get(message.conversationId) || [];
  if (!existing.some((item) => item.id === message.id)) {
    existing.push(message);
    existing.sort((a, b) => a.createdAt.localeCompare(b.createdAt));
    state.messagesByConversation.set(message.conversationId, existing);
  }
}

function renderMessages() {
  messagesEl.innerHTML = "";

  if (!state.activeConversationId) {
    messagesEl.appendChild(createEmptyListNote("Выберите чат, чтобы начать переписку."));
    return;
  }

  const messages = state.messagesByConversation.get(state.activeConversationId) || [];
  if (messages.length === 0) {
    messagesEl.appendChild(createEmptyListNote("Напишите первое сообщение в этом диалоге."));
    return;
  }

  for (const message of messages) {
    const row = document.createElement("article");
    const mine = message.senderId === state.me.id;
    row.className = `message-row ${mine ? "mine" : "their"}`;

    const bubble = document.createElement("div");
    bubble.className = "bubble";

    const text = document.createElement("p");
    text.textContent = message.text;
    bubble.appendChild(text);

    const meta = document.createElement("div");
    meta.className = "bubble-meta";
    meta.textContent = mine
      ? `Вы, ${formatDateTime(message.createdAt)}`
      : `${message.sender?.username || "Пользователь"}, ${formatDateTime(
          message.createdAt
        )}`;
    bubble.appendChild(meta);

    row.appendChild(bubble);
    messagesEl.appendChild(row);
  }

  messagesEl.scrollTop = messagesEl.scrollHeight;
}

function renderSearchResults(users) {
  searchResults.innerHTML = "";
  if (users.length === 0) {
    searchResults.appendChild(
      createEmptyListNote("Введите минимум 2 символа для поиска пользователей.")
    );
    return;
  }

  for (const user of users) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "list-item";

    const row = document.createElement("div");
    row.className = "item-row";

    const titleEl = document.createElement("p");
    titleEl.className = "item-title";
    titleEl.textContent = user.username;
    row.appendChild(titleEl);

    const emailEl = document.createElement("p");
    emailEl.className = "item-sub";
    emailEl.textContent = user.email;

    button.appendChild(row);
    button.appendChild(emailEl);
    button.addEventListener("click", async () => {
      try {
        const payload = await api("/api/conversations/direct", {
          method: "POST",
          body: { userId: user.id },
        });
        upsertConversation(payload.conversation);
        renderConversationList();
        await selectConversation(payload.conversation.id);
        userSearch.value = "";
        renderSearchResults([]);
      } catch (error) {
        authStatus.textContent = error.message;
      }
    });

    const wrapper = document.createElement("li");
    wrapper.appendChild(button);
    searchResults.appendChild(wrapper);
  }
}

async function loadMessages(conversationId) {
  if (state.messagesByConversation.has(conversationId)) {
    return;
  }

  const payload = await api(`/api/conversations/${conversationId}/messages?limit=200`);
  state.messagesByConversation.set(conversationId, payload.messages || []);
}

async function selectConversation(conversationId) {
  state.activeConversationId = conversationId;
  renderConversationList();

  const conversation = getConversationById(conversationId);
  chatTitle.textContent = conversation?.participant?.username || "Диалог";

  await loadMessages(conversationId);
  renderMessages();

  if (window.matchMedia("(max-width: 950px)").matches) {
    openMobileChatState();
  }
}

async function loadConversations() {
  const payload = await api("/api/conversations");
  state.conversations = payload.conversations || [];
  state.conversations.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));

  renderConversationList();
  if (state.conversations.length > 0) {
    await selectConversation(state.conversations[0].id);
  } else {
    state.activeConversationId = null;
    chatTitle.textContent = "Выберите диалог слева";
    renderMessages();
    resetMobileChatState();
  }
}

function closeSocket() {
  if (state.socket) {
    state.socket.close();
    state.socket = null;
  }
}

function connectSocket() {
  closeSocket();
  const protocol = window.location.protocol === "https:" ? "wss" : "ws";
  const socket = new WebSocket(`${protocol}://${window.location.host}/ws`);
  state.socket = socket;

  socket.addEventListener("message", async (event) => {
    let payload;
    try {
      payload = JSON.parse(event.data);
    } catch {
      return;
    }

    if (payload.type === "message:new" && payload.message) {
      addMessage(payload.message);
      if (payload.message.conversationId === state.activeConversationId) {
        renderMessages();
      }
    }

    if (payload.type === "conversation:update" && payload.conversation) {
      upsertConversation(payload.conversation);
      renderConversationList();
      if (payload.conversation.id === state.activeConversationId) {
        chatTitle.textContent =
          payload.conversation.participant?.username || "Диалог";
      }
    }
  });

  socket.addEventListener("close", () => {
    state.socket = null;
    if (state.me) {
      setTimeout(() => {
        if (!state.socket && state.me) {
          connectSocket();
        }
      }, 1500);
    }
  });
}

async function bootstrapSession(user) {
  state.me = user;
  meName.textContent = `${user.username} (${user.email})`;
  showChat();
  authStatus.textContent = "";
  renderSearchResults([]);
  await loadConversations();
  connectSocket();
}

tabLogin.addEventListener("click", () => setAuthTab("login"));
tabRegister.addEventListener("click", () => setAuthTab("register"));

loginForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  authStatus.textContent = "";

  const formData = new FormData(loginForm);
  const login = String(formData.get("login") || "");
  const password = String(formData.get("password") || "");

  try {
    const payload = await api("/api/auth/login", {
      method: "POST",
      body: { login, password },
    });
    loginForm.reset();
    await bootstrapSession(payload.user);
  } catch (error) {
    authStatus.textContent = error.message;
  }
});

registerForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  authStatus.textContent = "";

  const formData = new FormData(registerForm);
  const username = String(formData.get("username") || "");
  const email = String(formData.get("email") || "");
  const password = String(formData.get("password") || "");

  try {
    const payload = await api("/api/auth/register", {
      method: "POST",
      body: { username, email, password },
    });
    registerForm.reset();
    await bootstrapSession(payload.user);
  } catch (error) {
    authStatus.textContent = error.message;
  }
});

logoutBtn.addEventListener("click", async () => {
  try {
    await api("/api/auth/logout", { method: "POST" });
  } catch {
  } finally {
    showAuth();
    setAuthTab("login");
  }
});

userSearch.addEventListener("input", () => {
  const query = userSearch.value.trim();
  clearTimeout(state.searchDebounce);

  if (query.length < 2) {
    renderSearchResults([]);
    return;
  }

  state.searchDebounce = setTimeout(async () => {
    try {
      const payload = await api(`/api/users?search=${encodeURIComponent(query)}`);
      renderSearchResults(payload.users || []);
    } catch {
      renderSearchResults([]);
    }
  }, 250);
});

messageInput.addEventListener("input", () => {
  messageInput.style.height = "auto";
  messageInput.style.height = `${Math.min(messageInput.scrollHeight, 130)}px`;
});

messageForm.addEventListener("submit", async (event) => {
  event.preventDefault();

  if (!state.activeConversationId) {
    return;
  }

  const text = messageInput.value.trim();
  if (!text) {
    return;
  }

  try {
    const payload = await api(
      `/api/conversations/${state.activeConversationId}/messages`,
      {
        method: "POST",
        body: { text },
      }
    );

    upsertConversation(payload.conversation);
    addMessage(payload.message);
    renderConversationList();
    renderMessages();
    messageInput.value = "";
    messageInput.style.height = "auto";
  } catch (error) {
    authStatus.textContent = error.message;
  }
});

mobileBack.addEventListener("click", () => {
  resetMobileChatState();
});

window.addEventListener("resize", () => {
  if (!window.matchMedia("(max-width: 950px)").matches) {
    chatView.classList.remove("chat-open");
  }
});

async function init() {
  setAuthTab("login");
  renderSearchResults([]);

  try {
    const payload = await api("/api/auth/me");
    await bootstrapSession(payload.user);
  } catch {
    showAuth();
  }
}

init();
