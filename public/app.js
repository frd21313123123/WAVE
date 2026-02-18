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
const chatPresence = document.getElementById("chatPresence");
const callStatus = document.getElementById("callStatus");
const incomingCallPanel = document.getElementById("incomingCallPanel");
const incomingCallText = document.getElementById("incomingCallText");
const acceptCallBtn = document.getElementById("acceptCallBtn");
const rejectCallBtn = document.getElementById("rejectCallBtn");
const messagesEl = document.getElementById("messages");
const messageForm = document.getElementById("messageForm");
const messageInput = document.getElementById("messageInput");
const mobileBack = document.getElementById("mobileBack");
const settingsBtn = document.getElementById("settingsBtn");
const settingsPanel = document.getElementById("settingsPanel");
const closeSettingsBtn = document.getElementById("closeSettingsBtn");
const translationLanguage = document.getElementById("translationLanguage");
const themeSelect = document.getElementById("themeSelect");
const vigenereKeyInput = document.getElementById("vigenereKeyInput");
const vigenereToggle = document.getElementById("vigenereToggle");
const loginOtpLabel = document.getElementById("loginOtpLabel");
const loginOtpInput = document.getElementById("loginOtpInput");
const loginOtpCancelBtn = document.getElementById("loginOtpCancelBtn");
const loginSubmitBtn = document.getElementById("loginSubmitBtn");
const twoFaStatus = document.getElementById("twoFaStatus");
const twoFaSetupBtn = document.getElementById("twoFaSetupBtn");
const twoFaSetupPanel = document.getElementById("twoFaSetupPanel");
const twoFaQr = document.getElementById("twoFaQr");
const twoFaSecret = document.getElementById("twoFaSecret");
const twoFaEnableCodeInput = document.getElementById("twoFaEnableCodeInput");
const twoFaEnableBtn = document.getElementById("twoFaEnableBtn");
const twoFaDisablePanel = document.getElementById("twoFaDisablePanel");
const twoFaDisableCodeInput = document.getElementById("twoFaDisableCodeInput");
const twoFaDisableBtn = document.getElementById("twoFaDisableBtn");
const deleteModeBtn = document.getElementById("deleteModeBtn");
const deleteToolbar = document.getElementById("deleteToolbar");
const deleteSelectionInfo = document.getElementById("deleteSelectionInfo");
const deleteSelectedBtn = document.getElementById("deleteSelectedBtn");
const deleteConversationBtn = document.getElementById("deleteConversationBtn");
const deleteCancelBtn = document.getElementById("deleteCancelBtn");
const chatLockBtn = document.getElementById("chatLockBtn");
const blockUserBtn = document.getElementById("blockUserBtn");
const callBtn = document.getElementById("callBtn");
const chatLockOverlay = document.getElementById("chatLockOverlay");
const chatLockCodeInput = document.getElementById("chatLockCodeInput");
const chatUnlockBtn = document.getElementById("chatUnlockBtn");
const chatLockStatus = document.getElementById("chatLockStatus");
const deleteAccountBtn = document.getElementById("deleteAccountBtn");
const microphoneSelect = document.getElementById("microphoneSelect");
const remoteAudio = document.getElementById("remoteAudio");
const chatMain = document.querySelector(".chat-main");
const sidebarResizeHandle = document.getElementById("sidebarResizeHandle");
const sendMessageBtn = messageForm.querySelector('button[type="submit"]');
const typingIndicator = document.getElementById("typingIndicator");
const replyBar = document.getElementById("replyBar");
const replyBarText = document.getElementById("replyBarText");
const replyBarCancel = document.getElementById("replyBarCancel");
const voiceRecordBtn = document.getElementById("voiceRecordBtn");
const messageContextMenu = document.getElementById("messageContextMenu");
const ctxReply = document.getElementById("ctxReply");
const ctxEdit = document.getElementById("ctxEdit");
const ctxForward = document.getElementById("ctxForward");
const ctxReact = document.getElementById("ctxReact");
const reactionPicker = document.getElementById("reactionPicker");
const createGroupBtn = document.getElementById("createGroupBtn");
const createGroupModal = document.getElementById("createGroupModal");
const closeGroupModalBtn = document.getElementById("closeGroupModalBtn");
const groupNameInput = document.getElementById("groupNameInput");
const groupMemberSearch = document.getElementById("groupMemberSearch");
const groupMemberResults = document.getElementById("groupMemberResults");
const groupSelectedMembers = document.getElementById("groupSelectedMembers");
const groupCreateBtn = document.getElementById("groupCreateBtn");
const groupCreateStatus = document.getElementById("groupCreateStatus");
const avatarPreview = document.getElementById("avatarPreview");
const avatarFileInput = document.getElementById("avatarFileInput");
const avatarUploadBtn = document.getElementById("avatarUploadBtn");
const notifToggleBtn = document.getElementById("notifToggleBtn");

const UI_SETTINGS_KEY = "messenger_ui_settings_v1";
const DEFAULT_VIGENERE_KEY = "WAVE";
const DEFAULT_MESSAGE_PLACEHOLDER = "Напишите сообщение...";
const MESSAGE_DELETE_ANIMATION_MS = 240;
const SIDEBAR_DEFAULT_WIDTH = 336;
const SIDEBAR_MIN_WIDTH = 260;
const SIDEBAR_MAIN_MIN_WIDTH = 420;
const SIDEBAR_HANDLE_WIDTH = 10;
const SIDEBAR_MAX_WIDTH = 560;
const CALL_RINGTONE_SRC = "/sound-call.mp3";
const MESSAGE_SOUND_SRC = "/sound-message.mp3";
const ALLOWED_TRANSLATION_LANGS = new Set([
  "off",
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
const ALLOWED_THEMES = new Set(["light", "dark"]);

const state = {
  me: null,
  conversations: [],
  activeConversationId: null,
  messagesByConversation: new Map(),
  socket: null,
  searchDebounce: null,
  translationCache: new Map(),
  translationRequests: new Map(),
  loginChallengeToken: null,
  twoFa: {
    enabled: false,
    setupSecret: "",
    setupOtpAuthUrl: "",
  },
  deletingMessageIdsByConversation: new Map(),
  readRequestsInFlight: new Set(),
  incomingSoundContext: null,
  chatLocked: false,
  blockActionInFlight: false,
  call: {
    active: false,
    targetUserId: "",
    conversationId: "",
    peer: null,
    localStream: null,
    pendingIncoming: null,
    ringtoneFrame: null,
    incomingActionInFlight: false,
  },
  deleteMode: false,
  selectedMessageIds: new Set(),
  replyToMessage: null,
  contextMenuMessageId: null,
  typingTimers: new Map(),
  typingDebounce: null,
  voiceRecorder: null,
  voiceRecording: false,
  groupSelectedMembers: [],
  ui: {
    theme: "light",
    targetLanguage: "off",
    vigenereEnabled: false,
    vigenereKey: DEFAULT_VIGENERE_KEY,
    sidebarWidth: SIDEBAR_DEFAULT_WIDTH,
    microphoneId: "",
  },
};

function normalizeOtpToken(value) {
  return String(value || "")
    .replace(/\D+/g, "")
    .slice(0, 6);
}

function resetLoginTwoFactorStep() {
  state.loginChallengeToken = null;
  loginOtpLabel.classList.add("hidden");
  loginOtpCancelBtn.classList.add("hidden");
  loginOtpInput.value = "";
  loginForm.elements.login.disabled = false;
  loginForm.elements.password.disabled = false;
  loginSubmitBtn.textContent = "\u0412\u043e\u0439\u0442\u0438";
}

function startLoginTwoFactorStep(challengeToken) {
  state.loginChallengeToken = String(challengeToken || "");
  loginOtpLabel.classList.remove("hidden");
  loginOtpCancelBtn.classList.remove("hidden");
  loginForm.elements.login.disabled = true;
  loginForm.elements.password.disabled = true;
  loginSubmitBtn.textContent = "\u041f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u044c \u043a\u043e\u0434";
  loginOtpInput.focus();
}

function clearTwoFaSetup() {
  state.twoFa.setupSecret = "";
  state.twoFa.setupOtpAuthUrl = "";
  twoFaSetupPanel.classList.add("hidden");
  twoFaSecret.textContent = "";
  twoFaEnableCodeInput.value = "";
  twoFaQr.removeAttribute("src");
}

function setTwoFaStatusText(text, isError = false) {
  twoFaStatus.textContent = String(text || "");
  twoFaStatus.style.color = isError ? "var(--danger)" : "var(--text-subtle)";
}

function renderTwoFaState() {
  if (state.twoFa.enabled) {
    setTwoFaStatusText("2FA is enabled for this account.");
    twoFaSetupBtn.textContent = "Rotate 2FA secret";
    twoFaDisablePanel.classList.remove("hidden");
  } else {
    setTwoFaStatusText("2FA is disabled.");
    twoFaSetupBtn.textContent = "Enable 2FA";
    twoFaDisablePanel.classList.add("hidden");
    twoFaDisableCodeInput.value = "";
  }

  if (state.twoFa.setupSecret && state.twoFa.setupOtpAuthUrl) {
    twoFaSetupPanel.classList.remove("hidden");
    twoFaSecret.textContent = `Secret: ${state.twoFa.setupSecret}`;
    twoFaQr.src = `https://api.qrserver.com/v1/create-qr-code/?size=156x156&data=${encodeURIComponent(
      state.twoFa.setupOtpAuthUrl
    )}`;
  } else {
    twoFaSetupPanel.classList.add("hidden");
    twoFaSecret.textContent = "";
    twoFaQr.removeAttribute("src");
  }

  updateChatLockUi();
}

async function refreshTwoFaStatus() {
  try {
    const payload = await api("/api/auth/2fa/status");
    state.twoFa.enabled = Boolean(payload.enabled);
    if (!state.twoFa.enabled) {
      clearTwoFaSetup();
      for (const conversation of state.conversations) {
        conversation.chatProtected = false;
      }
      setChatLocked(false);
    }
    renderTwoFaState();
  } catch {
    setTwoFaStatusText("Failed to load 2FA status.", true);
  }
}

function setChatLockStatus(text, isError = false) {
  chatLockStatus.textContent = String(text || "");
  chatLockStatus.style.color = isError ? "var(--danger)" : "var(--text-subtle)";
}

function getActiveConversation() {
  return getConversationById(state.activeConversationId);
}

function getConversationByParticipantId(userId) {
  return state.conversations.find((conversation) => conversation.participant?.id === userId);
}

function sendSocketPayload(payload) {
  if (!state.socket || state.socket.readyState !== WebSocket.OPEN) {
    return false;
  }

  state.socket.send(JSON.stringify(payload));
  return true;
}

function setCallStatus(text, isError = false) {
  callStatus.textContent = String(text || "");
  callStatus.style.color = isError ? "var(--danger)" : "var(--text-subtle)";
}

function setIncomingCallActionInFlight(inFlight) {
  state.call.incomingActionInFlight = Boolean(inFlight);
  acceptCallBtn.disabled = state.call.incomingActionInFlight;
  rejectCallBtn.disabled = state.call.incomingActionInFlight;
}

function clearIncomingCallUi() {
  incomingCallPanel.classList.add("hidden");
  incomingCallText.textContent = "";
  setIncomingCallActionInFlight(false);
}

function clearPendingIncomingCall() {
  state.call.pendingIncoming = null;
  clearIncomingCallUi();
  updateCallUi();
}

function showIncomingCallUi(callerName) {
  incomingCallText.textContent = callerName;
  incomingCallPanel.classList.remove("hidden");
  setIncomingCallActionInFlight(false);
}

function startCallRingtone() {
  if (state.call.ringtoneFrame) {
    return;
  }

  const audio = new Audio(CALL_RINGTONE_SRC);
  audio.loop = true;
  audio.play().catch(() => { });
  state.call.ringtoneFrame = audio;
}

function stopCallRingtone() {
  if (!state.call.ringtoneFrame) {
    return;
  }
  state.call.ringtoneFrame.pause();
  state.call.ringtoneFrame = null;
}

function getPeerConnectionConstructor() {
  return window.RTCPeerConnection || window.webkitRTCPeerConnection || null;
}

function canUseAudioCalls() {
  return Boolean(
    getPeerConnectionConstructor() &&
    navigator.mediaDevices &&
    typeof navigator.mediaDevices.getUserMedia === "function"
  );
}

function updateCallUi() {
  const conversation = getActiveConversation();
  const callActive = Boolean(state.call.active);
  const callsSupported = canUseAudioCalls();
  const hasPendingIncoming = Boolean(state.call.pendingIncoming);
  const disabledByContext =
    !conversation || state.chatLocked || Boolean(conversation?.blockedMe) || !callsSupported;

  callBtn.disabled = (disabledByContext || hasPendingIncoming) && !callActive;
  callBtn.classList.toggle("active", callActive);
  callBtn.textContent = callActive ? "Завершить" : "Позвонить";
  callBtn.title = callsSupported
    ? ""
    : "Звонки недоступны: браузер не поддерживает доступ к микрофону.";
}

function cleanupCallState() {
  stopCallRingtone();
  clearPendingIncomingCall();

  if (state.call.peer) {
    try {
      state.call.peer.close();
    } catch {
    }
  }

  if (state.call.localStream) {
    for (const track of state.call.localStream.getTracks()) {
      track.stop();
    }
  }

  state.call.active = false;
  state.call.targetUserId = "";
  state.call.conversationId = "";
  state.call.peer = null;
  state.call.localStream = null;

  remoteAudio.srcObject = null;
  updateCallUi();
}

function endCall(notifyPeer = true, statusText = "Звонок завершен.") {
  const targetUserId = state.call.targetUserId;
  if (notifyPeer && targetUserId) {
    sendSocketPayload({
      type: "call:signal",
      targetUserId,
      signalType: "end",
      conversationId: state.call.conversationId || state.activeConversationId,
    });
  }

  cleanupCallState();
  setCallStatus(statusText);
}

function rejectPendingIncomingCall(statusText = "Входящий звонок отклонен.") {
  const pendingCall = state.call.pendingIncoming;
  if (!pendingCall) {
    return;
  }

  sendSocketPayload({
    type: "call:signal",
    targetUserId: pendingCall.fromUserId,
    signalType: "reject",
    conversationId: pendingCall.conversationId,
  });

  stopCallRingtone();
  clearPendingIncomingCall();
  setCallStatus(statusText);
}

async function acceptPendingIncomingCall() {
  const pendingCall = state.call.pendingIncoming;
  if (!pendingCall || state.call.active || state.call.incomingActionInFlight) {
    return;
  }

  if (!canUseAudioCalls()) {
    rejectPendingIncomingCall("Входящий звонок отклонен: звонки недоступны в этом браузере.");
    return;
  }

  setIncomingCallActionInFlight(true);
  stopCallRingtone();

  try {
    const callerConversation =
      getConversationById(pendingCall.conversationId) ||
      getConversationByParticipantId(pendingCall.fromUserId);

    if (callerConversation && callerConversation.id !== state.activeConversationId) {
      await selectConversation(callerConversation.id);
    }

    const localStream = await navigator.mediaDevices.getUserMedia(getAudioConstraints());
    const peer = await createCallPeer(
      pendingCall.fromUserId,
      callerConversation?.id || pendingCall.conversationId,
      localStream
    );

    await peer.setRemoteDescription(new RTCSessionDescription(pendingCall.offerSdp));
    const answer = await peer.createAnswer();
    await peer.setLocalDescription(answer);

    sendSocketPayload({
      type: "call:signal",
      targetUserId: pendingCall.fromUserId,
      signalType: "answer",
      conversationId: callerConversation?.id || pendingCall.conversationId,
      data: { sdp: peer.localDescription },
    });

    clearPendingIncomingCall();
    setCallStatus("В звонке.");
  } catch (error) {
    sendSocketPayload({
      type: "call:signal",
      targetUserId: pendingCall.fromUserId,
      signalType: "reject",
      conversationId: pendingCall.conversationId,
    });
    cleanupCallState();
    setCallStatus(error?.message || "Не удалось принять звонок.", true);
  }
}

async function createCallPeer(targetUserId, conversationId, localStream) {
  const PeerConnection = getPeerConnectionConstructor();
  if (!PeerConnection) {
    throw new Error("Звонки недоступны в этом браузере.");
  }

  const peer = new PeerConnection({
    iceServers: [{ urls: "stun:stun.l.google.com:19302" }],
  });

  for (const track of localStream.getTracks()) {
    peer.addTrack(track, localStream);
  }

  peer.onicecandidate = (event) => {
    if (!event.candidate || !state.call.targetUserId) {
      return;
    }
    sendSocketPayload({
      type: "call:signal",
      targetUserId: state.call.targetUserId,
      signalType: "ice",
      conversationId,
      data: { candidate: event.candidate },
    });
  };

  peer.ontrack = (event) => {
    const [stream] = event.streams || [];
    if (!stream) {
      return;
    }
    remoteAudio.srcObject = stream;
    remoteAudio
      .play()
      .then(() => { })
      .catch(() => { });
  };

  peer.onconnectionstatechange = () => {
    if (!state.call.active) {
      return;
    }
    if (["failed", "disconnected", "closed"].includes(peer.connectionState)) {
      endCall(true, "Соединение прервано.");
    }
  };

  state.call.active = true;
  state.call.targetUserId = targetUserId;
  state.call.conversationId = conversationId;
  state.call.peer = peer;
  state.call.localStream = localStream;
  updateCallUi();
  return peer;
}

async function startOutgoingCall() {
  if (!canUseAudioCalls()) {
    setCallStatus("Звонки недоступны в этом браузере.", true);
    return;
  }

  const conversation = getActiveConversation();
  const targetUserId = conversation?.participant?.id;
  if (!targetUserId) {
    return;
  }

  if (!state.socket || state.socket.readyState !== WebSocket.OPEN) {
    setCallStatus("Нет соединения с сервером.", true);
    return;
  }

  if (state.call.active) {
    endCall(true, "Звонок завершен.");
    return;
  }

  if (state.call.pendingIncoming) {
    setCallStatus("Сначала ответьте на входящий звонок.");
    return;
  }

  try {
    const localStream = await navigator.mediaDevices.getUserMedia(getAudioConstraints());
    const peer = await createCallPeer(
      targetUserId,
      state.activeConversationId,
      localStream
    );

    const offer = await peer.createOffer();
    await peer.setLocalDescription(offer);

    sendSocketPayload({
      type: "call:signal",
      targetUserId,
      signalType: "offer",
      conversationId: state.activeConversationId,
      data: { sdp: peer.localDescription },
    });

    setCallStatus("Звоним...");
    startCallRingtone();
  } catch (error) {
    cleanupCallState();
    setCallStatus(error?.message || "Не удалось начать звонок.", true);
  }
}

async function handleCallSignal(payload) {
  if (!payload?.fromUserId || !payload?.signalType) {
    return;
  }

  const signalType = String(payload.signalType);
  const fromUserId = String(payload.fromUserId);
  const conversationId = String(payload.conversationId || "");
  const data = payload.data || {};

  if (signalType === "offer") {
    if (state.call.active) {
      sendSocketPayload({
        type: "call:signal",
        targetUserId: fromUserId,
        signalType: "busy",
        conversationId,
      });
      return;
    }

    if (!canUseAudioCalls()) {
      sendSocketPayload({
        type: "call:signal",
        targetUserId: fromUserId,
        signalType: "reject",
        conversationId,
      });
      setCallStatus("Входящий звонок отклонен: звонки недоступны в этом браузере.", true);
      return;
    }

    if (state.call.pendingIncoming && state.call.pendingIncoming.fromUserId !== fromUserId) {
      sendSocketPayload({
        type: "call:signal",
        targetUserId: fromUserId,
        signalType: "busy",
        conversationId,
      });
      return;
    }

    if (!data.sdp) {
      sendSocketPayload({
        type: "call:signal",
        targetUserId: fromUserId,
        signalType: "reject",
        conversationId,
      });
      setCallStatus("Некорректный входящий offer.", true);
      return;
    }

    const callerConversation =
      getConversationById(conversationId) || getConversationByParticipantId(fromUserId);
    const resolvedConversationId = callerConversation?.id || conversationId;
    const callerName = callerConversation?.participant?.username || "Собеседник";
    state.call.pendingIncoming = {
      fromUserId,
      conversationId: resolvedConversationId,
      offerSdp: data.sdp,
      callerName,
    };

    showIncomingCallUi(callerName);
    setCallStatus(`Входящий звонок от ${callerName}.`);
    startCallRingtone();
    updateCallUi();
    return;
  }

  if (!state.call.active || fromUserId !== state.call.targetUserId || !state.call.peer) {
    if (
      signalType === "end" &&
      state.call.pendingIncoming &&
      state.call.pendingIncoming.fromUserId === fromUserId
    ) {
      stopCallRingtone();
      clearPendingIncomingCall();
      updateCallUi();
      setCallStatus("Собеседник отменил звонок.");
    }
    return;
  }

  if (signalType === "answer") {
    if (!data.sdp) {
      return;
    }
    await state.call.peer.setRemoteDescription(new RTCSessionDescription(data.sdp));
    stopCallRingtone();
    setCallStatus("В звонке.");
    return;
  }

  if (signalType === "ice") {
    if (!data.candidate) {
      return;
    }
    try {
      await state.call.peer.addIceCandidate(new RTCIceCandidate(data.candidate));
    } catch {
    }
    return;
  }

  if (signalType === "reject") {
    endCall(false, "Собеседник отклонил звонок.");
    return;
  }

  if (signalType === "busy") {
    endCall(false, "Собеседник сейчас в другом звонке.");
    return;
  }

  if (signalType === "end") {
    endCall(false, "Собеседник завершил звонок.");
  }
}

function updateBlockUserUi() {
  const conversation = getActiveConversation();
  const blockedByMe = Boolean(conversation?.blockedByMe);
  const canToggle = Boolean(
    state.me && conversation?.participant?.id && !state.chatLocked
  );

  blockUserBtn.disabled = !canToggle || state.blockActionInFlight;
  blockUserBtn.classList.toggle("active", blockedByMe);
  blockUserBtn.textContent = blockedByMe ? "Разблокировать" : "Заблокировать";
}

function updateComposerUi() {
  const conversation = getActiveConversation();
  const blockedMe = Boolean(conversation?.blockedMe);
  const disabled = state.chatLocked || !conversation || blockedMe;

  messageInput.disabled = disabled;
  vigenereToggle.disabled = disabled;
  if (sendMessageBtn) {
    sendMessageBtn.disabled = disabled;
  }

  messageInput.placeholder = blockedMe
    ? "Вы заблокированы в этом чате."
    : DEFAULT_MESSAGE_PLACEHOLDER;
}

function updateChatLockUi() {
  const hasConversation = Boolean(state.activeConversationId);
  const canLock = Boolean(state.me && state.twoFa.enabled && hasConversation);
  const locked = state.chatLocked;

  chatLockBtn.disabled = !canLock;
  chatLockBtn.classList.toggle("active", locked);
  chatLockBtn.textContent = locked ? "Чат защищен" : "Защитить чат";

  chatLockOverlay.classList.toggle("hidden", !locked);
  chatMain.classList.toggle("chat-locked", locked);

  updateComposerUi();
  updateBlockUserUi();
  updateCallUi();
  settingsBtn.disabled = locked;

  if (!locked) {
    chatLockCodeInput.value = "";
    setChatLockStatus("");
  }
}

function setChatLocked(locked) {
  const shouldLock =
    Boolean(locked) &&
    Boolean(state.me) &&
    Boolean(state.twoFa.enabled) &&
    Boolean(state.activeConversationId);

  if (shouldLock === state.chatLocked) {
    updateDeleteUi();
    updateChatLockUi();
    return;
  }

  state.chatLocked = shouldLock;
  if (state.chatLocked) {
    setSettingsPanelOpen(false);
    state.deleteMode = false;
    state.selectedMessageIds.clear();
    setChatLockStatus("Введите 6-значный код из Google Authenticator.");
  } else {
    setChatLockStatus("");
  }

  updateDeleteUi();
  updateChatLockUi();
  renderMessages();

  if (state.chatLocked) {
    chatLockCodeInput.focus();
  } else {
    if (!messageInput.disabled) {
      messageInput.focus();
    }
    markConversationAsRead(state.activeConversationId);
  }
}

async function persistChatProtection(locked) {
  if (!state.activeConversationId) {
    return null;
  }

  const payload = await api(`/api/conversations/${state.activeConversationId}/protection`, {
    method: "POST",
    body: { locked: Boolean(locked) },
  });

  if (payload.conversation) {
    upsertConversation(payload.conversation);
  }

  const active = getActiveConversation();
  state.chatLocked = Boolean(active?.chatProtected && state.twoFa.enabled);
  renderConversationList();
  renderActiveConversationHeader();
  updateDeleteUi();
  updateChatLockUi();
  return payload;
}

async function verifyAndUnlockChat() {
  if (!state.chatLocked) {
    return;
  }

  const token = normalizeOtpToken(chatLockCodeInput.value);
  if (token.length !== 6) {
    setChatLockStatus("Введите корректный 6-значный код.", true);
    return;
  }

  chatUnlockBtn.disabled = true;
  setChatLockStatus("Проверка кода...");

  try {
    await api("/api/auth/2fa/verify", {
      method: "POST",
      body: { token },
    });
    await persistChatProtection(false);
    setChatLocked(false);
  } catch (error) {
    setChatLockStatus(error.message, true);
    chatLockCodeInput.focus();
    chatLockCodeInput.select();
  } finally {
    chatUnlockBtn.disabled = false;
  }
}

function updateDeleteUi() {
  const selectedCount = state.selectedMessageIds.size;
  const hasConversation = Boolean(state.activeConversationId);
  const locked = state.chatLocked;
  const isDeleteModeVisible = state.deleteMode && !locked;

  deleteToolbar.classList.toggle("hidden", !isDeleteModeVisible);
  deleteModeBtn.classList.toggle("active", state.deleteMode);
  deleteModeBtn.disabled = !hasConversation || locked;
  deleteModeBtn.textContent = "Удаление";
  deleteSelectionInfo.textContent = `Выбрано: ${selectedCount}`;
  deleteSelectedBtn.disabled = selectedCount === 0 || locked;
  deleteConversationBtn.disabled = !hasConversation || locked;
  deleteCancelBtn.disabled = locked;
}

function setDeleteMode(enabled) {
  state.deleteMode =
    Boolean(enabled) && Boolean(state.activeConversationId) && !state.chatLocked;
  if (!state.deleteMode) {
    state.selectedMessageIds.clear();
  }
  updateDeleteUi();
  renderMessages();
}

function toggleMessageSelection(messageId, rowElement = null) {
  if (!state.deleteMode) {
    return;
  }

  if (rowElement?.classList.contains("deleting")) {
    return;
  }

  if (state.selectedMessageIds.has(messageId)) {
    state.selectedMessageIds.delete(messageId);
  } else {
    state.selectedMessageIds.add(messageId);
  }

  updateDeleteUi();

  if (rowElement) {
    rowElement.classList.toggle(
      "selected-for-delete",
      state.selectedMessageIds.has(messageId)
    );
    return;
  }

  renderMessages();
}

function removeMessagesFromState(conversationId, messageIds) {
  const idsSet = new Set(messageIds || []);
  if (idsSet.size === 0) {
    return;
  }

  const existing = state.messagesByConversation.get(conversationId) || [];
  const next = existing.filter((message) => !idsSet.has(message.id));
  state.messagesByConversation.set(conversationId, next);

  for (const messageId of idsSet) {
    state.selectedMessageIds.delete(messageId);
  }

  const deletingIds = state.deletingMessageIdsByConversation.get(conversationId);
  if (deletingIds) {
    for (const messageId of idsSet) {
      deletingIds.delete(messageId);
    }
    if (deletingIds.size === 0) {
      state.deletingMessageIdsByConversation.delete(conversationId);
    }
  }
}

function getDeletingMessageSet(conversationId) {
  let ids = state.deletingMessageIdsByConversation.get(conversationId);
  if (!ids) {
    ids = new Set();
    state.deletingMessageIdsByConversation.set(conversationId, ids);
  }
  return ids;
}

function animateMessageDeletion(conversationId, messageIds) {
  const uniqueIds = [...new Set((messageIds || []).map((id) => String(id || "")))].filter(
    Boolean
  );
  if (uniqueIds.length === 0) {
    return;
  }

  const existingIds = new Set(
    (state.messagesByConversation.get(conversationId) || []).map((message) => message.id)
  );
  const deletingIds = getDeletingMessageSet(conversationId);
  const idsForAnimation = uniqueIds.filter(
    (id) => existingIds.has(id) && !deletingIds.has(id)
  );
  if (idsForAnimation.length === 0) {
    return;
  }

  for (const messageId of idsForAnimation) {
    deletingIds.add(messageId);
  }

  const isActiveConversation = state.activeConversationId === conversationId;
  if (isActiveConversation) {
    for (const messageId of idsForAnimation) {
      const row = messagesEl.querySelector(`[data-message-id="${messageId}"]`);
      if (row) {
        row.classList.add("deleting");
      }
    }
  }

  const finalizeDeletion = () => {
    removeMessagesFromState(conversationId, idsForAnimation);
    updateDeleteUi();
    if (conversationId === state.activeConversationId) {
      renderMessages();
    }
  };

  if (isActiveConversation) {
    window.setTimeout(finalizeDeletion, MESSAGE_DELETE_ANIMATION_MS);
  } else {
    finalizeDeletion();
  }
}

function applyReadState(conversationId, messageIds, readAt) {
  const idsSet = new Set((messageIds || []).map((id) => String(id || "")));
  if (idsSet.size === 0) {
    return false;
  }

  const messages = state.messagesByConversation.get(conversationId) || [];
  let changed = false;

  for (const message of messages) {
    if (!idsSet.has(message.id) || message.readAt) {
      continue;
    }
    message.readAt = String(readAt || new Date().toISOString());
    changed = true;
  }

  return changed;
}

async function markConversationAsRead(conversationId) {
  if (!conversationId || !state.me || state.chatLocked || document.hidden) {
    return;
  }

  if (state.readRequestsInFlight.has(conversationId)) {
    return;
  }

  const messages = state.messagesByConversation.get(conversationId) || [];
  const hasUnreadIncoming = messages.some(
    (message) => message.senderId !== state.me.id && !message.readAt
  );
  if (!hasUnreadIncoming) {
    return;
  }

  state.readRequestsInFlight.add(conversationId);
  try {
    const payload = await api(`/api/conversations/${conversationId}/read`, {
      method: "POST",
    });

    if (payload.readMessageIds?.length) {
      applyReadState(conversationId, payload.readMessageIds, payload.readAt);
    }

    if (payload.conversation) {
      upsertConversation(payload.conversation);
      renderConversationList();
      renderActiveConversationHeader();
      updateChatLockUi();
    }

    if (conversationId === state.activeConversationId) {
      renderMessages();
    }
  } catch {
  } finally {
    state.readRequestsInFlight.delete(conversationId);
  }
}

function setNoConversationHeader() {
  chatTitle.textContent = "Выберите диалог слева";
  chatPresence.textContent = "";
  chatPresence.classList.remove("online", "offline");
  if (!state.call.active && !state.call.pendingIncoming) {
    setCallStatus("");
  }
  updateBlockUserUi();
  updateComposerUi();
  updateCallUi();
}

function renderActiveConversationHeader() {
  const conversation = getConversationById(state.activeConversationId);
  if (!conversation) {
    setNoConversationHeader();
    return;
  }

  if (conversation.type === "group") {
    chatTitle.textContent = conversation.name || "Группа";
    const onlineCount = (conversation.participants || []).filter((p) => p.online).length;
    chatPresence.textContent = `${conversation.participants?.length || 0} участников, ${onlineCount} онлайн`;
    chatPresence.classList.remove("online", "offline");
  } else {
    chatTitle.textContent = conversation.participant?.username || "Диалог";
    const isOnline = Boolean(conversation.participant?.online);
    if (isOnline) {
      chatPresence.textContent = "онлайн";
    } else {
      const lastSeen = conversation.participant?.lastSeenAt;
      chatPresence.textContent = lastSeen ? formatLastSeen(lastSeen) : "оффлайн";
    }
    chatPresence.classList.toggle("online", isOnline);
    chatPresence.classList.toggle("offline", !isOnline);
  }
  hideTypingIndicator();
  updateBlockUserUi();
  updateComposerUi();
  updateCallUi();
}

function updateParticipantPresence(userId, online) {
  let changed = false;
  for (const conversation of state.conversations) {
    if (conversation.participant?.id === userId) {
      if (Boolean(conversation.participant.online) !== Boolean(online)) {
        conversation.participant.online = Boolean(online);
        changed = true;
      }
    }
    if (conversation.participants) {
      const p = conversation.participants.find((pp) => pp.id === userId);
      if (p && Boolean(p.online) !== Boolean(online)) {
        p.online = Boolean(online);
        changed = true;
      }
    }
  }
  return changed;
}

function playIncomingMessageSound() {
  try {
    const audio = new Audio(MESSAGE_SOUND_SRC);
    audio.play().catch(() => { });
  } catch {
  }
}

async function removeConversationFromState(conversationId) {
  if (state.call.active && state.call.conversationId === conversationId) {
    endCall(false, "Звонок завершен.");
  }

  state.conversations = state.conversations.filter(
    (conversation) => conversation.id !== conversationId
  );
  state.messagesByConversation.delete(conversationId);
  state.deletingMessageIdsByConversation.delete(conversationId);
  state.readRequestsInFlight.delete(conversationId);

  if (state.activeConversationId === conversationId) {
    state.activeConversationId = null;
    if (state.conversations.length > 0) {
      await selectConversation(state.conversations[0].id);
      return;
    }

    setChatLocked(false);
    setNoConversationHeader();
    renderConversationList();
    renderMessages();
    resetMobileChatState();
    updateChatLockUi();
    return;
  }

  renderConversationList();
  renderActiveConversationHeader();
  updateChatLockUi();
}

function setAuthTab(tab) {
  const isLogin = tab === "login";
  tabLogin.classList.toggle("active", isLogin);
  tabRegister.classList.toggle("active", !isLogin);
  loginForm.classList.toggle("hidden", !isLogin);
  registerForm.classList.toggle("hidden", isLogin);
  if (isLogin) {
    resetLoginTwoFactorStep();
  }
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
  setSettingsPanelOpen(false);
  if (state.call.active) {
    endCall(true, "Звонок завершен.");
  } else {
    cleanupCallState();
  }
  setCallStatus("");
  state.chatLocked = false;
  state.blockActionInFlight = false;
  state.deleteMode = false;
  state.selectedMessageIds.clear();
  resetVigenereKey();
  saveUiSettings();
  resetLoginTwoFactorStep();
  clearTwoFaSetup();
  state.twoFa.enabled = false;
  renderTwoFaState();
  closeSocket();
  state.me = null;
  state.conversations = [];
  state.activeConversationId = null;
  state.messagesByConversation = new Map();
  state.translationCache = new Map();
  state.translationRequests = new Map();
  state.deletingMessageIdsByConversation = new Map();
  state.readRequestsInFlight = new Set();
  deleteAccountBtn.disabled = false;
  setNoConversationHeader();
  updateDeleteUi();
  updateChatLockUi();
}

function showChat() {
  authView.classList.add("hidden");
  chatView.classList.remove("hidden");
  applySidebarWidth(state.ui.sidebarWidth);
  renderActiveConversationHeader();
  updateChatLockUi();
}

function resetMobileChatState() {
  chatView.classList.remove("chat-open");
}

function openMobileChatState() {
  chatView.classList.add("chat-open");
}

function normalizeTranslationLanguage(value) {
  const language = String(value || "").trim().toLowerCase();
  if (!ALLOWED_TRANSLATION_LANGS.has(language)) {
    return "off";
  }
  return language;
}

function normalizeTheme(value) {
  const theme = String(value || "").trim().toLowerCase();
  if (!ALLOWED_THEMES.has(theme)) {
    return "light";
  }
  return theme;
}

function normalizeVigenereKey(value) {
  const key = String(value || "").trim();
  return key || DEFAULT_VIGENERE_KEY;
}

function normalizeSidebarWidth(value) {
  const width = Number(value);
  if (!Number.isFinite(width)) {
    return SIDEBAR_DEFAULT_WIDTH;
  }

  return Math.max(SIDEBAR_MIN_WIDTH, Math.min(SIDEBAR_MAX_WIDTH, Math.round(width)));
}

function getSidebarMaxWidth() {
  const containerWidth = chatView.clientWidth || window.innerWidth || SIDEBAR_DEFAULT_WIDTH;
  const maxByLayout = containerWidth - SIDEBAR_MAIN_MIN_WIDTH - SIDEBAR_HANDLE_WIDTH;
  return Math.max(SIDEBAR_MIN_WIDTH, Math.min(SIDEBAR_MAX_WIDTH, maxByLayout));
}

function applySidebarWidth(width, persist = false) {
  const maxWidth = getSidebarMaxWidth();
  const normalized = normalizeSidebarWidth(width);
  const clamped = Math.max(SIDEBAR_MIN_WIDTH, Math.min(normalized, maxWidth));

  state.ui.sidebarWidth = clamped;
  chatView.style.setProperty("--sidebar-width", `${clamped}px`);

  if (persist) {
    saveUiSettings();
  }
}

function initializeSidebarResize() {
  if (!sidebarResizeHandle) {
    return;
  }

  let dragStartX = 0;
  let dragStartWidth = state.ui.sidebarWidth;

  const stopDragging = () => {
    chatView.classList.remove("resizing");
    document.removeEventListener("pointermove", handlePointerMove);
    document.removeEventListener("pointerup", stopDragging);
    document.removeEventListener("pointercancel", stopDragging);
    saveUiSettings();
  };

  const handlePointerMove = (event) => {
    if (!chatView.classList.contains("resizing")) {
      return;
    }

    const delta = event.clientX - dragStartX;
    applySidebarWidth(dragStartWidth + delta);
  };

  sidebarResizeHandle.addEventListener("pointerdown", (event) => {
    if (event.button !== 0 || window.matchMedia("(max-width: 950px)").matches) {
      return;
    }

    event.preventDefault();
    dragStartX = event.clientX;
    dragStartWidth = state.ui.sidebarWidth;
    chatView.classList.add("resizing");
    sidebarResizeHandle.setPointerCapture?.(event.pointerId);
    document.addEventListener("pointermove", handlePointerMove);
    document.addEventListener("pointerup", stopDragging);
    document.addEventListener("pointercancel", stopDragging);
  });

  sidebarResizeHandle.addEventListener("keydown", (event) => {
    if (window.matchMedia("(max-width: 950px)").matches) {
      return;
    }

    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") {
      return;
    }

    event.preventDefault();
    const delta = event.key === "ArrowLeft" ? -24 : 24;
    applySidebarWidth(state.ui.sidebarWidth + delta, true);
  });
}

function resetVigenereKey() {
  state.ui.vigenereKey = DEFAULT_VIGENERE_KEY;
  if (vigenereKeyInput) {
    vigenereKeyInput.value = DEFAULT_VIGENERE_KEY;
  }
}

function applyTheme() {
  document.documentElement.dataset.theme = normalizeTheme(state.ui.theme);
}

function saveUiSettings() {
  try {
    localStorage.setItem(
      UI_SETTINGS_KEY,
      JSON.stringify({
        theme: state.ui.theme,
        targetLanguage: state.ui.targetLanguage,
        vigenereEnabled: state.ui.vigenereEnabled,
        sidebarWidth: normalizeSidebarWidth(state.ui.sidebarWidth),
        microphoneId: state.ui.microphoneId || "",
      })
    );
  } catch {
  }
}

function loadUiSettings() {
  try {
    const raw = localStorage.getItem(UI_SETTINGS_KEY);
    if (!raw) {
      return;
    }

    const parsed = JSON.parse(raw);
    state.ui.theme = normalizeTheme(parsed.theme);
    state.ui.targetLanguage = normalizeTranslationLanguage(parsed.targetLanguage);
    state.ui.vigenereEnabled = Boolean(parsed.vigenereEnabled);
    state.ui.sidebarWidth = normalizeSidebarWidth(parsed.sidebarWidth);
    state.ui.vigenereKey = DEFAULT_VIGENERE_KEY;
    state.ui.microphoneId = String(parsed.microphoneId || "");
  } catch {
  }
}

function syncUiControls() {
  themeSelect.value = normalizeTheme(state.ui.theme);
  translationLanguage.value = normalizeTranslationLanguage(state.ui.targetLanguage);
  vigenereKeyInput.value = normalizeVigenereKey(state.ui.vigenereKey);
  updateVigenereToggle();
  loadMicrophoneDevices();
}

async function loadMicrophoneDevices() {
  if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
    return;
  }
  try {
    const devices = await navigator.mediaDevices.enumerateDevices();
    const mics = devices.filter((d) => d.kind === "audioinput");
    microphoneSelect.innerHTML = '<option value="">Микрофон по умолчанию</option>';
    for (const mic of mics) {
      const opt = document.createElement("option");
      opt.value = mic.deviceId;
      opt.textContent = mic.label || `Микрофон ${microphoneSelect.options.length}`;
      microphoneSelect.appendChild(opt);
    }
    microphoneSelect.value = state.ui.microphoneId || "";
  } catch {
  }
}

function getAudioConstraints() {
  const id = state.ui.microphoneId;
  return id ? { audio: { deviceId: { exact: id } } } : { audio: true };
}

function updateVigenereToggle() {
  const enabled = state.ui.vigenereEnabled;
  vigenereToggle.classList.toggle("active", enabled);
  vigenereToggle.textContent = enabled ? "Encrypt send: ON" : "Encrypt send: OFF";
}

function setSettingsPanelOpen(isOpen) {
  const shouldOpen = Boolean(isOpen) && !state.chatLocked;
  settingsPanel.classList.toggle("hidden", !shouldOpen);
  if (shouldOpen) {
    loadMicrophoneDevices();
  }
}

function quoteText(text) {
  return `"${String(text || "")}"`;
}

const EN_LOWER = "abcdefghijklmnopqrstuvwxyz";
const EN_UPPER = EN_LOWER.toUpperCase();
const RU_LOWER = "абвгдеёжзийклмнопрстуфхцчшщъыьэюя";
const RU_UPPER = RU_LOWER.toUpperCase();

function buildVigenereShifts(key) {
  const shifts = { en: [], ru: [] };
  for (const char of normalizeVigenereKey(key).toLowerCase()) {
    const enIndex = EN_LOWER.indexOf(char);
    if (enIndex >= 0) {
      shifts.en.push(enIndex);
      continue;
    }

    const ruIndex = RU_LOWER.indexOf(char);
    if (ruIndex >= 0) {
      shifts.ru.push(ruIndex);
    }
  }
  return shifts;
}

function transformWithVigenere(text, key, decrypt = false) {
  const shifts = buildVigenereShifts(key);
  if (shifts.en.length === 0 && shifts.ru.length === 0) {
    return String(text || "");
  }

  const direction = decrypt ? -1 : 1;
  const counters = { en: 0, ru: 0 };
  const source = String(text || "");
  let output = "";

  for (const char of source) {
    const enLowerIndex = EN_LOWER.indexOf(char);
    if (enLowerIndex >= 0) {
      if (shifts.en.length === 0) {
        output += char;
        continue;
      }
      const shift = shifts.en[counters.en % shifts.en.length];
      const nextIndex =
        (enLowerIndex + direction * shift + EN_LOWER.length) % EN_LOWER.length;
      output += EN_LOWER[nextIndex];
      counters.en += 1;
      continue;
    }

    const enUpperIndex = EN_UPPER.indexOf(char);
    if (enUpperIndex >= 0) {
      if (shifts.en.length === 0) {
        output += char;
        continue;
      }
      const shift = shifts.en[counters.en % shifts.en.length];
      const nextIndex =
        (enUpperIndex + direction * shift + EN_UPPER.length) % EN_UPPER.length;
      output += EN_UPPER[nextIndex];
      counters.en += 1;
      continue;
    }

    const ruLowerIndex = RU_LOWER.indexOf(char);
    if (ruLowerIndex >= 0) {
      if (shifts.ru.length === 0) {
        output += char;
        continue;
      }
      const shift = shifts.ru[counters.ru % shifts.ru.length];
      const nextIndex =
        (ruLowerIndex + direction * shift + RU_LOWER.length) % RU_LOWER.length;
      output += RU_LOWER[nextIndex];
      counters.ru += 1;
      continue;
    }

    const ruUpperIndex = RU_UPPER.indexOf(char);
    if (ruUpperIndex >= 0) {
      if (shifts.ru.length === 0) {
        output += char;
        continue;
      }
      const shift = shifts.ru[counters.ru % shifts.ru.length];
      const nextIndex =
        (ruUpperIndex + direction * shift + RU_UPPER.length) % RU_UPPER.length;
      output += RU_UPPER[nextIndex];
      counters.ru += 1;
      continue;
    }

    output += char;
  }

  return output;
}

function vigenereEncrypt(text, key) {
  return transformWithVigenere(text, key, false);
}

function vigenereDecrypt(text, key) {
  return transformWithVigenere(text, key, true);
}

function createAuxLine(text) {
  const line = document.createElement("p");
  line.className = "bubble-aux";
  line.textContent = quoteText(text);
  return line;
}

function translationCacheKey(sourceText, language) {
  return `${language}:${sourceText}`;
}

async function getTranslatedText(sourceText, language) {
  const cacheKey = translationCacheKey(sourceText, language);
  if (state.translationCache.has(cacheKey)) {
    return state.translationCache.get(cacheKey);
  }

  if (state.translationRequests.has(cacheKey)) {
    return state.translationRequests.get(cacheKey);
  }

  const request = api("/api/translate", {
    method: "POST",
    body: {
      text: sourceText,
      targetLang: language,
    },
  })
    .then((payload) => {
      const translated = String(payload.translatedText || "").trim();
      return translated || sourceText;
    })
    .catch(() => sourceText)
    .finally(() => {
      state.translationRequests.delete(cacheKey);
    });

  state.translationRequests.set(cacheKey, request);
  const translated = await request;
  state.translationCache.set(cacheKey, translated);
  return translated;
}

async function hydrateTranslationLine(sourceText, language, element) {
  const translated = await getTranslatedText(sourceText, language);
  if (!element.isConnected || state.ui.targetLanguage !== language) {
    return;
  }
  element.textContent = quoteText(translated);
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

function getInitial(text) {
  const trimmed = String(text || "").trim();
  if (!trimmed) {
    return "?";
  }

  return Array.from(trimmed)[0].toUpperCase();
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

    const isGroup = conversation.type === "group";
    const title = isGroup ? (conversation.name || "Группа") : (conversation.participant ? conversation.participant.username : "Диалог");
    const avatarUrl = !isGroup ? conversation.participant?.avatarUrl : null;
    const isOnline = isGroup ? false : Boolean(conversation.participant?.online);

    let preview = conversation.lastMessage
      ? (conversation.lastMessage.messageType === "voice" ? "🎤 Голосовое" : conversation.lastMessage.text)
      : "Сообщений еще нет";
    if (conversation.lastMessage?.senderId === state.me?.id) {
      preview = `${conversation.lastMessage.readAt ? "✓✓" : "✓"} ${preview}`;
    }
    button.dataset.initial = getInitial(title);

    if (avatarUrl) {
      button.classList.add("has-avatar");
      const avatarImg = document.createElement("img");
      avatarImg.src = avatarUrl;
      avatarImg.alt = title;
      avatarImg.className = "list-item-avatar";
      button.appendChild(avatarImg);
    }

    const row = document.createElement("div");
    row.className = "item-row";

    const titleWrap = document.createElement("div");
    titleWrap.className = "item-title-wrap";

    if (!isGroup) {
      const presenceDot = document.createElement("span");
      presenceDot.className = `presence-dot ${isOnline ? "online" : "offline"}`;
      titleWrap.appendChild(presenceDot);
    }

    const titleEl = document.createElement("p");
    titleEl.className = "item-title";
    titleEl.textContent = title;
    titleWrap.appendChild(titleEl);

    if (isGroup) {
      const badge = document.createElement("span");
      badge.className = "group-badge";
      badge.textContent = `👥 ${conversation.participants?.length || 0}`;
      titleWrap.appendChild(badge);
    }

    const timeEl = document.createElement("p");
    timeEl.className = "item-time";
    timeEl.textContent = formatTime(conversation.updatedAt);

    row.appendChild(titleWrap);
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
  if (existing.some((item) => item.id === message.id)) {
    return false;
  }

  existing.push(message);
  existing.sort((a, b) => a.createdAt.localeCompare(b.createdAt));
  state.messagesByConversation.set(message.conversationId, existing);
  return true;
}

function createMessageRow(message, deletingIds = new Set()) {
  const row = document.createElement("article");
  const mine = message.senderId === state.me.id;
  row.className = `message-row ${mine ? "mine" : "their"}`;
  row.dataset.messageId = message.id;
  if (deletingIds.has(message.id)) {
    row.classList.add("deleting");
  }

  if (state.deleteMode) {
    row.classList.add("selectable");
    if (state.selectedMessageIds.has(message.id)) {
      row.classList.add("selected-for-delete");
    }

    row.addEventListener("click", () => {
      toggleMessageSelection(message.id, row);
    });
  }

  const bubble = document.createElement("div");
  bubble.className = "bubble";

  // Reply badge
  if (message.replyToId) {
    const messages = state.messagesByConversation.get(message.conversationId) || [];
    const original = messages.find((m) => m.id === message.replyToId);
    const replyBadge = document.createElement("span");
    replyBadge.className = "bubble-reply-badge";
    replyBadge.textContent = `↩ ${original ? (original.messageType === "voice" ? "🎤 Голосовое" : (original.text || "").slice(0, 50)) : "Сообщение"}`;
    replyBadge.addEventListener("click", () => {
      const el = messagesEl.querySelector(`[data-message-id="${message.replyToId}"]`);
      if (el) { el.scrollIntoView({ behavior: "smooth", block: "center" }); el.style.outline = "2px solid var(--accent)"; setTimeout(() => { el.style.outline = ""; }, 1500); }
    });
    bubble.appendChild(replyBadge);
  }

  // Forward badge
  if (message.forwardFromId) {
    const fwdBadge = document.createElement("span");
    fwdBadge.className = "bubble-forward-badge";
    fwdBadge.textContent = "↗ Пересланное сообщение";
    bubble.appendChild(fwdBadge);
  }

  // Voice message
  if (message.messageType === "voice" && message.voiceData) {
    const player = document.createElement("div");
    player.className = "voice-message-player";
    const playBtn = document.createElement("button");
    playBtn.type = "button";
    playBtn.className = "voice-play-btn";
    playBtn.innerHTML = "▶";
    const dur = document.createElement("span");
    dur.className = "voice-duration";
    dur.textContent = "Голосовое";
    let audio = null;
    playBtn.addEventListener("click", () => {
      if (!audio) {
        audio = new Audio(message.voiceData);
        audio.addEventListener("ended", () => { playBtn.innerHTML = "▶"; });
      }
      if (audio.paused) { audio.play(); playBtn.innerHTML = "⏸"; }
      else { audio.pause(); playBtn.innerHTML = "▶"; }
    });
    player.appendChild(playBtn);
    player.appendChild(dur);
    bubble.appendChild(player);
  } else {
    const originalText = String(message.text || "");
    const isVigenereEncrypted = message.encryption?.type === "vigenere";

    const text = document.createElement("p");
    text.textContent = originalText;
    bubble.appendChild(text);

    let translationSourceText = originalText;
    if (isVigenereEncrypted) {
      const decryptedText = vigenereDecrypt(originalText, state.ui.vigenereKey);
      bubble.appendChild(createAuxLine(decryptedText));
      translationSourceText = decryptedText;
    }

    if (state.ui.targetLanguage !== "off") {
      const language = state.ui.targetLanguage;
      const translationLine = createAuxLine("Перевод...");
      bubble.appendChild(translationLine);
      hydrateTranslationLine(translationSourceText, language, translationLine);
    }
  }

  // Reactions
  const reactions = message.reactions || [];
  if (reactions.length > 0) {
    const reactionsEl = document.createElement("div");
    reactionsEl.className = "bubble-reactions";
    const grouped = {};
    for (const r of reactions) {
      if (!grouped[r.emoji]) grouped[r.emoji] = [];
      grouped[r.emoji].push(r.userId);
    }
    for (const [emoji, userIds] of Object.entries(grouped)) {
      const badge = document.createElement("span");
      badge.className = "reaction-badge" + (userIds.includes(state.me?.id) ? " mine" : "");
      badge.innerHTML = `${emoji} <span class="reaction-count">${userIds.length}</span>`;
      badge.addEventListener("click", async () => {
        try {
          await api(`/api/conversations/${message.conversationId}/messages/${message.id}/reactions`, { method: "POST", body: { emoji } });
        } catch { }
      });
      reactionsEl.appendChild(badge);
    }
    bubble.appendChild(reactionsEl);
  }

  const meta = document.createElement("div");
  meta.className = "bubble-meta";
  if (mine) {
    const readMarker = message.readAt ? "прочитано" : "доставлено";
    meta.textContent = `Вы, ${formatDateTime(message.createdAt)} · ${readMarker}`;
  } else {
    meta.textContent = `${message.sender?.username || "Пользователь"}, ${formatDateTime(
      message.createdAt
    )}`;
  }
  if (message.editedAt) {
    const editedSpan = document.createElement("span");
    editedSpan.className = "bubble-edited";
    editedSpan.textContent = "(ред.)";
    meta.appendChild(editedSpan);
  }
  bubble.appendChild(meta);

  row.appendChild(bubble);
  return row;
}

function appendMessageToActiveView(message) {
  if (!state.activeConversationId || message.conversationId !== state.activeConversationId) {
    return false;
  }

  if (messagesEl.querySelector(`[data-message-id="${message.id}"]`)) {
    return true;
  }

  const emptyNote = messagesEl.querySelector(".empty-note");
  if (emptyNote) {
    messagesEl.innerHTML = "";
  }

  const deletingIds =
    state.deletingMessageIdsByConversation.get(state.activeConversationId) || new Set();
  messagesEl.appendChild(createMessageRow(message, deletingIds));

  if (!state.deleteMode) {
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  return true;
}

function renderMessages() {
  messagesEl.innerHTML = "";

  if (!state.activeConversationId) {
    messagesEl.appendChild(createEmptyListNote("Выберите чат, чтобы начать переписку."));
    return;
  }

  const messages = state.messagesByConversation.get(state.activeConversationId) || [];
  const deletingIds =
    state.deletingMessageIdsByConversation.get(state.activeConversationId) || new Set();
  if (messages.length === 0) {
    messagesEl.appendChild(createEmptyListNote("Напишите первое сообщение в этом диалоге."));
    return;
  }

  for (const message of messages) {
    messagesEl.appendChild(createMessageRow(message, deletingIds));
  }

  if (!state.deleteMode) {
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }
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
    button.dataset.initial = getInitial(user.username);

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
  const activeConversation = getConversationById(conversationId);
  state.chatLocked = Boolean(activeConversation?.chatProtected && state.twoFa.enabled);
  state.deleteMode = false;
  state.selectedMessageIds.clear();
  updateDeleteUi();
  updateChatLockUi();
  renderConversationList();
  renderActiveConversationHeader();

  await loadMessages(conversationId);
  renderMessages();
  markConversationAsRead(conversationId);

  if (window.matchMedia("(max-width: 950px)").matches) {
    openMobileChatState();
  }
}

async function loadConversations() {
  const payload = await api("/api/conversations");
  state.conversations = payload.conversations || [];
  state.conversations.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  state.activeConversationId = null;
  state.deletingMessageIdsByConversation = new Map();
  state.readRequestsInFlight = new Set();
  state.deleteMode = false;
  state.selectedMessageIds.clear();
  updateDeleteUi();

  renderConversationList();
  if (state.conversations.length > 0) {
    await selectConversation(state.conversations[0].id);
  } else {
    setChatLocked(false);
    state.activeConversationId = null;
    setNoConversationHeader();
    renderMessages();
    resetMobileChatState();
  }
  updateChatLockUi();
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
      const added = addMessage(payload.message);
      if (payload.message.senderId !== state.me?.id) {
        playIncomingMessageSound();
        const conv = getConversationById(payload.message.conversationId);
        const senderName = payload.message.sender?.username || "Новое сообщение";
        const previewText = payload.message.messageType === "voice" ? "🎤 Голосовое" : (payload.message.text || "").slice(0, 60);
        showPushNotification(senderName, previewText);
      }
      if (payload.message.conversationId === state.activeConversationId) {
        if (added) {
          appendMessageToActiveView(payload.message);
        }
        markConversationAsRead(payload.message.conversationId);
        hideTypingIndicator();
      }
    }

    if (payload.type === "conversation:update" && payload.conversation) {
      upsertConversation(payload.conversation);
      if (payload.conversation.id === state.activeConversationId) {
        state.chatLocked = Boolean(payload.conversation.chatProtected && state.twoFa.enabled);
      }
      renderConversationList();
      renderActiveConversationHeader();
      updateDeleteUi();
      updateChatLockUi();
    }

    if (payload.type === "message:read" && payload.conversationId) {
      const changed = applyReadState(
        payload.conversationId,
        payload.messageIds || [],
        payload.readAt
      );
      if (changed) {
        renderConversationList();
        if (payload.conversationId === state.activeConversationId) {
          renderMessages();
        }
      }
    }

    if (payload.type === "typing" && payload.conversationId === state.activeConversationId && payload.userId !== state.me?.id) {
      showTypingIndicator(payload.username || "Кто-то");
      clearTimeout(state.typingTimers.get(payload.userId));
      state.typingTimers.set(payload.userId, setTimeout(() => { hideTypingIndicator(); state.typingTimers.delete(payload.userId); }, 3000));
    }

    if (payload.type === "message:edited" && payload.message) {
      const msgs = state.messagesByConversation.get(payload.message.conversationId) || [];
      const idx = msgs.findIndex((m) => m.id === payload.message.id);
      if (idx >= 0) { msgs[idx] = { ...msgs[idx], text: payload.message.text, editedAt: payload.message.editedAt }; }
      if (payload.message.conversationId === state.activeConversationId) renderMessages();
    }

    if (payload.type === "message:reactions" && payload.conversationId && payload.messageId) {
      const msgs = state.messagesByConversation.get(payload.conversationId) || [];
      const msg = msgs.find((m) => m.id === payload.messageId);
      if (msg) { msg.reactions = payload.reactions || []; }
      if (payload.conversationId === state.activeConversationId) renderMessages();
    }

    if (payload.type === "presence:update" && payload.userId) {
      // Update lastSeenAt in conversations
      for (const conv of state.conversations) {
        if (conv.participant && conv.participant.id === payload.userId) {
          conv.participant.lastSeenAt = payload.lastSeenAt || null;
        }
        if (conv.participants) {
          const p = conv.participants.find((pp) => pp.id === payload.userId);
          if (p) p.lastSeenAt = payload.lastSeenAt || null;
        }
      }
      if (updateParticipantPresence(payload.userId, payload.online)) {
        renderConversationList();
        renderActiveConversationHeader();
      }
    }

    if (payload.type === "message:deleted" && payload.conversationId) {
      animateMessageDeletion(payload.conversationId, payload.messageIds || []);
    }

    if (payload.type === "conversation:deleted" && payload.conversationId) {
      await removeConversationFromState(payload.conversationId);
      updateDeleteUi();
    }

    if (payload.type === "call:signal") {
      await handleCallSignal(payload);
    }
  });

  socket.addEventListener("close", () => {
    state.socket = null;
    if (state.call.active) {
      endCall(false, "Соединение с сервером потеряно.");
    } else if (state.call.pendingIncoming) {
      stopCallRingtone();
      clearPendingIncomingCall();
      updateCallUi();
      setCallStatus("Соединение с сервером потеряно.");
    }
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
  state.chatLocked = false;
  resetVigenereKey();
  saveUiSettings();
  setChatLockStatus("");
  meName.textContent = `${user.username} (${user.email})`;
  showChat();
  authStatus.textContent = "";
  resetLoginTwoFactorStep();
  renderSearchResults([]);
  updateAvatarPreview();
  await refreshTwoFaStatus();
  await loadConversations();
  connectSocket();
}

tabLogin.addEventListener("click", () => setAuthTab("login"));
tabRegister.addEventListener("click", () => setAuthTab("register"));
loginOtpCancelBtn.addEventListener("click", () => {
  resetLoginTwoFactorStep();
  authStatus.textContent = "";
});

loginForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  authStatus.textContent = "";

  const formData = new FormData(loginForm);
  const login = String(formData.get("login") || "");
  const password = String(formData.get("password") || "");
  const otpToken = normalizeOtpToken(formData.get("otp"));

  try {
    if (state.loginChallengeToken) {
      if (otpToken.length !== 6) {
        throw new Error("Enter 6-digit code from Google Authenticator");
      }

      const payload = await api("/api/auth/login/2fa", {
        method: "POST",
        body: {
          challengeToken: state.loginChallengeToken,
          token: otpToken,
        },
      });

      loginForm.reset();
      await bootstrapSession(payload.user);
      return;
    }

    const payload = await api("/api/auth/login", {
      method: "POST",
      body: { login, password },
    });

    if (payload.requires2fa) {
      startLoginTwoFactorStep(payload.challengeToken);
      authStatus.textContent = "Enter 6-digit code from Google Authenticator";
      return;
    }

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

settingsBtn.addEventListener("click", () => {
  if (state.chatLocked) {
    return;
  }

  const willOpen = settingsPanel.classList.contains("hidden");
  if (willOpen && state.deleteMode) {
    setDeleteMode(false);
  }
  setSettingsPanelOpen(willOpen);
  if (willOpen && state.me) {
    refreshTwoFaStatus();
  }
});

closeSettingsBtn.addEventListener("click", () => {
  setSettingsPanelOpen(false);
});

settingsPanel.addEventListener("click", (event) => {
  if (event.target === settingsPanel) {
    setSettingsPanelOpen(false);
  }
});

deleteAccountBtn.addEventListener("click", async () => {
  if (!state.me) {
    return;
  }

  const confirmed = window.confirm(
    "Удалить аккаунт? Это действие необратимо и удалит ваши чаты."
  );
  if (!confirmed) {
    return;
  }

  deleteAccountBtn.disabled = true;
  try {
    await api("/api/auth/account", { method: "DELETE" });
    showAuth();
    setAuthTab("login");
    authStatus.textContent = "Аккаунт удален.";
  } catch (error) {
    authStatus.textContent = error.message;
  } finally {
    deleteAccountBtn.disabled = false;
  }
});

deleteModeBtn.addEventListener("click", () => {
  if (state.chatLocked) {
    return;
  }

  if (!state.activeConversationId) {
    return;
  }

  if (state.deleteMode) {
    setDeleteMode(false);
    return;
  }

  setSettingsPanelOpen(false);
  setDeleteMode(true);
});

deleteCancelBtn.addEventListener("click", () => {
  setDeleteMode(false);
});

deleteSelectedBtn.addEventListener("click", async () => {
  if (!state.activeConversationId) {
    return;
  }

  const messageIds = Array.from(state.selectedMessageIds);
  if (messageIds.length === 0) {
    return;
  }

  if (!window.confirm(`Удалить ${messageIds.length} сообщени(е/я) для всех участников?`)) {
    return;
  }

  try {
    const payload = await api(`/api/conversations/${state.activeConversationId}/messages`, {
      method: "DELETE",
      body: { messageIds },
    });

    const deleted = payload.deletedMessageIds || messageIds;
    animateMessageDeletion(state.activeConversationId, deleted);
    if (payload.conversation) {
      upsertConversation(payload.conversation);
      renderConversationList();
    }
    renderActiveConversationHeader();
    setDeleteMode(false);
  } catch (error) {
    authStatus.textContent = error.message;
  }
});

deleteConversationBtn.addEventListener("click", async () => {
  if (!state.activeConversationId) {
    return;
  }

  if (!window.confirm("Удалить весь чат и все сообщения для обоих участников?")) {
    return;
  }

  const deletingId = state.activeConversationId;

  try {
    const payload = await api(`/api/conversations/${deletingId}`, {
      method: "DELETE",
    });

    await removeConversationFromState(payload.deletedConversationId || deletingId);
    setDeleteMode(false);
  } catch (error) {
    authStatus.textContent = error.message;
  }
});

blockUserBtn.addEventListener("click", async () => {
  if (state.chatLocked || !state.me) {
    return;
  }

  const conversation = getActiveConversation();
  const partnerId = conversation?.participant?.id;
  if (!partnerId || state.blockActionInFlight) {
    return;
  }

  state.blockActionInFlight = true;
  updateBlockUserUi();

  const shouldBlock = !conversation.blockedByMe;
  const endpoint = shouldBlock ? "block" : "unblock";

  try {
    const payload = await api(`/api/users/${partnerId}/${endpoint}`, {
      method: "POST",
    });

    if (payload.conversation) {
      upsertConversation(payload.conversation);
    } else {
      conversation.blockedByMe = shouldBlock;
    }

    renderConversationList();
    renderActiveConversationHeader();
    updateChatLockUi();
  } catch (error) {
    authStatus.textContent = error.message;
  } finally {
    state.blockActionInFlight = false;
    updateBlockUserUi();
  }
});

callBtn.addEventListener("click", async () => {
  if (state.call.active) {
    endCall(true, "Звонок завершен.");
    return;
  }

  if (state.call.pendingIncoming) {
    setCallStatus("Сначала ответьте на входящий звонок.");
    return;
  }

  await startOutgoingCall();
});

acceptCallBtn.addEventListener("click", async () => {
  await acceptPendingIncomingCall();
});

rejectCallBtn.addEventListener("click", () => {
  rejectPendingIncomingCall();
});

chatLockBtn.addEventListener("click", async () => {
  if (!state.activeConversationId || !state.twoFa.enabled || !state.me) {
    return;
  }

  if (state.chatLocked) {
    chatLockCodeInput.focus();
    return;
  }

  setDeleteMode(false);
  setSettingsPanelOpen(false);
  setChatLocked(true);
  try {
    await persistChatProtection(true);
  } catch (error) {
    setChatLocked(false);
    authStatus.textContent = error.message;
  }
});

chatUnlockBtn.addEventListener("click", () => {
  verifyAndUnlockChat();
});

chatLockCodeInput.addEventListener("keydown", (event) => {
  if (event.key !== "Enter") {
    return;
  }
  event.preventDefault();
  verifyAndUnlockChat();
});

twoFaSetupBtn.addEventListener("click", async () => {
  if (!state.me) {
    return;
  }

  try {
    const payload = await api("/api/auth/2fa/setup", { method: "POST" });
    state.twoFa.setupSecret = String(payload.secret || "");
    state.twoFa.setupOtpAuthUrl = String(payload.otpauthUrl || "");
    renderTwoFaState();
    setTwoFaStatusText("Scan QR and confirm with a 6-digit code.");
  } catch (error) {
    setTwoFaStatusText(error.message, true);
  }
});

twoFaEnableBtn.addEventListener("click", async () => {
  const token = normalizeOtpToken(twoFaEnableCodeInput.value);
  if (token.length !== 6) {
    setTwoFaStatusText("Enter a valid 6-digit code.", true);
    return;
  }

  try {
    await api("/api/auth/2fa/enable", {
      method: "POST",
      body: { token },
    });
    clearTwoFaSetup();
    state.twoFa.enabled = true;
    renderTwoFaState();
    setTwoFaStatusText("2FA has been enabled.");
  } catch (error) {
    setTwoFaStatusText(error.message, true);
  }
});

twoFaDisableBtn.addEventListener("click", async () => {
  const token = normalizeOtpToken(twoFaDisableCodeInput.value);
  if (token.length !== 6) {
    setTwoFaStatusText("Enter a valid 6-digit code.", true);
    return;
  }

  try {
    await api("/api/auth/2fa/disable", {
      method: "POST",
      body: { token },
    });
    clearTwoFaSetup();
    state.twoFa.enabled = false;
    for (const conversation of state.conversations) {
      conversation.chatProtected = false;
    }
    setChatLocked(false);
    renderTwoFaState();
    setTwoFaStatusText("2FA has been disabled.");
  } catch (error) {
    setTwoFaStatusText(error.message, true);
  }
});

themeSelect.addEventListener("change", () => {
  state.ui.theme = normalizeTheme(themeSelect.value);
  applyTheme();
  saveUiSettings();
});

translationLanguage.addEventListener("change", () => {
  state.ui.targetLanguage = normalizeTranslationLanguage(translationLanguage.value);
  saveUiSettings();
  renderMessages();
});

vigenereKeyInput.addEventListener("input", () => {
  state.ui.vigenereKey = normalizeVigenereKey(vigenereKeyInput.value);
  saveUiSettings();
  renderMessages();
});

microphoneSelect.addEventListener("change", () => {
  state.ui.microphoneId = microphoneSelect.value;
  saveUiSettings();
});

vigenereToggle.addEventListener("click", () => {
  state.ui.vigenereEnabled = !state.ui.vigenereEnabled;
  updateVigenereToggle();
  saveUiSettings();
  renderMessages();
});

messageInput.addEventListener("input", () => {
  messageInput.style.height = "auto";
  messageInput.style.height = `${Math.min(messageInput.scrollHeight, 130)}px`;
});

messageInput.addEventListener("keydown", (event) => {
  if (event.key !== "Enter" || event.shiftKey || event.isComposing) {
    return;
  }

  event.preventDefault();
  messageForm.requestSubmit();
});

messageForm.addEventListener("submit", async (event) => {
  event.preventDefault();

  const activeConversation = getActiveConversation();
  if (
    !state.activeConversationId ||
    state.chatLocked ||
    !activeConversation ||
    activeConversation.blockedMe
  ) {
    return;
  }

  const plainText = messageInput.value.trim();
  if (!plainText) {
    return;
  }

  const encrypted = state.ui.vigenereEnabled;
  const text = encrypted ? vigenereEncrypt(plainText, state.ui.vigenereKey) : plainText;

  try {
    const body = encrypted ? { text, encryption: { type: "vigenere" } } : { text };
    if (state.replyToMessage) {
      body.replyToId = state.replyToMessage.id;
    }
    const payload = await api(
      `/api/conversations/${state.activeConversationId}/messages`,
      { method: "POST", body }
    );

    upsertConversation(payload.conversation);
    const added = addMessage(payload.message);
    renderConversationList();
    if (!added || !appendMessageToActiveView(payload.message)) {
      renderMessages();
    }
    messageInput.value = "";
    messageInput.style.height = "auto";
    state.replyToMessage = null;
    replyBar.classList.add("hidden");
  } catch (error) {
    authStatus.textContent = error.message;
  }
});

mobileBack.addEventListener("click", () => {
  setDeleteMode(false);
  resetMobileChatState();
});

window.addEventListener("resize", () => {
  if (!window.matchMedia("(max-width: 950px)").matches) {
    chatView.classList.remove("chat-open");
  }
  applySidebarWidth(state.ui.sidebarWidth);
});

document.addEventListener("visibilitychange", () => {
  if (!document.hidden) {
    markConversationAsRead(state.activeConversationId);
  }
});

// ========================
// TYPING INDICATOR
// ========================
function sendTypingEvent() {
  if (!state.socket || !state.activeConversationId) return;
  state.socket.send(JSON.stringify({ type: "typing", conversationId: state.activeConversationId }));
}

function showTypingIndicator(username) {
  typingIndicator.textContent = `${username} печатает...`;
  typingIndicator.classList.remove("hidden");
}

function hideTypingIndicator() {
  typingIndicator.classList.add("hidden");
  typingIndicator.textContent = "";
}

messageInput.addEventListener("input", () => {
  messageInput.style.height = "auto";
  messageInput.style.height = `${Math.min(messageInput.scrollHeight, 130)}px`;
  clearTimeout(state.typingDebounce);
  state.typingDebounce = setTimeout(sendTypingEvent, 300);
});

// ========================
// FORMAT LAST SEEN
// ========================
function formatLastSeen(isoDate) {
  if (!isoDate) return "";
  const diff = Math.floor((Date.now() - new Date(isoDate).getTime()) / 60000);
  if (diff < 1) return "был(а) только что";
  if (diff < 60) return `был(а) ${diff} мин. назад`;
  if (diff < 1440) return `был(а) ${Math.floor(diff / 60)} ч. назад`;
  return `был(а) ${Math.floor(diff / 1440)} дн. назад`;
}

// ========================
// CONTEXT MENU / REPLY / EDIT / FORWARD / REACT
// ========================
function hideContextMenu() {
  messageContextMenu.classList.add("hidden");
  reactionPicker.classList.add("hidden");
  state.contextMenuMessageId = null;
}

document.addEventListener("click", (e) => {
  if (!messageContextMenu.contains(e.target) && !reactionPicker.contains(e.target)) {
    hideContextMenu();
  }
});

document.addEventListener("contextmenu", (e) => {
  const row = e.target.closest(".message-row");
  if (!row || state.deleteMode) return;
  e.preventDefault();
  const msgId = row.dataset.messageId;
  state.contextMenuMessageId = msgId;
  const messages = state.messagesByConversation.get(state.activeConversationId) || [];
  const msg = messages.find((m) => m.id === msgId);
  const isMine = msg && msg.senderId === state.me?.id;
  ctxEdit.style.display = isMine && msg.messageType !== "voice" ? "" : "none";
  messageContextMenu.style.left = `${Math.min(e.clientX, window.innerWidth - 190)}px`;
  messageContextMenu.style.top = `${Math.min(e.clientY, window.innerHeight - 200)}px`;
  messageContextMenu.classList.remove("hidden");
  reactionPicker.classList.add("hidden");
});

ctxReply.addEventListener("click", () => {
  const messages = state.messagesByConversation.get(state.activeConversationId) || [];
  const msg = messages.find((m) => m.id === state.contextMenuMessageId);
  if (!msg) { hideContextMenu(); return; }
  state.replyToMessage = msg;
  replyBarText.textContent = msg.messageType === "voice" ? "🎤 Голосовое сообщение" : (msg.text || "").slice(0, 80);
  replyBar.classList.remove("hidden");
  messageInput.focus();
  hideContextMenu();
});

replyBarCancel.addEventListener("click", () => {
  state.replyToMessage = null;
  replyBar.classList.add("hidden");
});

ctxEdit.addEventListener("click", async () => {
  const messages = state.messagesByConversation.get(state.activeConversationId) || [];
  const msg = messages.find((m) => m.id === state.contextMenuMessageId);
  if (!msg) { hideContextMenu(); return; }
  hideContextMenu();
  const newText = prompt("Редактировать сообщение:", msg.text);
  if (newText === null || newText.trim() === "" || newText.trim() === msg.text) return;
  try {
    await api(`/api/conversations/${state.activeConversationId}/messages/${msg.id}`, { method: "PATCH", body: { text: newText.trim() } });
  } catch (e) { authStatus.textContent = e.message; }
});

ctxForward.addEventListener("click", () => {
  const messages = state.messagesByConversation.get(state.activeConversationId) || [];
  const msg = messages.find((m) => m.id === state.contextMenuMessageId);
  if (!msg) { hideContextMenu(); return; }
  hideContextMenu();
  const convNames = state.conversations.filter((c) => c.id !== state.activeConversationId).map((c, i) => `${i + 1}. ${c.type === "group" ? c.name : (c.participant?.username || "Чат")}`);
  if (convNames.length === 0) { alert("Нет других чатов для пересылки"); return; }
  const choice = prompt("Переслать в чат:\n" + convNames.join("\n") + "\n\nВведите номер:");
  const idx = parseInt(choice, 10) - 1;
  const targets = state.conversations.filter((c) => c.id !== state.activeConversationId);
  if (isNaN(idx) || idx < 0 || idx >= targets.length) return;
  const targetConv = targets[idx];
  const fwdText = msg.messageType === "voice" ? "🎤 Голосовое (пересланное)" : (msg.text || "");
  api(`/api/conversations/${targetConv.id}/messages`, {
    method: "POST",
    body: { text: fwdText, forwardFromId: msg.id },
  }).catch((e) => { authStatus.textContent = e.message; });
});

ctxReact.addEventListener("click", () => {
  const rect = messageContextMenu.getBoundingClientRect();
  reactionPicker.style.left = `${rect.left}px`;
  reactionPicker.style.top = `${rect.top - 48}px`;
  reactionPicker.classList.remove("hidden");
  messageContextMenu.classList.add("hidden");
});

reactionPicker.addEventListener("click", async (e) => {
  const btn = e.target.closest("[data-emoji]");
  if (!btn) return;
  const emoji = btn.dataset.emoji;
  const msgId = state.contextMenuMessageId;
  hideContextMenu();
  if (!msgId || !state.activeConversationId) return;
  try {
    await api(`/api/conversations/${state.activeConversationId}/messages/${msgId}/reactions`, { method: "POST", body: { emoji } });
  } catch (e) { console.error(e); }
});

// ========================
// VOICE MESSAGES
// ========================
voiceRecordBtn.addEventListener("click", async () => {
  if (state.voiceRecording) {
    if (state.voiceRecorder && state.voiceRecorder.state === "recording") {
      state.voiceRecorder.stop();
    }
    return;
  }
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const recorder = new MediaRecorder(stream);
    const chunks = [];
    recorder.ondataavailable = (e) => chunks.push(e.data);
    recorder.onstop = async () => {
      stream.getTracks().forEach((t) => t.stop());
      state.voiceRecording = false;
      voiceRecordBtn.classList.remove("recording");
      const blob = new Blob(chunks, { type: "audio/webm" });
      const reader = new FileReader();
      reader.onload = async () => {
        const base64 = reader.result;
        if (!state.activeConversationId) return;
        try {
          const body = { text: "🎤 Голосовое сообщение", voiceData: base64 };
          if (state.replyToMessage) { body.replyToId = state.replyToMessage.id; state.replyToMessage = null; replyBar.classList.add("hidden"); }
          const payload = await api(`/api/conversations/${state.activeConversationId}/messages`, { method: "POST", body });
          upsertConversation(payload.conversation);
          const added = addMessage(payload.message);
          renderConversationList();
          if (!added || !appendMessageToActiveView(payload.message)) renderMessages();
        } catch (e) { authStatus.textContent = e.message; }
      };
      reader.readAsDataURL(blob);
    };
    recorder.start();
    state.voiceRecorder = recorder;
    state.voiceRecording = true;
    voiceRecordBtn.classList.add("recording");
  } catch { alert("Не удалось получить доступ к микрофону"); }
});

// ========================
// AVATAR
// ========================
avatarUploadBtn.addEventListener("click", () => avatarFileInput.click());
avatarFileInput.addEventListener("change", async () => {
  const file = avatarFileInput.files[0];
  if (!file) return;
  if (file.size > 1.5 * 1024 * 1024) { alert("Файл слишком большой (макс 1.5MB)"); return; }
  const reader = new FileReader();
  reader.onload = async () => {
    try {
      const payload = await api("/api/auth/avatar", { method: "POST", body: { avatar: reader.result } });
      if (state.me) state.me.avatarUrl = payload.avatarUrl;
      updateAvatarPreview();
    } catch (e) { alert(e.message); }
  };
  reader.readAsDataURL(file);
});

function updateAvatarPreview() {
  avatarPreview.innerHTML = "";
  if (state.me?.avatarUrl) {
    const img = document.createElement("img");
    img.src = state.me.avatarUrl;
    img.alt = "Avatar";
    avatarPreview.appendChild(img);
  }
}

// ========================
// GROUP CHATS
// ========================
createGroupBtn.addEventListener("click", () => {
  state.groupSelectedMembers = [];
  groupNameInput.value = "";
  groupMemberSearch.value = "";
  groupMemberResults.innerHTML = "";
  groupCreateStatus.textContent = "";
  renderGroupSelectedMembers();
  createGroupModal.classList.remove("hidden");
});

closeGroupModalBtn.addEventListener("click", () => createGroupModal.classList.add("hidden"));
createGroupModal.addEventListener("click", (e) => { if (e.target === createGroupModal) createGroupModal.classList.add("hidden"); });

groupMemberSearch.addEventListener("input", () => {
  const q = groupMemberSearch.value.trim();
  clearTimeout(state._groupSearchTimeout);
  if (q.length < 2) { groupMemberResults.innerHTML = ""; return; }
  state._groupSearchTimeout = setTimeout(async () => {
    try {
      const payload = await api(`/api/users?search=${encodeURIComponent(q)}`);
      const users = (payload.users || []).filter((u) => u.id !== state.me?.id && !state.groupSelectedMembers.some((m) => m.id === u.id));
      groupMemberResults.innerHTML = "";
      for (const u of users) {
        const li = document.createElement("li");
        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "list-item";
        btn.dataset.initial = getInitial(u.username);
        btn.innerHTML = `<div class="item-row"><p class="item-title">${u.username}</p></div><p class="item-sub">${u.email}</p>`;
        btn.addEventListener("click", () => { state.groupSelectedMembers.push(u); renderGroupSelectedMembers(); groupMemberSearch.value = ""; groupMemberResults.innerHTML = ""; });
        li.appendChild(btn);
        groupMemberResults.appendChild(li);
      }
    } catch { }
  }, 250);
});

function renderGroupSelectedMembers() {
  groupSelectedMembers.innerHTML = "";
  for (const m of state.groupSelectedMembers) {
    const chip = document.createElement("span");
    chip.className = "group-member-chip";
    chip.innerHTML = `${m.username} <button type="button">&times;</button>`;
    chip.querySelector("button").addEventListener("click", () => { state.groupSelectedMembers = state.groupSelectedMembers.filter((x) => x.id !== m.id); renderGroupSelectedMembers(); });
    groupSelectedMembers.appendChild(chip);
  }
}

groupCreateBtn.addEventListener("click", async () => {
  const name = groupNameInput.value.trim();
  if (!name) { groupCreateStatus.textContent = "Введите название"; return; }
  if (state.groupSelectedMembers.length === 0) { groupCreateStatus.textContent = "Добавьте участников"; return; }
  try {
    const payload = await api("/api/conversations/group", { method: "POST", body: { name, memberIds: state.groupSelectedMembers.map((m) => m.id) } });
    upsertConversation(payload.conversation);
    renderConversationList();
    await selectConversation(payload.conversation.id);
    createGroupModal.classList.add("hidden");
  } catch (e) { groupCreateStatus.textContent = e.message; }
});

// ========================
// PUSH NOTIFICATIONS
// ========================
notifToggleBtn.addEventListener("click", async () => {
  if (!("Notification" in window)) { alert("Браузер не поддерживает уведомления"); return; }
  if (Notification.permission === "granted") { notifToggleBtn.textContent = "Включены ✓"; return; }
  const perm = await Notification.requestPermission();
  notifToggleBtn.textContent = perm === "granted" ? "Включены ✓" : "Отклонено";
});

function showPushNotification(title, body) {
  if (!("Notification" in window) || Notification.permission !== "granted") return;
  if (!document.hidden) return;
  try { new Notification(title, { body, icon: "/favicon.ico", tag: "wave-msg" }); } catch { }
}

// ========================
// UPDATED RENDER FOR CONVERSATION LIST (groups + avatars)
// ========================
function getConversationTitle(conversation) {
  if (conversation.type === "group") return conversation.name || "Группа";
  return conversation.participant ? conversation.participant.username : "Диалог";
}

function getConversationAvatar(conversation) {
  if (conversation.type === "group") return null;
  return conversation.participant?.avatarUrl || null;
}

// ========================
// OVERRIDE MESSAGE FORM SUBMIT TO INCLUDE REPLY
// ========================
const _origSubmitHandler = messageForm.onsubmit;

// ========================
// UPDATED INIT
// ========================
async function init() {
  loadUiSettings();
  resetVigenereKey();
  saveUiSettings();
  applySidebarWidth(state.ui.sidebarWidth);
  initializeSidebarResize();
  applyTheme();
  syncUiControls();
  renderTwoFaState();
  updateDeleteUi();
  updateChatLockUi();
  setSettingsPanelOpen(false);
  setAuthTab("login");
  renderSearchResults([]);
  if ("Notification" in window && Notification.permission === "granted") {
    notifToggleBtn.textContent = "Включены ✓";
  }

  try {
    const payload = await api("/api/auth/me");
    await bootstrapSession(payload.user);
  } catch {
    showAuth();
  }
}

init();
