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
const activeCallPanel = document.getElementById("activeCallPanel");
const activeCallName = document.getElementById("activeCallName");
const activeCallStatus = document.getElementById("activeCallStatus");
const activeCallPeerAvatar = document.getElementById("activeCallPeerAvatar");
const activeCallPeerAvatarImg = document.getElementById("activeCallPeerAvatarImg");
const activeCallMeAvatar = document.getElementById("activeCallMeAvatar");
const activeCallMeAvatarImg = document.getElementById("activeCallMeAvatarImg");
const activeCallMuteBtn = document.getElementById("activeCallMuteBtn");
const activeCallSpeakerBtn = document.getElementById("activeCallSpeakerBtn");
const activeCallAcceptBtn = document.getElementById("activeCallAcceptBtn");
const activeCallEndBtn = document.getElementById("activeCallEndBtn");
const activeCallMuteChevron = document.getElementById("activeCallMuteChevron");
const activeCallVideoBtn = document.getElementById("activeCallVideoBtn");
const activeCallVideoChevron = document.getElementById("activeCallVideoChevron");
const activeCallSpeakerChevron = document.getElementById("activeCallSpeakerChevron");
const micSettingsPopover = document.getElementById("micSettingsPopover");
const videoSettingsPopover = document.getElementById("videoSettingsPopover");
const speakerSettingsPopover = document.getElementById("speakerSettingsPopover");
const popoverWebcamBtn = document.getElementById("popoverWebcamBtn");
const popoverScreenShareBtn = document.getElementById("popoverScreenShareBtn");
const remoteVideo = document.getElementById("remoteVideo");
const localVideo = document.getElementById("localVideo");
const noConversationState = document.getElementById("noConversationState");
const messagesEl = document.getElementById("messages");
const messageForm = document.getElementById("messageForm");
const messageInput = document.getElementById("messageInput");
const mobileBack = document.getElementById("mobileBack");
const settingsBtn = document.getElementById("settingsBtn");
const settingsPanel = document.getElementById("settingsPanel");
const closeSettingsBtn = document.getElementById("closeSettingsBtn");
const themeToggleBtn = document.getElementById("themeToggleBtn");
const fullscreenToggleBtn = document.getElementById("fullscreenToggleBtn");
const vigenereKeyInput = document.getElementById("vigenereKeyInput");
const vigenereToggle = document.getElementById("vigenereToggle");
const encInputShell = document.getElementById("encInputShell");
const encVisualLayer = document.getElementById("encVisualLayer");
const encVisibilityBtn = document.getElementById("encVisibilityBtn");
const encVisibilityEye = document.getElementById("encVisibilityEye");
const encVisibilityEyeOff = document.getElementById("encVisibilityEyeOff");
const encSaveBtn = document.getElementById("encSaveBtn");
const encSaveHint = document.getElementById("encSaveHint");
const encStatusValue = document.getElementById("encStatusValue");
const encKeyIcon = document.getElementById("encKeyIcon");
const encStrengthBars = Array.from(document.querySelectorAll(".enc-strength-bar"));
const loginOtpLabel = document.getElementById("loginOtpLabel");
const loginOtpInput = document.getElementById("loginOtpInput");
const loginOtpCancelBtn = document.getElementById("loginOtpCancelBtn");
const loginSubmitBtn = document.getElementById("loginSubmitBtn");
const loginPrimaryFields = document.getElementById("loginPrimaryFields");
const authTabs = document.getElementById("authTabs");
const authSocialSection = document.getElementById("authSocialSection");
const authThemeToggleBtn = document.getElementById("authThemeToggleBtn");
const authTitle = document.getElementById("authTitle");
const authCaption = document.getElementById("authCaption");
const authBrand = document.getElementById("authBrand");
const authLogoWave = document.getElementById("authLogoWave");
const authLogoShield = document.getElementById("authLogoShield");
const loginPasswordToggle = document.getElementById("loginPasswordToggle");
const registerPasswordToggle = document.getElementById("registerPasswordToggle");
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
const speakerSelect = document.getElementById("speakerSelect");
const settingsMicVolume = document.getElementById("settingsMicVolume");
const settingsSpeakerVolume = document.getElementById("settingsSpeakerVolume");
const settingsMicTestBtn = document.getElementById("settingsMicTestBtn");
const settingsMicTestBars = document.getElementById("settingsMicTestBars");
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
const conversationContextMenu = document.getElementById("conversationContextMenu");
const ctxReply = document.getElementById("ctxReply");
const ctxEdit = document.getElementById("ctxEdit");
const ctxForward = document.getElementById("ctxForward");
const ctxReact = document.getElementById("ctxReact");
const convCtxPin = document.getElementById("convCtxPin");
const convCtxClear = document.getElementById("convCtxClear");
const convCtxDelete = document.getElementById("convCtxDelete");
const reactionPicker = document.getElementById("reactionPicker");
const createGroupBtn = document.getElementById("createGroupBtn");
const createGroupModal = document.getElementById("createGroupModal");
const closeGroupModalBtn = document.getElementById("closeGroupModalBtn");
const groupNameInput = document.getElementById("groupNameInput");
const groupDescriptionInput = document.getElementById("groupDescriptionInput");
const groupPrivacyToggle = document.getElementById("groupPrivacyToggle");
const groupTypePrivateBtn = document.getElementById("groupTypePrivateBtn");
const groupTypePublicBtn = document.getElementById("groupTypePublicBtn");
const groupAvatarPickBtn = document.getElementById("groupAvatarPickBtn");
const groupAvatarPreview = document.getElementById("groupAvatarPreview");
const groupAvatarFileInput = document.getElementById("groupAvatarFileInput");
const groupMemberSearch = document.getElementById("groupMemberSearch");
const groupMemberResults = document.getElementById("groupMemberResults");
const groupSelectedMembers = document.getElementById("groupSelectedMembers");
const groupCreateBtn = document.getElementById("groupCreateBtn");
const groupCreateCount = document.getElementById("groupCreateCount");
const groupCreateStatus = document.getElementById("groupCreateStatus");
const avatarPreview = document.getElementById("avatarPreview");
const avatarFileInput = document.getElementById("avatarFileInput");
const avatarUploadBtn = document.getElementById("avatarUploadBtn");
const notifToggleBtn = document.getElementById("notifToggleBtn");
const groupSettingsHeaderBtn = document.getElementById("groupSettingsHeaderBtn");
const groupSettingsModal = document.getElementById("groupSettingsModal");
const closeGroupSettingsBtn = document.getElementById("closeGroupSettingsBtn");
const gsAvatarPreview = document.getElementById("gsAvatarPreview");
const gsAvatarInitial = document.getElementById("gsAvatarInitial");
const gsAvatarFileInput = document.getElementById("gsAvatarFileInput");
const gsAvatarUploadBtn = document.getElementById("gsAvatarUploadBtn");
const gsAvatarRemoveBtn = document.getElementById("gsAvatarRemoveBtn");
const gsGroupName = document.getElementById("gsGroupName");
const gsGroupMeta = document.getElementById("gsGroupMeta");
const gsNameInput = document.getElementById("gsNameInput");
const gsNameSaveBtn = document.getElementById("gsNameSaveBtn");
const gsMemberList = document.getElementById("gsMemberList");
const gsMemberCount = document.getElementById("gsMemberCount");
const gsAddMemberSearch = document.getElementById("gsAddMemberSearch");
const gsAddMemberResults = document.getElementById("gsAddMemberResults");
const gsLeaveBtn = document.getElementById("gsLeaveBtn");
const gsDeleteGroupBtn = document.getElementById("gsDeleteGroupBtn");
const gsStatus = document.getElementById("gsStatus");

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
const CALL_REJECTED_SOUND_SRC = "/call-rejected.mp3";
const CALL_ENDED_SOUND_SRC = "/call-ended.mp3";
const CALL_RECOVERY_STORAGE_KEY = "messenger_call_recovery_v1";
const CALL_RECOVERY_MAX_AGE_MS = 45 * 1000;
const CALL_DISCONNECT_GRACE_MS = 15 * 1000;
const MESSAGE_SOUND_SRC = "/sound-message.mp3";
const OUTGOING_MESSAGE_SOUND_SRC = "/zvukovoe-uvedomlenie-kontakta.mp3";
const SCREENSHOT_MESSAGE_TEXT = "🖼 Скриншот";
const MAX_SCREENSHOT_SIZE_BYTES = 3 * 1024 * 1024;
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
const ENC_SCRAMBLE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*";

function setActionButtonLabel(button, label) {
  const labelNode = button?.querySelector(".chat-action-label");
  if (labelNode) {
    labelNode.textContent = label;
    return;
  }
  button.textContent = label;
}

let encShowKey = false;
let encGlobalScramble = false;
let encGlobalScrambleInterval = null;
let encGlobalScrambleTimeout = null;
let encTypingPulseTimeout = null;
let encHintTimeout = null;
let encVisualRenderToken = 0;
let encVisualIntervals = [];
let encVisualTimeouts = [];
const ENC_DEFAULT_HINT_TEXT = encSaveHint ? encSaveHint.textContent.trim() : "";

const state = {
  me: null,
  conversations: [],
  activeConversationId: null,
  messagesByConversation: new Map(),
  loadedMessagesConversationIds: new Set(),
  pendingOutgoingByClientId: new Map(),
  socket: null,
  pageUnloading: false,
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
    pendingRemoteIceCandidates: [],
    disconnectTimer: null,
    recoveryInFlight: false,
    ringtoneFrame: null,
    incomingActionInFlight: false,
    muted: false,
    outputMuted: false,
    videoEnabled: false,
    screenShareEnabled: false,
    timerInterval: null,
    timerStart: null,
    micGainNode: null,
    micAudioCtx: null,
    micProcessedStream: null,
    micVolume: 100,
    speakerVolume: 100,
  },
  deleteMode: false,
  selectedMessageIds: new Set(),
  replyToMessage: null,
  contextMenuMessageId: null,
  contextMenuConversationId: null,
  typingTimers: new Map(),
  typingDebounce: null,
  voiceRecorder: null,
  voiceRecording: false,
  groupSelectedMembers: [],
  groupCreateIsPrivate: true,
  groupCreateAvatarData: "",
  ui: {
    theme: "light",
    targetLanguage: "off",
    vigenereEnabled: false,
    vigenereKey: DEFAULT_VIGENERE_KEY,
    sidebarWidth: SIDEBAR_DEFAULT_WIDTH,
    microphoneId: "",
    speakerId: "",
    fullscreen: true,
    pinnedConversationIds: [],
  },
};

function normalizeOtpToken(value) {
  return String(value || "")
    .replace(/\D+/g, "")
    .slice(0, 6);
}

function setupPasswordToggle(toggleButton, input) {
  if (!toggleButton || !input) {
    return;
  }

  toggleButton.dataset.visible = "false";
  toggleButton.addEventListener("click", () => {
    const shouldShowPassword = input.type === "password";
    input.type = shouldShowPassword ? "text" : "password";
    toggleButton.dataset.visible = shouldShowPassword ? "true" : "false";
    toggleButton.setAttribute(
      "aria-label",
      shouldShowPassword ? "Скрыть пароль" : "Показать пароль"
    );
  });
}

function resetPasswordToggle(toggleButton, input) {
  if (!toggleButton || !input) {
    return;
  }

  input.type = "password";
  toggleButton.dataset.visible = "false";
  toggleButton.setAttribute("aria-label", "Показать пароль");
}

function renderAuthLayoutState() {
  const isLoginTab = !loginForm.classList.contains("hidden");
  const isTwoFactorStep = Boolean(state.loginChallengeToken);

  if (loginPrimaryFields) {
    loginPrimaryFields.classList.toggle("hidden", isTwoFactorStep);
  }
  loginOtpLabel.classList.toggle("hidden", !isTwoFactorStep);
  loginOtpCancelBtn.classList.toggle("hidden", !isTwoFactorStep);
  if (authTabs) {
    authTabs.classList.toggle("hidden", isTwoFactorStep);
  }
  if (authSocialSection) {
    authSocialSection.classList.toggle("hidden", isTwoFactorStep);
  }
  if (authBrand) {
    authBrand.classList.toggle("hidden", isTwoFactorStep);
  }
  if (authLogoWave) {
    authLogoWave.classList.toggle("hidden", isTwoFactorStep);
  }
  if (authLogoShield) {
    authLogoShield.classList.toggle("hidden", !isTwoFactorStep);
  }

  loginOtpInput.required = isTwoFactorStep;
  loginForm.elements.login.disabled = isTwoFactorStep;
  loginForm.elements.password.disabled = isTwoFactorStep;
  loginSubmitBtn.textContent = isTwoFactorStep ? "Подтвердить код" : "Войти";

  if (authTitle) {
    authTitle.textContent = isTwoFactorStep
      ? "Защита аккаунта"
      : isLoginTab
        ? "С возвращением"
        : "Создать аккаунт";
  }

  if (authCaption) {
    authCaption.textContent = isTwoFactorStep
      ? "Откройте приложение Google Authenticator и введите 6-значный код"
      : isLoginTab
        ? "Настройся на нашу волну общения"
        : "Поймай свою волну - присоединяйся к нам";
  }
}

function resetLoginTwoFactorStep() {
  state.loginChallengeToken = null;
  loginOtpInput.value = "";
  resetPasswordToggle(loginPasswordToggle, loginForm.elements.password);
  renderAuthLayoutState();
}

function startLoginTwoFactorStep(challengeToken) {
  state.loginChallengeToken = String(challengeToken || "");
  renderAuthLayoutState();
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
  renderActiveCallOverlay();
}

function setIncomingCallActionInFlight(inFlight) {
  state.call.incomingActionInFlight = Boolean(inFlight);
  acceptCallBtn.disabled = state.call.incomingActionInFlight;
  rejectCallBtn.disabled = state.call.incomingActionInFlight;
  renderActiveCallOverlay();
}

function clearIncomingCallUi() {
  incomingCallPanel.classList.add("hidden");
  incomingCallText.textContent = "";
  acceptCallBtn.disabled = false;
  rejectCallBtn.disabled = false;
}

function clearPendingIncomingCall() {
  state.call.pendingIncoming = null;
  clearIncomingCallUi();
  updateCallUi();
}

function clearCallRecoveryState() {
  try {
    sessionStorage.removeItem(CALL_RECOVERY_STORAGE_KEY);
  } catch {
  }
}

function saveCallRecoveryState() {
  if (
    !state.me?.id ||
    !state.call.active ||
    !state.call.targetUserId ||
    !state.call.conversationId
  ) {
    clearCallRecoveryState();
    return;
  }

  try {
    sessionStorage.setItem(
      CALL_RECOVERY_STORAGE_KEY,
      JSON.stringify({
        userId: state.me.id,
        targetUserId: state.call.targetUserId,
        conversationId: state.call.conversationId,
        savedAt: Date.now(),
      })
    );
  } catch {
  }
}

function readCallRecoveryState() {
  try {
    const raw = sessionStorage.getItem(CALL_RECOVERY_STORAGE_KEY);
    if (!raw) {
      return null;
    }

    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") {
      clearCallRecoveryState();
      return null;
    }

    const userId = String(parsed.userId || "");
    const targetUserId = String(parsed.targetUserId || "");
    const conversationId = String(parsed.conversationId || "");
    const savedAt = Number(parsed.savedAt || 0);
    const ageMs = Date.now() - savedAt;

    if (
      !userId ||
      !targetUserId ||
      !conversationId ||
      !Number.isFinite(savedAt) ||
      ageMs < 0 ||
      ageMs > CALL_RECOVERY_MAX_AGE_MS
    ) {
      clearCallRecoveryState();
      return null;
    }

    if (state.me?.id && userId !== state.me.id) {
      clearCallRecoveryState();
      return null;
    }

    return {
      userId,
      targetUserId,
      conversationId,
      savedAt,
    };
  } catch {
    clearCallRecoveryState();
    return null;
  }
}

function markPageUnloading() {
  state.pageUnloading = true;
  if (state.call.active) {
    saveCallRecoveryState();
  }
}

function isIncomingCallChatOpen() {
  const pending = state.call.pendingIncoming;
  if (!pending) return false;
  const conv =
    getConversationById(pending.conversationId) ||
    getConversationByParticipantId(pending.fromUserId);
  return conv && conv.id === state.activeConversationId;
}

function showIncomingCallUi(callerName) {
  incomingCallText.textContent = callerName;
  setIncomingCallActionInFlight(false);

  if (isIncomingCallChatOpen()) {
    // Chat is open — use the inline active-call panel, hide floating
    incomingCallPanel.classList.add("hidden");
  } else {
    // Chat is NOT open — show floating notification
    incomingCallPanel.classList.remove("hidden");
  }
  renderActiveCallOverlay();
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

function playCallRejectedSound() {
  try {
    const audio = new Audio(CALL_REJECTED_SOUND_SRC);
    audio.play().catch(() => { });
  } catch {
  }
}

function playCallEndedSound() {
  try {
    const audio = new Audio(CALL_ENDED_SOUND_SRC);
    audio.play().catch(() => { });
  } catch {
  }
}

function getActiveCallConversation() {
  return (
    getConversationById(state.call.conversationId) ||
    getConversationByParticipantId(state.call.targetUserId) ||
    getActiveConversation() ||
    null
  );
}

function setActiveCallAvatar(avatarEl, avatarImgEl, avatarUrl, displayName) {
  if (!avatarEl || !avatarImgEl) {
    return;
  }

  avatarEl.dataset.initial = getInitial(displayName);
  avatarImgEl.alt = displayName;

  if (!avatarUrl) {
    avatarImgEl.removeAttribute("src");
    avatarImgEl.classList.add("hidden");
    return;
  }

  avatarImgEl.onerror = () => {
    avatarImgEl.classList.add("hidden");
  };
  avatarImgEl.src = avatarUrl;
  avatarImgEl.classList.remove("hidden");
}

function applyCallAudioPreferences() {
  if (state.call.localStream) {
    for (const track of state.call.localStream.getAudioTracks()) {
      track.enabled = !state.call.muted;
    }
  }

  remoteAudio.muted = Boolean(state.call.outputMuted);
}

function formatCallDuration(seconds) {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

function startCallTimer() {
  stopCallTimer();
  state.call.timerStart = Date.now();
  state.call.timerInterval = setInterval(() => {
    if (!state.call.active || !state.call.timerStart) return;
    const elapsed = Math.floor((Date.now() - state.call.timerStart) / 1000);
    if (activeCallStatus) {
      activeCallStatus.textContent = formatCallDuration(elapsed);
    }
    callStatus.textContent = `В звонке ${formatCallDuration(elapsed)}`;
  }, 1000);
}

function stopCallTimer() {
  if (state.call.timerInterval) {
    clearInterval(state.call.timerInterval);
    state.call.timerInterval = null;
  }
  state.call.timerStart = null;
}

async function loadPopoverDevices() {
  if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) return;
  try {
    const devices = await navigator.mediaDevices.enumerateDevices();
    const mics = devices.filter(d => d.kind === "audioinput");
    const speakers = devices.filter(d => d.kind === "audiooutput");
    const micListEl = document.getElementById("micDeviceList");
    const speakerListEl = document.getElementById("speakerDeviceList");

    const allMics = [{ deviceId: "", label: "Системный по умолчанию" }, ...mics];
    const allSpks = [{ deviceId: "", label: "Системный по умолчанию" }, ...speakers];

    if (micListEl) {
      populateCpopList(micListEl, allMics, state.ui.microphoneId || "", (deviceId, label) => {
        state.ui.microphoneId = deviceId;
        const nameEl = document.getElementById("micDeviceName");
        if (nameEl) nameEl.textContent = label;
        if (microphoneSelect) microphoneSelect.value = deviceId;
        saveUiSettings();
        closeCpopLists();
      }, "mic");
    }
    if (speakerListEl) {
      populateCpopList(speakerListEl, allSpks, "", (deviceId, label) => {
        const nameEl = document.getElementById("speakerDeviceName");
        if (nameEl) nameEl.textContent = label;
        if (remoteAudio && typeof remoteAudio.setSinkId === "function") {
          remoteAudio.setSinkId(deviceId).catch(() => {});
        }
        closeCpopLists();
      }, "speaker");
    }
  } catch {}
}

function setCallMuted(muted) {
  state.call.muted = Boolean(muted);
  applyCallAudioPreferences();
  renderActiveCallOverlay();
}

function setCallOutputMuted(muted) {
  state.call.outputMuted = Boolean(muted);
  applyCallAudioPreferences();
  renderActiveCallOverlay();
}

function renderActiveCallOverlay() {
  if (!activeCallPanel) {
    return;
  }

  const hasIncomingPending = Boolean(state.call.pendingIncoming) && !state.call.active;
  if (!state.call.active && !hasIncomingPending) {
    activeCallPanel.classList.add("hidden");
    return;
  }

  // Incoming call with chat NOT open — only show floating panel, not inline
  if (hasIncomingPending && !isIncomingCallChatOpen()) {
    activeCallPanel.classList.add("hidden");
    return;
  }

  const pendingCall = state.call.pendingIncoming;
  const callConversation = hasIncomingPending
    ? (
      getConversationById(pendingCall?.conversationId) ||
      getConversationByParticipantId(pendingCall?.fromUserId) ||
      getActiveConversation() ||
      null
    )
    : getActiveCallConversation();
  const peerName = hasIncomingPending
    ? (pendingCall?.callerName || callConversation?.participant?.username || "Собеседник")
    : (callConversation?.participant?.username || "Собеседник");
  const peerAvatarUrl = callConversation?.participant?.avatarUrl || "";
  const meName = state.me?.username || "Вы";
  const meAvatarUrl = state.me?.avatarUrl || "";

  if (activeCallName) {
    activeCallName.textContent = peerName;
  }
  if (activeCallStatus) {
    activeCallStatus.textContent = callStatus.textContent || (hasIncomingPending ? "Входящий звонок..." : "Подключение...");
  }

  setActiveCallAvatar(activeCallPeerAvatar, activeCallPeerAvatarImg, peerAvatarUrl, peerName);
  setActiveCallAvatar(activeCallMeAvatar, activeCallMeAvatarImg, meAvatarUrl, meName);

  // Mute Button
  if (activeCallMuteBtn) {
    activeCallMuteBtn.classList.toggle("hidden", hasIncomingPending);
    activeCallMuteBtn.classList.toggle("active", state.call.muted);
    activeCallMuteBtn.setAttribute("aria-pressed", state.call.muted ? "true" : "false");
    activeCallMuteBtn.title = state.call.muted ? "Включить микрофон" : "Выключить микрофон";
  }
  if (activeCallMuteChevron) {
    activeCallMuteChevron.classList.toggle("hidden", hasIncomingPending);
  }

  // Speaker Button
  if (activeCallSpeakerBtn) {
    activeCallSpeakerBtn.classList.toggle("hidden", hasIncomingPending);
    activeCallSpeakerBtn.classList.toggle("active", state.call.outputMuted);
    activeCallSpeakerBtn.setAttribute("aria-pressed", state.call.outputMuted ? "true" : "false");
    activeCallSpeakerBtn.title = state.call.outputMuted ? "Включить звук" : "Выключить звук";
  }
  if (activeCallSpeakerChevron) {
    activeCallSpeakerChevron.classList.toggle("hidden", hasIncomingPending);
  }

  // Video Button
  if (activeCallVideoBtn) {
    const isVideoOn = state.call.videoEnabled || state.call.screenShareEnabled;
    activeCallVideoBtn.classList.toggle("hidden", hasIncomingPending);
    activeCallVideoBtn.classList.toggle("active", isVideoOn);
    activeCallVideoBtn.setAttribute("aria-pressed", isVideoOn ? "true" : "false");
    activeCallVideoBtn.title = isVideoOn ? "Выключить камеру" : "Включить камеру";
  }
  if (activeCallVideoChevron) {
    activeCallVideoChevron.classList.toggle("hidden", hasIncomingPending);
  }

  // Hide the entire control group container when all children are hidden
  const controlGroupMain = activeCallPanel.querySelector(".control-group-main");
  if (controlGroupMain) {
    controlGroupMain.classList.toggle("hidden", hasIncomingPending);
  }

  if (activeCallAcceptBtn) {
    activeCallAcceptBtn.classList.toggle("hidden", !hasIncomingPending);
    activeCallAcceptBtn.disabled = state.call.incomingActionInFlight;
  }

  if (activeCallEndBtn) {
    activeCallEndBtn.disabled = hasIncomingPending && state.call.incomingActionInFlight;
    activeCallEndBtn.title = hasIncomingPending ? "Отклонить" : "Завершить";
    activeCallEndBtn.classList.toggle("danger-pulse", hasIncomingPending);
  }

  activeCallPanel.classList.remove("hidden");
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
  const hasCallTarget = Boolean(conversation?.participant?.id);
  const disabledByContext =
    !conversation ||
    state.chatLocked ||
    Boolean(conversation?.blockedMe) ||
    !callsSupported ||
    !hasCallTarget;

  callBtn.disabled = (disabledByContext || hasPendingIncoming) && !callActive;
  callBtn.classList.toggle("active", callActive);
  setActionButtonLabel(callBtn, callActive ? "Завершить" : "Позвонить");
  if (callActive) {
    callBtn.title = "";
  } else if (!conversation) {
    callBtn.title = "Сначала выберите диалог.";
  } else if (state.chatLocked) {
    callBtn.title = "Разблокируйте чат, чтобы начать звонок.";
  } else if (conversation?.blockedMe) {
    callBtn.title = "Звонок недоступен: вы заблокированы собеседником.";
  } else if (!hasCallTarget) {
    callBtn.title = "Звонки доступны только в личных чатах.";
  } else if (!callsSupported) {
    callBtn.title = "Звонки недоступны: браузер не поддерживает доступ к микрофону.";
  } else if (hasPendingIncoming) {
    callBtn.title = "Сначала ответьте на входящий звонок.";
  } else {
    callBtn.title = "";
  }

  // Sync floating incoming-call panel vs inline active-call panel
  if (hasPendingIncoming && !callActive) {
    if (isIncomingCallChatOpen()) {
      incomingCallPanel.classList.add("hidden");
    } else {
      const callerName = state.call.pendingIncoming?.callerName || "Собеседник";
      incomingCallText.textContent = callerName;
      incomingCallPanel.classList.remove("hidden");
    }
  } else if (!hasPendingIncoming) {
    incomingCallPanel.classList.add("hidden");
  }

  renderActiveCallOverlay();
}

function cleanupCallState(options = {}) {
  const preserveRecovery = Boolean(options.preserveRecovery);
  stopSpeakingDetection();
  stopCallRingtone();
  stopCallTimer();
  clearPendingIncomingCall();

  if (state.call.disconnectTimer) {
    clearTimeout(state.call.disconnectTimer);
    state.call.disconnectTimer = null;
  }

  if (state.call.peer) {
    state.call.peer.onicecandidate = null;
    state.call.peer.ontrack = null;
    state.call.peer.onconnectionstatechange = null;
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

  if (state.call.micProcessedStream) {
    for (const track of state.call.micProcessedStream.getTracks()) {
      track.stop();
    }
  }

  if (state.call.micAudioCtx) {
    try { state.call.micAudioCtx.close(); } catch {}
  }

  state.call.active = false;
  state.call.targetUserId = "";
  state.call.conversationId = "";
  state.call.peer = null;
  state.call.localStream = null;
  state.call.pendingRemoteIceCandidates = [];
  state.call.disconnectTimer = null;
  state.call.recoveryInFlight = false;
  state.call.muted = false;
  state.call.outputMuted = false;
  state.call.videoEnabled = false;
  state.call.screenShareEnabled = false;
  state.call.timerInterval = null;
  state.call.timerStart = null;
  state.call.micGainNode = null;
  state.call.micAudioCtx = null;
  state.call.micProcessedStream = null;

  remoteAudio.muted = false;
  remoteAudio.srcObject = null;

  if (remoteVideo) {
    remoteVideo.srcObject = null;
    remoteVideo.classList.add("hidden");
  }
  if (localVideo) {
    localVideo.srcObject = null;
    localVideo.classList.add("hidden");
  }
  if (activeCallPeerAvatar) activeCallPeerAvatar.classList.remove("hidden");
  if (activeCallMeAvatar) activeCallMeAvatar.classList.remove("hidden");

  if (!preserveRecovery) {
    clearCallRecoveryState();
  }

  updateCallUi();
}

async function flushPeerIceQueue(peer, queuedCandidates) {
  if (!peer || !Array.isArray(queuedCandidates) || queuedCandidates.length === 0) {
    return;
  }

  const candidates = queuedCandidates.splice(0, queuedCandidates.length);
  for (const candidate of candidates) {
    try {
      await peer.addIceCandidate(new RTCIceCandidate(candidate));
    } catch {
    }
  }
}

function endCall(
  notifyPeer = true,
  statusText = "Звонок завершен.",
  playSound = true,
  options = {}
) {
  const targetUserId = state.call.targetUserId;
  if (notifyPeer && targetUserId) {
    sendSocketPayload({
      type: "call:signal",
      targetUserId,
      signalType: "end",
      conversationId: state.call.conversationId || state.activeConversationId,
    });
  }

  if (playSound) {
    playCallEndedSound();
  }
  cleanupCallState(options);
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

    const rawStream = await navigator.mediaDevices.getUserMedia(getAudioConstraints());
    const localStream = createGainProcessedStream(rawStream);
    const peer = await createCallPeer(
      pendingCall.fromUserId,
      callerConversation?.id || pendingCall.conversationId,
      localStream
    );

    await peer.setRemoteDescription(new RTCSessionDescription(pendingCall.offerSdp));
    await flushPeerIceQueue(peer, pendingCall.pendingIceCandidates || []);
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
    startCallTimer();
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
    throw new Error("WebRTC не поддерживается в этом браузере.");
  }

  const peer = new PeerConnection({
    iceServers: [{ urls: "stun:stun.l.google.com:19302" }],
  });

  if (localStream) {
    for (const track of localStream.getTracks()) {
      peer.addTrack(track, localStream);
    }
  }

  peer.onicecandidate = (event) => {
    if (event.candidate) {
      sendSocketPayload({
        type: "call:signal",
        targetUserId,
        signalType: "ice",
        conversationId,
        data: { candidate: event.candidate.toJSON() },
      });
    }
  };

  peer.ontrack = (event) => {
    const track = event.track;
    if (!track) return;

    if (track.kind === "audio") {
      const audioStream = new MediaStream([track]);
      remoteAudio.srcObject = audioStream;
      remoteAudio.muted = false;
      remoteAudio.volume = state.call.speakerVolume / 100;
      const tryPlay = () => {
        remoteAudio.play().catch(() => {
          // Retry play on user interaction if autoplay blocked
          document.addEventListener("click", () => {
            remoteAudio.play().catch(() => {});
          }, { once: true });
        });
      };
      tryPlay();

      // Re-play if track unmutes after renegotiation
      track.onunmute = tryPlay;

      // Start speaking detection once remote audio is available
      setTimeout(() => startSpeakingDetection(), 500);
    }

    if (track.kind === "video") {
      if (remoteVideo) {
        const videoStream = new MediaStream([track]);
        remoteVideo.srcObject = videoStream;
        remoteVideo.muted = true;
        remoteVideo.classList.remove("hidden");
        remoteVideo.play().catch(() => { });
        if (activeCallPeerAvatar) activeCallPeerAvatar.classList.add("hidden");

        const hideRemoteVideo = () => {
          remoteVideo.srcObject = null;
          remoteVideo.classList.add("hidden");
          if (activeCallPeerAvatar) activeCallPeerAvatar.classList.remove("hidden");
        };

        track.onended = hideRemoteVideo;
        track.onmute = hideRemoteVideo;
        track.onunmute = () => {
          if (remoteVideo && track.readyState === "live") {
            const vs = new MediaStream([track]);
            remoteVideo.srcObject = vs;
            remoteVideo.classList.remove("hidden");
            remoteVideo.play().catch(() => { });
            if (activeCallPeerAvatar) activeCallPeerAvatar.classList.add("hidden");
          }
        };
      }
    }
  };

  // Periodically check if remote video track is still alive
  // (fallback for browsers that don't fire onmute properly)
  const checkRemoteVideo = setInterval(() => {
    if (!state.call.active || !state.call.peer) {
      clearInterval(checkRemoteVideo);
      return;
    }
    const videoReceivers = peer.getReceivers().filter(r => r.track && r.track.kind === "video");
    const hasLiveVideo = videoReceivers.some(r => r.track.readyState === "live" && !r.track.muted);
    if (!hasLiveVideo && remoteVideo && !remoteVideo.classList.contains("hidden")) {
      remoteVideo.srcObject = null;
      remoteVideo.classList.add("hidden");
      if (activeCallPeerAvatar) activeCallPeerAvatar.classList.remove("hidden");
    }
  }, 1000);

  peer.onconnectionstatechange = () => {
    if (!state.call.active || state.call.peer !== peer) {
      clearInterval(checkRemoteVideo);
      return;
    }

    if (peer.connectionState === "connected") {
      if (state.call.disconnectTimer) {
        clearTimeout(state.call.disconnectTimer);
        state.call.disconnectTimer = null;
      }
      return;
    }

    if (["failed", "disconnected", "closed"].includes(peer.connectionState)) {
      if (!state.call.disconnectTimer) {
        setCallStatus("Связь нестабильна, пытаемся восстановить...");
        state.call.disconnectTimer = setTimeout(() => {
          state.call.disconnectTimer = null;
          if (!state.call.active || state.call.peer !== peer) {
            return;
          }
          if (peer.connectionState === "connected") {
            return;
          }
          clearInterval(checkRemoteVideo);
          endCall(true, "Соединение прервано.");
        }, CALL_DISCONNECT_GRACE_MS);
      }
    }
  };

  state.call.active = true;
  state.call.targetUserId = targetUserId;
  state.call.conversationId = conversationId;
  state.call.peer = peer;
  state.call.localStream = localStream;
  state.call.pendingRemoteIceCandidates = [];
  if (state.call.disconnectTimer) {
    clearTimeout(state.call.disconnectTimer);
    state.call.disconnectTimer = null;
  }
  state.call.recoveryInFlight = false;
  applyCallAudioPreferences();
  saveCallRecoveryState();
  loadPopoverDevices();
  updateCallUi();
  return peer;
}

async function startOutgoingCall() {
  if (!canUseAudioCalls()) {
    setCallStatus("Звонки недоступны в этом браузере.", true);
    return;
  }

  const conversation = getActiveConversation();
  if (!conversation) {
    setCallStatus("Сначала выберите диалог.", true);
    return;
  }

  const targetUserId = conversation?.participant?.id;
  if (!targetUserId) {
    setCallStatus("Звонки доступны только в личных чатах.", true);
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
    const rawStream = await navigator.mediaDevices.getUserMedia(getAudioConstraints());
    const localStream = createGainProcessedStream(rawStream);
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

async function restoreCallAfterReloadIfNeeded() {
  if (
    !state.me ||
    state.call.active ||
    state.call.pendingIncoming ||
    state.call.recoveryInFlight
  ) {
    return;
  }

  if (!state.socket || state.socket.readyState !== WebSocket.OPEN) {
    return;
  }

  const recovery = readCallRecoveryState();
  if (!recovery) {
    return;
  }

  const conversation =
    getConversationById(recovery.conversationId) ||
    getConversationByParticipantId(recovery.targetUserId);

  if (
    !conversation ||
    conversation.type !== "direct" ||
    !conversation.participant?.id ||
    conversation.participant.id !== recovery.targetUserId ||
    conversation.blockedMe
  ) {
    clearCallRecoveryState();
    return;
  }

  state.call.recoveryInFlight = true;
  let createdPeer = false;

  try {
    if (state.activeConversationId !== conversation.id) {
      await selectConversation(conversation.id);
    }

    const rawStream = await navigator.mediaDevices.getUserMedia(getAudioConstraints());
    const localStream = createGainProcessedStream(rawStream);
    const peer = await createCallPeer(
      recovery.targetUserId,
      conversation.id,
      localStream
    );
    createdPeer = true;

    const offer = await peer.createOffer({ iceRestart: true });
    await peer.setLocalDescription(offer);

    sendSocketPayload({
      type: "call:signal",
      targetUserId: recovery.targetUserId,
      signalType: "offer",
      conversationId: conversation.id,
      data: { sdp: peer.localDescription, recovery: true },
    });

    stopCallRingtone();
    setCallStatus("Восстанавливаем звонок...");
    saveCallRecoveryState();
  } catch (error) {
    if (createdPeer || state.call.active) {
      cleanupCallState();
    }
    clearCallRecoveryState();
    setCallStatus(error?.message || "Не удалось восстановить звонок.", true);
  } finally {
    state.call.recoveryInFlight = false;
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
      // Handle renegotiation from same peer
      if (fromUserId === state.call.targetUserId && state.call.peer) {
        try {
          await state.call.peer.setRemoteDescription(new RTCSessionDescription(data.sdp));
          await flushPeerIceQueue(state.call.peer, state.call.pendingRemoteIceCandidates);
          const answer = await state.call.peer.createAnswer();
          await state.call.peer.setLocalDescription(answer);

          sendSocketPayload({
            type: "call:signal",
            targetUserId: fromUserId,
            signalType: "answer",
            conversationId,
            data: { sdp: state.call.peer.localDescription },
          });
        } catch (e) {
          console.error("Renegotiation failed:", e);
        }
        return;
      }

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
      pendingIceCandidates: [],
    };

    setCallStatus(`Входящий звонок от ${callerName}.`);
    startCallRingtone();
    showIncomingCallUi(callerName);
    updateCallUi();
    return;
  }

  if (!state.call.active || fromUserId !== state.call.targetUserId || !state.call.peer) {
    if (
      signalType === "ice" &&
      state.call.pendingIncoming &&
      state.call.pendingIncoming.fromUserId === fromUserId &&
      data?.candidate
    ) {
      state.call.pendingIncoming.pendingIceCandidates.push(data.candidate);
      return;
    }

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
    await flushPeerIceQueue(state.call.peer, state.call.pendingRemoteIceCandidates);
    stopCallRingtone();
    setCallStatus("В звонке.");
    startCallTimer();
    return;
  }

  if (signalType === "ice") {
    if (!data.candidate) {
      return;
    }

    if (!state.call.peer.remoteDescription) {
      state.call.pendingRemoteIceCandidates.push(data.candidate);
      return;
    }

    try {
      await state.call.peer.addIceCandidate(new RTCIceCandidate(data.candidate));
    } catch {
      state.call.pendingRemoteIceCandidates.push(data.candidate);
    }
    return;
  }

  if (signalType === "reject") {
    playCallRejectedSound();
    endCall(false, "Собеседник отклонил звонок.", false);
    return;
  }

  if (signalType === "busy") {
    endCall(false, "Собеседник сейчас в другом звонке.", false);
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
  setActionButtonLabel(
    blockUserBtn,
    blockedByMe ? "Разблокировать" : "Заблокировать"
  );
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
  setActionButtonLabel(chatLockBtn, locked ? "Чат защищен" : "Защитить чат");

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
  setActionButtonLabel(deleteModeBtn, "Удаление");
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
  groupSettingsHeaderBtn.classList.add("hidden");
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
    groupSettingsHeaderBtn.classList.remove("hidden");
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
    groupSettingsHeaderBtn.classList.add("hidden");
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

function playOutgoingMessageSound() {
  try {
    const audio = new Audio(OUTGOING_MESSAGE_SOUND_SRC);
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
  state.loadedMessagesConversationIds.delete(conversationId);
  state.deletingMessageIdsByConversation.delete(conversationId);
  state.readRequestsInFlight.delete(conversationId);
  if (isConversationPinned(conversationId)) {
    state.ui.pinnedConversationIds = state.ui.pinnedConversationIds.filter(
      (id) => id !== conversationId
    );
    saveUiSettings();
  }

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
  resetPasswordToggle(loginPasswordToggle, loginForm.elements.password);
  resetPasswordToggle(registerPasswordToggle, registerForm.elements.password);
  tabLogin.classList.toggle("active", isLogin);
  tabRegister.classList.toggle("active", !isLogin);
  loginForm.classList.toggle("hidden", !isLogin);
  registerForm.classList.toggle("hidden", isLogin);
  if (isLogin) {
    resetLoginTwoFactorStep();
  } else {
    state.loginChallengeToken = null;
    loginOtpInput.value = "";
    renderAuthLayoutState();
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
  state.loadedMessagesConversationIds = new Set();
  state.pendingOutgoingByClientId = new Map();
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

function returnToMainMenu() {
  if (!state.activeConversationId) {
    return false;
  }

  state.activeConversationId = null;
  state.deleteMode = false;
  state.selectedMessageIds.clear();
  state.replyToMessage = null;

  hideTypingIndicator();
  hideContextMenu();
  hideConversationContextMenu();
  replyBar.classList.add("hidden");

  setSettingsPanelOpen(false);
  setChatLocked(false);
  setNoConversationHeader();
  renderConversationList();
  renderMessages();
  resetMobileChatState();
  updateDeleteUi();
  updateChatLockUi();

  return true;
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

function normalizePinnedConversationIds(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return [...new Set(value.map((id) => String(id || "").trim()).filter(Boolean))];
}

function isConversationPinned(conversationId) {
  return state.ui.pinnedConversationIds.includes(String(conversationId || ""));
}

function sortConversations() {
  state.conversations.sort((a, b) => {
    const aPinned = isConversationPinned(a.id) ? 1 : 0;
    const bPinned = isConversationPinned(b.id) ? 1 : 0;
    if (aPinned !== bPinned) {
      return bPinned - aPinned;
    }
    return b.updatedAt.localeCompare(a.updatedAt);
  });
}

function prunePinnedConversationIds() {
  const activeIds = new Set(state.conversations.map((conversation) => conversation.id));
  const before = state.ui.pinnedConversationIds.length;
  state.ui.pinnedConversationIds = state.ui.pinnedConversationIds.filter((id) =>
    activeIds.has(id)
  );
  return before !== state.ui.pinnedConversationIds.length;
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

function toggleThemeFromButton(triggerButton) {
  const isDark = state.ui.theme !== "dark";
  state.ui.theme = isDark ? "dark" : "light";

  const rect = triggerButton?.getBoundingClientRect?.();
  const x = rect ? Math.round(rect.left + rect.width / 2) : Math.round(window.innerWidth / 2);
  const y = rect ? Math.round(rect.top + rect.height / 2) : 0;
  document.documentElement.style.setProperty("--vt-x", `${x}px`);
  document.documentElement.style.setProperty("--vt-y", `${y}px`);

  if (!document.startViewTransition) {
    document.documentElement.classList.add("theme-changing");
    applyTheme();
    saveUiSettings();
    setTimeout(() => document.documentElement.classList.remove("theme-changing"), 700);
    return;
  }

  document.startViewTransition(() => {
    applyTheme();
    saveUiSettings();
  });
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
        speakerId: state.ui.speakerId || "",
        fullscreen: !!state.ui.fullscreen,
        pinnedConversationIds: normalizePinnedConversationIds(
          state.ui.pinnedConversationIds
        ),
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
    state.ui.targetLanguage = "off";
    state.ui.vigenereEnabled = Boolean(parsed.vigenereEnabled);
    state.ui.sidebarWidth = normalizeSidebarWidth(parsed.sidebarWidth);
    state.ui.vigenereKey = DEFAULT_VIGENERE_KEY;
    state.ui.microphoneId = String(parsed.microphoneId || "");
    state.ui.speakerId = String(parsed.speakerId || "");
    state.ui.fullscreen = parsed.fullscreen !== false;
    state.ui.pinnedConversationIds = normalizePinnedConversationIds(
      parsed.pinnedConversationIds
    );
  } catch {
  }
}

function applyFullscreen() {
  document.documentElement.classList.toggle("windowed-mode", !state.ui.fullscreen);
  if (fullscreenToggleBtn) {
    fullscreenToggleBtn.textContent = state.ui.fullscreen ? "Оконный режим" : "На весь экран";
  }
}

function ensureMicTestBars() {
  if (!settingsMicTestBars || settingsMicTestBars.childElementCount) return;
  for (let i = 0; i < 48; i += 1) {
    const bar = document.createElement("span");
    bar.className = "voice-test-bar";
    settingsMicTestBars.appendChild(bar);
  }
}

function syncSettingsCallControls() {
  if (settingsMicVolume) settingsMicVolume.value = String(state.call.micVolume);
  if (settingsSpeakerVolume) settingsSpeakerVolume.value = String(state.call.speakerVolume);
  ensureMicTestBars();
}

function syncUiControls() {
  vigenereKeyInput.value = normalizeVigenereKey(state.ui.vigenereKey);
  updateVigenereToggle();
  updateEncryptionUi();
  syncSettingsCallControls();
  loadAudioDevices();
  applyFullscreen();
}

async function loadAudioDevices() {
  if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
    return;
  }
  try {
    const devices = await navigator.mediaDevices.enumerateDevices();
    const mics = devices.filter((d) => d.kind === "audioinput");
    const speakers = devices.filter((d) => d.kind === "audiooutput");
    if (microphoneSelect) {
      microphoneSelect.innerHTML = '<option value="">Микрофон по умолчанию</option>';
      for (const mic of mics) {
        const opt = document.createElement("option");
        opt.value = mic.deviceId;
        opt.textContent = mic.label || `Микрофон ${microphoneSelect.options.length}`;
        microphoneSelect.appendChild(opt);
      }
      microphoneSelect.value = state.ui.microphoneId || "";
    }

    if (speakerSelect) {
      speakerSelect.innerHTML = '<option value="">Динамик по умолчанию</option>';
      for (const speaker of speakers) {
        const opt = document.createElement("option");
        opt.value = speaker.deviceId;
        opt.textContent = speaker.label || `Динамик ${speakerSelect.options.length}`;
        speakerSelect.appendChild(opt);
      }
      speakerSelect.value = state.ui.speakerId || "";
    }

    if (remoteAudio && typeof remoteAudio.setSinkId === "function") {
      remoteAudio.setSinkId(state.ui.speakerId || "").catch(() => {});
    }
  } catch {
  }
}

function getAudioConstraints() {
  const id = state.ui.microphoneId;
  return id ? { audio: { deviceId: { exact: id } } } : { audio: true };
}

function createGainProcessedStream(rawStream) {
  const ctx = new (window.AudioContext || window.webkitAudioContext)();
  const source = ctx.createMediaStreamSource(rawStream);
  const gain = ctx.createGain();
  gain.gain.value = state.call.micVolume / 100;
  source.connect(gain);
  const dest = ctx.createMediaStreamDestination();
  gain.connect(dest);
  state.call.micAudioCtx = ctx;
  state.call.micGainNode = gain;
  state.call.micProcessedStream = dest.stream;
  return dest.stream;
}

// ========================
// SPEAKING DETECTION
// ========================
const speakingState = {
  localAnalyser: null,
  remoteAnalyser: null,
  localCtx: null,
  remoteCtx: null,
  rafId: null,
};

const micTestState = {
  stream: null,
  ctx: null,
  analyser: null,
  rafId: null,
  running: false,
};

const SPEAKING_THRESHOLD = 18;

function startSpeakingDetection() {
  stopSpeakingDetection();

  try {
    // Local mic analyser
    const localStream = state.call.localStream;
    if (localStream && localStream.getAudioTracks().length > 0) {
      const ctx = new (window.AudioContext || window.webkitAudioContext)();
      const source = ctx.createMediaStreamSource(localStream);
      const analyser = ctx.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);
      speakingState.localAnalyser = analyser;
      speakingState.localCtx = ctx;
    }

    // Remote audio analyser
    const remoteStream = remoteAudio.srcObject;
    if (remoteStream && remoteStream.getAudioTracks().length > 0) {
      const ctx = new (window.AudioContext || window.webkitAudioContext)();
      const source = ctx.createMediaStreamSource(remoteStream);
      const analyser = ctx.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);
      speakingState.remoteAnalyser = analyser;
      speakingState.remoteCtx = ctx;
    }
  } catch {}

  const localData = speakingState.localAnalyser ? new Uint8Array(speakingState.localAnalyser.frequencyBinCount) : null;
  const remoteData = speakingState.remoteAnalyser ? new Uint8Array(speakingState.remoteAnalyser.frequencyBinCount) : null;

  function tick() {
    let localSpeaking = false;
    let remoteSpeaking = false;

    if (speakingState.localAnalyser && localData) {
      speakingState.localAnalyser.getByteFrequencyData(localData);
      let sum = 0;
      for (let i = 0; i < localData.length; i++) sum += localData[i];
      localSpeaking = (sum / localData.length) > SPEAKING_THRESHOLD;
    }

    if (speakingState.remoteAnalyser && remoteData) {
      speakingState.remoteAnalyser.getByteFrequencyData(remoteData);
      let sum = 0;
      for (let i = 0; i < remoteData.length; i++) sum += remoteData[i];
      remoteSpeaking = (sum / remoteData.length) > SPEAKING_THRESHOLD;
    }

    if (activeCallMeAvatar) activeCallMeAvatar.classList.toggle("speaking", localSpeaking);
    if (activeCallPeerAvatar) activeCallPeerAvatar.classList.toggle("speaking", remoteSpeaking);

    speakingState.rafId = requestAnimationFrame(tick);
  }

  speakingState.rafId = requestAnimationFrame(tick);
}

function stopSpeakingDetection() {
  if (speakingState.rafId) {
    cancelAnimationFrame(speakingState.rafId);
    speakingState.rafId = null;
  }
  if (speakingState.localCtx) {
    try { speakingState.localCtx.close(); } catch {}
    speakingState.localCtx = null;
  }
  if (speakingState.remoteCtx) {
    try { speakingState.remoteCtx.close(); } catch {}
    speakingState.remoteCtx = null;
  }
  speakingState.localAnalyser = null;
  speakingState.remoteAnalyser = null;
  if (activeCallMeAvatar) activeCallMeAvatar.classList.remove("speaking");
  if (activeCallPeerAvatar) activeCallPeerAvatar.classList.remove("speaking");
}

function updateVigenereToggle() {
  const enabled = state.ui.vigenereEnabled;
  vigenereToggle.classList.toggle("active", enabled);
  vigenereToggle.textContent = enabled ? "Encrypt send: ON" : "Encrypt send: OFF";
}

function randomEncChar() {
  return ENC_SCRAMBLE_CHARS[Math.floor(Math.random() * ENC_SCRAMBLE_CHARS.length)];
}

function clearEncryptionVisualTimers() {
  for (const intervalId of encVisualIntervals) {
    clearInterval(intervalId);
  }
  for (const timeoutId of encVisualTimeouts) {
    clearTimeout(timeoutId);
  }
  encVisualIntervals = [];
  encVisualTimeouts = [];
  if (encGlobalScrambleInterval) {
    clearInterval(encGlobalScrambleInterval);
    encGlobalScrambleInterval = null;
  }
}

function getEncryptionSecurityLevel(rawKey) {
  const length = String(rawKey || "").trim().length;
  if (!length) return 0;
  if (length < 5) return 1;
  if (length < 10) return 2;
  return 3;
}

function getEncryptionStatusText(level) {
  if (level <= 0) return "ОЖИДАНИЕ ВВОДА";
  if (level === 1) return "СЛАБЫЙ КЛЮЧ";
  if (level === 2) return "СРЕДНИЙ КЛЮЧ";
  return "НАДЕЖНЫЙ КЛЮЧ";
}

function setEncryptionSaveHint(text = "", isSuccess = false) {
  if (!encSaveHint) {
    return;
  }
  const nextText = String(text || "").trim();
  if (encHintTimeout) {
    clearTimeout(encHintTimeout);
    encHintTimeout = null;
  }
  encSaveHint.classList.toggle("success", Boolean(isSuccess) && Boolean(nextText));
  encSaveHint.textContent = nextText || ENC_DEFAULT_HINT_TEXT;

  if (nextText) {
    encHintTimeout = setTimeout(() => {
      encSaveHint.classList.remove("success");
      encSaveHint.textContent = ENC_DEFAULT_HINT_TEXT;
      encHintTimeout = null;
    }, 2200);
  }
}

function updateEncryptionVisibilityIcon() {
  if (!encVisibilityBtn || !encVisibilityEye || !encVisibilityEyeOff) {
    return;
  }
  encVisibilityEye.classList.toggle("hidden", encShowKey);
  encVisibilityEyeOff.classList.toggle("hidden", !encShowKey);
  encVisibilityBtn.title = encShowKey ? "Скрыть ключ" : "Показать ключ";
}

function updateEncryptionStrength() {
  const rawValue = String(vigenereKeyInput?.value || "");
  const level = getEncryptionSecurityLevel(rawValue);

  if (encStatusValue) {
    encStatusValue.textContent = getEncryptionStatusText(level);
    encStatusValue.classList.remove("level-1", "level-2", "level-3");
    if (level > 0) {
      encStatusValue.classList.add(`level-${Math.min(level, 3)}`);
    }
  }

  if (encStrengthBars.length) {
    encStrengthBars.forEach((bar, index) => {
      const step = index + 1;
      const active = level >= step;
      bar.classList.toggle("active", active);
      bar.classList.remove("level-1", "level-2", "level-3");
      if (active) {
        bar.classList.add(`level-${step}`);
      }
    });
  }

  if (encSaveBtn) {
    encSaveBtn.disabled = rawValue.trim().length === 0 || encGlobalScramble;
  }
}

function renderEncryptionVisual() {
  if (!encVisualLayer || !vigenereKeyInput) {
    return;
  }

  const rawValue = String(vigenereKeyInput.value || "");
  clearEncryptionVisualTimers();
  encVisualRenderToken += 1;
  const renderToken = encVisualRenderToken;
  encVisualLayer.textContent = "";

  if (!rawValue) {
    const placeholder = document.createElement("span");
    placeholder.className = "enc-placeholder";
    placeholder.textContent = "••••••••••••";
    encVisualLayer.appendChild(placeholder);
    return;
  }

  const spans = Array.from(rawValue).map((char) => {
    const span = document.createElement("span");
    span.className = "enc-char";
    span.dataset.char = char;
    span.textContent = encShowKey ? char : "•";
    if (encShowKey) {
      span.classList.add("glow");
    }
    encVisualLayer.appendChild(span);
    return span;
  });

  if (encGlobalScramble) {
    encGlobalScrambleInterval = setInterval(() => {
      if (renderToken !== encVisualRenderToken) {
        return;
      }
      for (const span of spans) {
        span.textContent = randomEncChar();
        span.classList.add("glow");
      }
    }, 30);
    return;
  }

  if (encShowKey) {
    return;
  }

  spans.forEach((span, index) => {
    const scrambleInterval = setInterval(() => {
      if (renderToken !== encVisualRenderToken) {
        return;
      }
      span.textContent = randomEncChar();
      span.classList.add("glow");
    }, 30);
    encVisualIntervals.push(scrambleInterval);

    const revealTimeout = setTimeout(() => {
      if (renderToken !== encVisualRenderToken) {
        return;
      }
      clearInterval(scrambleInterval);
      span.textContent = span.dataset.char || "";
      span.classList.add("glow");
    }, 150 + index * 18);
    encVisualTimeouts.push(revealTimeout);

    const hideTimeout = setTimeout(() => {
      if (renderToken !== encVisualRenderToken) {
        return;
      }
      span.textContent = "•";
      span.classList.remove("glow");
    }, 950 + index * 18);
    encVisualTimeouts.push(hideTimeout);
  });
}

function updateEncryptionUi() {
  updateEncryptionVisibilityIcon();
  updateEncryptionStrength();
  renderEncryptionVisual();
}

function toggleEncryptionVisibility() {
  if (!vigenereKeyInput || encGlobalScramble) {
    return;
  }

  const hasValue = String(vigenereKeyInput.value || "").trim().length > 0;
  if (!hasValue) {
    encShowKey = !encShowKey;
    updateEncryptionUi();
    return;
  }

  encGlobalScramble = true;
  if (encVisibilityBtn) {
    encVisibilityBtn.classList.add("scrambling");
  }
  updateEncryptionStrength();
  renderEncryptionVisual();

  if (encGlobalScrambleTimeout) {
    clearTimeout(encGlobalScrambleTimeout);
  }
  encGlobalScrambleTimeout = setTimeout(() => {
    encGlobalScramble = false;
    encShowKey = !encShowKey;
    if (encVisibilityBtn) {
      encVisibilityBtn.classList.remove("scrambling");
    }
    updateEncryptionUi();
    encGlobalScrambleTimeout = null;
  }, 400);
}

function pulseEncryptionKeyIcon() {
  if (!encKeyIcon) {
    return;
  }
  encKeyIcon.classList.add("typing-pulse");
  if (encTypingPulseTimeout) {
    clearTimeout(encTypingPulseTimeout);
  }
  encTypingPulseTimeout = setTimeout(() => {
    encKeyIcon.classList.remove("typing-pulse");
    encTypingPulseTimeout = null;
  }, 150);
}

function setSettingsPanelOpen(isOpen) {
  const shouldOpen = Boolean(isOpen) && !state.chatLocked;
  settingsPanel.classList.toggle("hidden", !shouldOpen);
  if (shouldOpen) {
    syncSettingsCallControls();
    loadAudioDevices();
    updateEncryptionUi();
  } else {
    clearEncryptionVisualTimers();
    if (encGlobalScrambleTimeout) {
      clearTimeout(encGlobalScrambleTimeout);
      encGlobalScrambleTimeout = null;
    }
    encGlobalScramble = false;
    if (encVisibilityBtn) {
      encVisibilityBtn.classList.remove("scrambling");
    }
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

function getMessageTypePreview(message, fallback = "Сообщение") {
  if (!message) {
    return fallback;
  }
  if (message.imageData) {
    return SCREENSHOT_MESSAGE_TEXT;
  }
  if (message.messageType === "voice") {
    return "🎤 Голосовое";
  }
  if (message.messageType === "image") {
    return SCREENSHOT_MESSAGE_TEXT;
  }

  const text = String(message.text || "").trim();
  return text || fallback;
}

function readFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () => reject(new Error("Не удалось прочитать изображение"));
    reader.readAsDataURL(file);
  });
}

function extractScreenshotFileFromClipboard(clipboardData) {
  const items = Array.from(clipboardData?.items || []);
  if (items.length === 0) {
    return null;
  }

  const hasRichClipboardPayload = items.some(
    (item) =>
      item.kind === "string" &&
      item.type !== "text/plain"
  );
  if (hasRichClipboardPayload) {
    return null;
  }

  const imageItems = items.filter(
    (item) => item.kind === "file" && item.type === "image/png"
  );
  const hasNonPngFiles = items.some(
    (item) => item.kind === "file" && item.type !== "image/png"
  );
  if (hasNonPngFiles || imageItems.length !== 1) {
    return null;
  }

  return imageItems[0].getAsFile();
}

function upsertConversation(conversation) {
  const index = state.conversations.findIndex((item) => item.id === conversation.id);
  if (index >= 0) {
    state.conversations[index] = conversation;
  } else {
    state.conversations.push(conversation);
  }

  sortConversations();
}

function getConversationById(conversationId) {
  return state.conversations.find((conversation) => conversation.id === conversationId);
}

function toggleConversationPinned(conversationId) {
  const id = String(conversationId || "");
  if (!id) {
    return;
  }

  if (isConversationPinned(id)) {
    state.ui.pinnedConversationIds = state.ui.pinnedConversationIds.filter(
      (item) => item !== id
    );
  } else {
    state.ui.pinnedConversationIds = [id, ...state.ui.pinnedConversationIds];
  }

  state.ui.pinnedConversationIds = normalizePinnedConversationIds(
    state.ui.pinnedConversationIds
  );
  sortConversations();
  saveUiSettings();
  renderConversationList();
}

async function clearConversationHistoryById(conversationId) {
  const id = String(conversationId || "");
  if (!id) {
    return;
  }

  const payload = await api(`/api/conversations/${id}/messages/all`, {
    method: "DELETE",
  });

  if (payload.conversation) {
    upsertConversation(payload.conversation);
  } else {
    const conversation = getConversationById(id);
    if (conversation) {
      conversation.lastMessage = null;
      conversation.updatedAt = new Date().toISOString();
      upsertConversation(conversation);
    }
  }

  const deletedIds = payload.deletedMessageIds || [];
  if (deletedIds.length > 0) {
    removeMessagesFromState(id, deletedIds);
  } else if (state.messagesByConversation.has(id)) {
    state.messagesByConversation.set(id, []);
  }

  if (state.activeConversationId === id) {
    renderMessages();
    renderActiveConversationHeader();
  }
  renderConversationList();
  updateChatLockUi();
}

async function deleteConversationById(conversationId) {
  const id = String(conversationId || "");
  if (!id) {
    return;
  }

  const payload = await api(`/api/conversations/${id}`, {
    method: "DELETE",
  });
  await removeConversationFromState(payload.deletedConversationId || id);
}

function renderConversationList() {
  conversationList.innerHTML = "";
  sortConversations();

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
    const pinned = isConversationPinned(conversation.id);
    const title = isGroup ? (conversation.name || "Группа") : (conversation.participant ? conversation.participant.username : "Диалог");
    const avatarUrl = isGroup
      ? conversation.avatarUrl || null
      : conversation.participant?.avatarUrl || null;
    const isOnline = isGroup ? false : Boolean(conversation.participant?.online);

    let preview = conversation.lastMessage
      ? getMessageTypePreview(conversation.lastMessage, "Сообщение")
      : "Сообщений еще нет";
    if (conversation.lastMessage?.senderId === state.me?.id) {
      preview = `${conversation.lastMessage.readAt ? "✓✓" : "✓"} ${preview}`;
    }
    button.dataset.initial = getInitial(title);
    if (pinned) {
      button.classList.add("pinned");
    }

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

    if (pinned) {
      const pinBadge = document.createElement("span");
      pinBadge.className = "pin-badge";
      pinBadge.textContent = "📌";
      pinBadge.title = "Закрепленный чат";
      titleWrap.appendChild(pinBadge);
    }

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
    button.addEventListener("contextmenu", (event) => {
      if (state.deleteMode) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      openConversationContextMenu(conversation.id, event.clientX, event.clientY);
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

function getLocalPendingMessageId(conversationId, clientMessageId) {
  if (!conversationId || !clientMessageId) {
    return "";
  }

  const messages = state.messagesByConversation.get(conversationId) || [];
  const pending = messages.find(
    (message) =>
      message.pending &&
      String(message.clientMessageId || "") === String(clientMessageId)
  );
  return pending ? pending.id : "";
}

function replaceMessageInState(conversationId, fromMessageId, nextMessage) {
  const current = state.messagesByConversation.get(conversationId) || [];
  const filtered = current.filter(
    (message) => message.id !== fromMessageId && message.id !== nextMessage.id
  );
  filtered.push({ ...nextMessage, pending: false });
  filtered.sort((a, b) => a.createdAt.localeCompare(b.createdAt));
  state.messagesByConversation.set(conversationId, filtered);
}

function mergeServerMessageWithLocalMedia(serverMessage, localMessage) {
  if (!localMessage) {
    return serverMessage;
  }

  const merged = { ...serverMessage };
  if (!merged.imageData && localMessage.imageData) {
    merged.imageData = localMessage.imageData;
  }
  if (!merged.voiceData && localMessage.voiceData) {
    merged.voiceData = localMessage.voiceData;
  }
  if (merged.messageType === "text") {
    if (merged.imageData) {
      merged.messageType = "image";
    } else if (merged.voiceData) {
      merged.messageType = "voice";
    }
  }

  return merged;
}

function getMessageMetaText(message, mine) {
  const timeText = formatTime(message.createdAt);
  if (mine) {
    if (message.pending) {
      return `${timeText} \u231b`;
    }
    return `${timeText} ${message.readAt ? "\u2713\u2713" : "\u2713"}`.trim();
  }

  return timeText;
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
    replyBadge.textContent = `↩ ${original ? getMessageTypePreview(original, "Сообщение").slice(0, 50) : "Сообщение"}`;
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

  if (message.imageData) {
    const imageLink = document.createElement("a");
    imageLink.className = "bubble-image-link";
    imageLink.href = message.imageData;
    imageLink.target = "_blank";
    imageLink.rel = "noopener noreferrer";
    imageLink.title = "Открыть скриншот в полном размере";

    const image = document.createElement("img");
    image.className = "bubble-image";
    image.src = message.imageData;
    image.alt = SCREENSHOT_MESSAGE_TEXT;
    image.loading = "lazy";
    image.decoding = "async";

    imageLink.appendChild(image);
    bubble.appendChild(imageLink);
  } else if (message.messageType === "voice" && message.voiceData) {
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
  meta.textContent = getMessageMetaText(message, mine);
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

function scrollToBottom(smooth = false) {
  if (state.deleteMode) {
    return;
  }

  const scroll = () => {
    messagesEl.scrollTop = messagesEl.scrollHeight;
  };

  if (smooth) {
    try {
      messagesEl.scrollTo({ top: messagesEl.scrollHeight, behavior: "smooth" });
    } catch {
      scroll();
    }
  } else {
    scroll();
    requestAnimationFrame(scroll);
    setTimeout(scroll, 100);
  }
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

  scrollToBottom(true);

  return true;
}

function replaceMessageRowInActiveView(fromMessageId, nextMessage) {
  if (!state.activeConversationId || nextMessage.conversationId !== state.activeConversationId) {
    return false;
  }

  const existingRow = messagesEl.querySelector(`[data-message-id="${nextMessage.id}"]`);
  if (existingRow) {
    const oldRow = messagesEl.querySelector(`[data-message-id="${fromMessageId}"]`);
    if (oldRow && oldRow !== existingRow) {
      oldRow.remove();
    }
    return true;
  }

  const oldRow = messagesEl.querySelector(`[data-message-id="${fromMessageId}"]`);
  if (!oldRow) {
    return appendMessageToActiveView(nextMessage);
  }

  const deletingIds =
    state.deletingMessageIdsByConversation.get(state.activeConversationId) || new Set();
  oldRow.replaceWith(createMessageRow(nextMessage, deletingIds));
  return true;
}

function reconcilePendingOutgoingMessage(message) {
  const clientMessageId = String(message?.clientMessageId || "");
  const conversationId = String(message?.conversationId || "");
  if (!clientMessageId || !conversationId) {
    return false;
  }

  let localMessageId = state.pendingOutgoingByClientId.get(clientMessageId);
  if (!localMessageId) {
    localMessageId = getLocalPendingMessageId(conversationId, clientMessageId);
  }
  if (!localMessageId) {
    return false;
  }

  const localMessage = (state.messagesByConversation.get(conversationId) || []).find(
    (item) => item.id === localMessageId
  );
  const mergedMessage = mergeServerMessageWithLocalMedia(message, localMessage);

  state.pendingOutgoingByClientId.delete(clientMessageId);
  replaceMessageInState(conversationId, localMessageId, mergedMessage);
  replaceMessageRowInActiveView(localMessageId, { ...mergedMessage, pending: false });
  return true;
}

function createOptimisticMessage(conversationId, body, clientMessageId) {
  return {
    id: `local-${clientMessageId}`,
    clientMessageId,
    pending: true,
    conversationId,
    senderId: state.me.id,
    text: String(body.text || ""),
    messageType: body.imageData ? "image" : body.voiceData ? "voice" : "text",
    encryption: body.encryption || null,
    replyToId: body.replyToId || null,
    forwardFromId: body.forwardFromId || null,
    imageData: body.imageData || null,
    voiceData: body.voiceData || null,
    reactions: [],
    editedAt: null,
    readAt: null,
    createdAt: new Date().toISOString(),
    sender: state.me ? { ...state.me } : null,
  };
}

async function sendMessageWithOptimistic(body) {
  if (!state.activeConversationId || !state.me) {
    return null;
  }

  const conversationId = state.activeConversationId;
  const clientMessageId = crypto.randomUUID();
  const optimisticMessage = createOptimisticMessage(conversationId, body, clientMessageId);

  state.pendingOutgoingByClientId.set(clientMessageId, optimisticMessage.id);
  addMessage(optimisticMessage);
  appendMessageToActiveView(optimisticMessage);

  try {
    const payload = await api(`/api/conversations/${conversationId}/messages`, {
      method: "POST",
      body: { ...body, clientMessageId },
    });

    upsertConversation(payload.conversation);
    const merged = reconcilePendingOutgoingMessage(payload.message);
    if (!merged) {
      addMessage(payload.message);
      appendMessageToActiveView(payload.message);
    }

    renderConversationList();
    return payload;
  } catch (error) {
    state.pendingOutgoingByClientId.delete(clientMessageId);
    removeMessagesFromState(conversationId, [optimisticMessage.id]);

    const optimisticRow = messagesEl.querySelector(`[data-message-id="${optimisticMessage.id}"]`);
    if (optimisticRow) {
      optimisticRow.remove();
    }
    if (
      state.activeConversationId === conversationId &&
      messagesEl.children.length === 0
    ) {
      renderMessages();
    }

    renderConversationList();
    throw error;
  }
}

function updateMessageMetaInActiveView(messageId) {
  if (!state.activeConversationId) {
    return false;
  }

  const row = messagesEl.querySelector(`[data-message-id="${messageId}"]`);
  if (!row) {
    return false;
  }

  const messages = state.messagesByConversation.get(state.activeConversationId) || [];
  const message = messages.find((item) => item.id === messageId);
  if (!message) {
    return false;
  }

  const meta = row.querySelector(".bubble-meta");
  if (!meta) {
    return false;
  }

  const mine = message.senderId === state.me?.id;
  const editedNode = meta.querySelector(".bubble-edited");
  meta.textContent = getMessageMetaText(message, mine);
  if (editedNode) {
    meta.appendChild(editedNode);
  }

  return true;
}

function renderMessages() {
  messagesEl.innerHTML = "";

  const hasActiveConversation = Boolean(state.activeConversationId);
  if (noConversationState) {
    noConversationState.classList.toggle("hidden", hasActiveConversation);
    noConversationState.setAttribute("aria-hidden", hasActiveConversation ? "true" : "false");
  }
  messagesEl.classList.toggle("hidden", !hasActiveConversation);
  messageForm.classList.toggle("hidden", !hasActiveConversation);

  if (!hasActiveConversation) {
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

  scrollToBottom(false);
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
  if (state.loadedMessagesConversationIds.has(conversationId)) {
    return;
  }

  const payload = await api(`/api/conversations/${conversationId}/messages?limit=200`);
  state.messagesByConversation.set(conversationId, payload.messages || []);
  state.loadedMessagesConversationIds.add(conversationId);
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
  sortConversations();
  if (prunePinnedConversationIds()) {
    saveUiSettings();
  }
  state.activeConversationId = null;
  state.deletingMessageIdsByConversation = new Map();
  state.readRequestsInFlight = new Set();
  state.loadedMessagesConversationIds = new Set();
  state.pendingOutgoingByClientId = new Map();
  state.deleteMode = false;
  state.selectedMessageIds.clear();
  updateDeleteUi();

  renderConversationList();
  // Default: no chat open
  setChatLocked(false);
  state.activeConversationId = null;
  setNoConversationHeader();
  renderMessages();
  resetMobileChatState();
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
  state.pageUnloading = false;
  const protocol = window.location.protocol === "https:" ? "wss" : "ws";
  const socket = new WebSocket(`${protocol}://${window.location.host}/ws`);
  state.socket = socket;

  socket.addEventListener("open", () => {
    if (!state.me) {
      return;
    }
    restoreCallAfterReloadIfNeeded().catch(() => {
    });
  });

  socket.addEventListener("message", async (event) => {
    let payload;
    try {
      payload = JSON.parse(event.data);
    } catch {
      return;
    }

    if (payload.type === "message:new" && payload.message) {
      const mergedPending = reconcilePendingOutgoingMessage(payload.message);
      const added = mergedPending ? false : addMessage(payload.message);
      if (payload.message.senderId !== state.me?.id) {
        playIncomingMessageSound();
        const senderName = payload.message.sender?.username || "Новое сообщение";
        const previewText = getMessageTypePreview(payload.message, "Новое сообщение").slice(0, 60);
        showPushNotification(senderName, previewText);
      }
      if (payload.message.conversationId === state.activeConversationId) {
        if (added) {
          appendMessageToActiveView(payload.message);
        }
        if (payload.message.senderId !== state.me?.id) {
          markConversationAsRead(payload.message.conversationId);
        }
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
          const activeMessages =
            state.messagesByConversation.get(state.activeConversationId) || [];
          const hasAnyUpdatedInState = (payload.messageIds || []).some((messageId) =>
            activeMessages.some((message) => message.id === messageId)
          );

          let updatedRows = false;
          if (hasAnyUpdatedInState) {
            for (const messageId of payload.messageIds || []) {
              updatedRows = updateMessageMetaInActiveView(messageId) || updatedRows;
            }
          }
          if (hasAnyUpdatedInState && !updatedRows) {
            renderMessages();
          }
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
    if (state.pageUnloading) {
      return;
    }
    if (state.call.active) {
      setCallStatus("Сервер недоступен. Пытаемся переподключиться...");
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

setupPasswordToggle(loginPasswordToggle, loginForm.elements.password);
setupPasswordToggle(registerPasswordToggle, registerForm.elements.password);

loginOtpInput.addEventListener("input", () => {
  loginOtpInput.value = normalizeOtpToken(loginOtpInput.value);
});

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
        throw new Error("Введите 6-значный код из Google Authenticator");
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
      authStatus.textContent = "Введите 6-значный код из Google Authenticator";
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

// Settings tab switching
const settingsTabTitles = {
  appearance: "Внешний вид аккаунта",
  theme: "Тема и режим отображения",
  encryption: "Слова шифрования",
  sounds: "Звук и уведомления",
  security: "Безопасность",
  account: "Управление аккаунтом",
};
const settingsTabTitle = document.getElementById("settingsTabTitle");

document.querySelectorAll(".settings-tab-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    const tab = btn.dataset.tab;
    document.querySelectorAll(".settings-tab-btn").forEach((b) => {
      b.classList.toggle("active", b === btn);
      b.setAttribute("aria-selected", b === btn ? "true" : "false");
    });
    document.querySelectorAll(".settings-tab-panel").forEach((panel) => {
      panel.classList.toggle("active", panel.dataset.panel === tab);
    });
    if (settingsTabTitle) {
      settingsTabTitle.textContent = settingsTabTitles[tab] || "";
    }
  });
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
    await deleteConversationById(deletingId);
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

if (activeCallMuteBtn) {
  activeCallMuteBtn.addEventListener("click", () => {
    setCallMuted(!state.call.muted);
  });
}

if (activeCallSpeakerBtn) {
  activeCallSpeakerBtn.addEventListener("click", () => {
    setCallOutputMuted(!state.call.outputMuted);
  });
}

if (activeCallAcceptBtn) {
  activeCallAcceptBtn.addEventListener("click", async () => {
    if (!state.call.pendingIncoming || state.call.active) {
      return;
    }
    await acceptPendingIncomingCall();
  });
}

if (activeCallEndBtn) {
  activeCallEndBtn.addEventListener("click", () => {
    if (state.call.pendingIncoming && !state.call.active) {
      rejectPendingIncomingCall("Входящий звонок отклонен.");
      return;
    }
    if (!state.call.active) {
      return;
    }
    endCall(true, "Звонок завершен.");
  });
}

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

themeToggleBtn.addEventListener("click", () => {
  toggleThemeFromButton(themeToggleBtn);
});

if (authThemeToggleBtn) {
  authThemeToggleBtn.addEventListener("click", () => {
    toggleThemeFromButton(authThemeToggleBtn);
  });
}

fullscreenToggleBtn.addEventListener("click", () => {
  state.ui.fullscreen = !state.ui.fullscreen;
  applyFullscreen();
  saveUiSettings();
});

if (vigenereKeyInput) {
  vigenereKeyInput.addEventListener("input", () => {
    state.ui.vigenereKey = normalizeVigenereKey(vigenereKeyInput.value);
    saveUiSettings();
    renderMessages();
    pulseEncryptionKeyIcon();
    setEncryptionSaveHint("");
    updateEncryptionUi();
  });

  vigenereKeyInput.addEventListener("focus", () => {
    if (encInputShell) {
      encInputShell.classList.add("is-focused");
    }
  });

  vigenereKeyInput.addEventListener("blur", () => {
    if (encInputShell) {
      encInputShell.classList.remove("is-focused");
    }
  });
}

if (encVisibilityBtn) {
  encVisibilityBtn.addEventListener("click", (event) => {
    event.preventDefault();
    toggleEncryptionVisibility();
  });
}

if (encSaveBtn) {
  encSaveBtn.addEventListener("click", () => {
    if (encGlobalScramble || !vigenereKeyInput) {
      return;
    }
    const raw = String(vigenereKeyInput.value || "").trim();
    state.ui.vigenereKey = normalizeVigenereKey(vigenereKeyInput.value);
    saveUiSettings();
    renderMessages();
    setEncryptionSaveHint(
      raw ? "Ключ шифрования сохранен." : "Пустой ключ заменен на WAVE.",
      true
    );
    updateEncryptionUi();
  });
}

if (microphoneSelect) {
  microphoneSelect.addEventListener("change", () => {
    state.ui.microphoneId = microphoneSelect.value;
    saveUiSettings();
  });
}

if (speakerSelect) {
  speakerSelect.addEventListener("change", () => {
    state.ui.speakerId = speakerSelect.value;
    saveUiSettings();
    if (remoteAudio && typeof remoteAudio.setSinkId === "function") {
      remoteAudio.setSinkId(state.ui.speakerId || "").catch(() => {});
    }
  });
}

if (settingsMicVolume) {
  settingsMicVolume.addEventListener("input", () => {
    const val = parseInt(settingsMicVolume.value, 10);
    state.call.micVolume = val;
    if (val > 0) micPrevVol = val;
    if (state.call.micGainNode) state.call.micGainNode.gain.value = val / 100;
    if (popoverMicVolume) popoverMicVolume.value = String(val);
    syncCpopVolume("popoverMicVolume", "micVolPct", "micMuteBtn", val);
  });
}

if (settingsSpeakerVolume) {
  settingsSpeakerVolume.addEventListener("input", () => {
    const val = parseInt(settingsSpeakerVolume.value, 10);
    state.call.speakerVolume = val;
    if (val > 0) speakerPrevVol = val;
    if (remoteAudio) remoteAudio.volume = val / 100;
    if (popoverSpeakerVolume) popoverSpeakerVolume.value = String(val);
    syncCpopVolume("popoverSpeakerVolume", "speakerVolPct", "speakerMuteBtn", val);
  });
}

if (settingsMicTestBtn) {
  settingsMicTestBtn.addEventListener("click", async () => {
    if (micTestState.running) {
      stopMicTest();
      return;
    }
    await startMicTest();
  });
}

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

let screenshotPasteInFlight = false;
let messageSubmitInFlight = false;
messageInput.addEventListener("paste", async (event) => {
  event.preventDefault();

  if (screenshotPasteInFlight) {
    return;
  }

  const activeConversation = getActiveConversation();
  if (
    !state.activeConversationId ||
    state.chatLocked ||
    !activeConversation ||
    activeConversation.blockedMe
  ) {
    return;
  }

  const screenshotFile = extractScreenshotFileFromClipboard(event.clipboardData);
  if (!screenshotFile) {
    authStatus.textContent = "Через Ctrl+V можно отправлять только скриншот.";
    return;
  }

  if (screenshotFile.size > MAX_SCREENSHOT_SIZE_BYTES) {
    authStatus.textContent = "Скриншот слишком большой (макс 3MB).";
    return;
  }

  screenshotPasteInFlight = true;
  try {
    const imageData = await readFileAsDataUrl(screenshotFile);
    const body = { text: SCREENSHOT_MESSAGE_TEXT, imageData };
    if (state.replyToMessage) {
      body.replyToId = state.replyToMessage.id;
      state.replyToMessage = null;
      replyBar.classList.add("hidden");
    }
    await sendMessageWithOptimistic(body);
    playOutgoingMessageSound();
    authStatus.textContent = "";
  } catch (error) {
    authStatus.textContent = error.message;
  } finally {
    screenshotPasteInFlight = false;
  }
});

messageForm.addEventListener("submit", async (event) => {
  event.preventDefault();

  if (messageSubmitInFlight) {
    return;
  }

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
  const replyToMessageBeforeSend = state.replyToMessage;

  try {
    messageSubmitInFlight = true;
    const body = encrypted ? { text, encryption: { type: "vigenere" } } : { text };
    if (replyToMessageBeforeSend) {
      body.replyToId = replyToMessageBeforeSend.id;
    }
    messageInput.value = "";
    messageInput.style.height = "auto";
    state.replyToMessage = null;
    replyBar.classList.add("hidden");
    await sendMessageWithOptimistic(body);
    playOutgoingMessageSound();
    authStatus.textContent = "";
  } catch (error) {
    authStatus.textContent = error.message;
    messageInput.value = plainText;
    messageInput.style.height = "auto";
    messageInput.style.height = `${Math.min(messageInput.scrollHeight, 130)}px`;
    if (replyToMessageBeforeSend) {
      state.replyToMessage = replyToMessageBeforeSend;
      replyBarText.textContent = getMessageTypePreview(replyToMessageBeforeSend, "Сообщение").slice(0, 80);
      replyBar.classList.remove("hidden");
    }
  } finally {
    messageSubmitInFlight = false;
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

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape" || event.defaultPrevented) {
    return;
  }
  if (!state.activeConversationId || chatView.classList.contains("hidden")) {
    return;
  }
  if (
    (createGroupModal && !createGroupModal.classList.contains("hidden")) ||
    (groupSettingsModal && !groupSettingsModal.classList.contains("hidden"))
  ) {
    return;
  }
  if (state.call.active || state.call.pendingIncoming) {
    return;
  }

  event.preventDefault();
  returnToMainMenu();
});

window.addEventListener("beforeunload", markPageUnloading);
window.addEventListener("pagehide", markPageUnloading);

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

function hideConversationContextMenu() {
  conversationContextMenu.classList.add("hidden");
  state.contextMenuConversationId = null;
}

function openConversationContextMenu(conversationId, x, y) {
  const id = String(conversationId || "");
  const conversation = getConversationById(id);
  if (!id || !conversation) {
    return;
  }

  state.contextMenuConversationId = id;
  convCtxPin.textContent = isConversationPinned(id) ? "📌 Открепить" : "📌 Закрепить";
  conversationContextMenu.style.left = `${Math.min(x, window.innerWidth - 210)}px`;
  conversationContextMenu.style.top = `${Math.min(y, window.innerHeight - 220)}px`;
  hideContextMenu();
  conversationContextMenu.classList.remove("hidden");
}

document.addEventListener("click", (e) => {
  if (!messageContextMenu.contains(e.target) && !reactionPicker.contains(e.target)) {
    hideContextMenu();
  }
  if (!conversationContextMenu.contains(e.target)) {
    hideConversationContextMenu();
  }
});

function openMessageContextMenu(msgId, x, y) {
  state.contextMenuMessageId = msgId;
  const messages = state.messagesByConversation.get(state.activeConversationId) || [];
  const msg = messages.find((m) => m.id === msgId);
  const isMine = msg && msg.senderId === state.me?.id;
  ctxEdit.style.display = isMine && msg.messageType === "text" && !msg.imageData && !msg.voiceData ? "" : "none";
  messageContextMenu.style.left = `${Math.min(x, window.innerWidth - 190)}px`;
  messageContextMenu.style.top = `${Math.min(y, window.innerHeight - 200)}px`;
  hideConversationContextMenu();
  messageContextMenu.classList.remove("hidden");
  reactionPicker.classList.add("hidden");
}

document.addEventListener("contextmenu", (e) => {
  const row = e.target.closest(".message-row");
  if (!row || state.deleteMode) return;
  e.preventDefault();
  openMessageContextMenu(row.dataset.messageId, e.clientX, e.clientY);
});

// Long-press for mobile (touch hold 500ms)
let _longPressTimer = null;
let _longPressTriggered = false;

messagesEl.addEventListener("touchstart", (e) => {
  const row = e.target.closest(".message-row");
  if (!row || state.deleteMode) return;
  _longPressTriggered = false;
  const touch = e.touches[0];
  const startX = touch.clientX;
  const startY = touch.clientY;
  _longPressTimer = setTimeout(() => {
    _longPressTriggered = true;
    openMessageContextMenu(row.dataset.messageId, startX, startY);
    if (navigator.vibrate) navigator.vibrate(30);
  }, 500);
}, { passive: true });

messagesEl.addEventListener("touchmove", () => {
  clearTimeout(_longPressTimer);
}, { passive: true });

messagesEl.addEventListener("touchend", (e) => {
  clearTimeout(_longPressTimer);
  if (_longPressTriggered) {
    e.preventDefault();
    _longPressTriggered = false;
  }
});

ctxReply.addEventListener("click", () => {
  const messages = state.messagesByConversation.get(state.activeConversationId) || [];
  const msg = messages.find((m) => m.id === state.contextMenuMessageId);
  if (!msg) { hideContextMenu(); return; }
  state.replyToMessage = msg;
  replyBarText.textContent = getMessageTypePreview(msg, "Сообщение").slice(0, 80);
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
  const fwdText = msg.messageType === "voice"
    ? "🎤 Голосовое (пересланное)"
    : msg.messageType === "image"
      ? `${SCREENSHOT_MESSAGE_TEXT} (пересланное)`
      : (msg.text || "");
  const body = { text: fwdText, forwardFromId: msg.id };
  if (msg.messageType === "voice" && msg.voiceData) {
    body.voiceData = msg.voiceData;
  }
  if (msg.messageType === "image" && msg.imageData) {
    body.imageData = msg.imageData;
  }
  api(`/api/conversations/${targetConv.id}/messages`, {
    method: "POST",
    body,
  })
    .then(() => {
      playOutgoingMessageSound();
    })
    .catch((e) => { authStatus.textContent = e.message; });
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

convCtxPin.addEventListener("click", () => {
  const conversationId = state.contextMenuConversationId;
  hideConversationContextMenu();
  if (!conversationId) {
    return;
  }
  toggleConversationPinned(conversationId);
});

convCtxClear.addEventListener("click", async () => {
  const conversationId = state.contextMenuConversationId;
  hideConversationContextMenu();
  if (!conversationId) {
    return;
  }

  const conversation = getConversationById(conversationId);
  if (!conversation) {
    return;
  }

  const title = getConversationTitle(conversation);
  if (!window.confirm(`Очистить историю чата "${title}"? Сообщения будут удалены для всех участников.`)) {
    return;
  }

  try {
    await clearConversationHistoryById(conversationId);
  } catch (error) {
    authStatus.textContent = error.message;
  }
});

convCtxDelete.addEventListener("click", async () => {
  const conversationId = state.contextMenuConversationId;
  hideConversationContextMenu();
  if (!conversationId) {
    return;
  }

  const conversation = getConversationById(conversationId);
  if (!conversation) {
    return;
  }

  const title = getConversationTitle(conversation);
  if (!window.confirm(`Удалить чат "${title}" для всех участников?`)) {
    return;
  }

  try {
    await deleteConversationById(conversationId);
    setDeleteMode(false);
  } catch (error) {
    authStatus.textContent = error.message;
  }
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
          await sendMessageWithOptimistic(body);
          playOutgoingMessageSound();
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
const GROUP_AVATAR_MAX_BYTES = 1.5 * 1024 * 1024;

function getTwoInitials(value) {
  const text = String(value || "").trim();
  if (!text) return "?";
  const words = text.split(/\s+/).filter(Boolean);
  if (words.length === 1) {
    const chars = Array.from(words[0].toUpperCase());
    return `${chars[0] || "?"}${chars[1] || ""}`;
  }
  const first = Array.from(words[0].toUpperCase())[0] || "?";
  const second = Array.from(words[1].toUpperCase())[0] || "";
  return `${first}${second}`;
}

function hashText(value) {
  let hash = 0;
  for (const ch of String(value || "")) {
    hash = ((hash << 5) - hash + ch.charCodeAt(0)) | 0;
  }
  return Math.abs(hash);
}

function getAvatarGradient(value) {
  const hue = hashText(value) % 360;
  return `linear-gradient(145deg, hsl(${hue} 68% 48%), hsl(${(hue + 28) % 360} 72% 58%))`;
}

function createGroupUserAvatar(user, className) {
  const avatar = document.createElement("span");
  avatar.className = className;
  avatar.textContent = getTwoInitials(user.username || user.email || "U");
  avatar.style.background = getAvatarGradient(user.id || user.username || user.email || "");
  return avatar;
}

function setGroupStatus(text = "") {
  groupCreateStatus.textContent = text;
}

function renderGroupAvatarPreview() {
  if (!groupAvatarPreview) return;
  groupAvatarPreview.innerHTML = "";
  if (state.groupCreateAvatarData) {
    const img = document.createElement("img");
    img.src = state.groupCreateAvatarData;
    img.alt = "Фото группы";
    groupAvatarPreview.appendChild(img);
    groupAvatarPreview.classList.add("has-image");
    return;
  }

  groupAvatarPreview.classList.remove("has-image");
  groupAvatarPreview.innerHTML = `
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="26" height="26" aria-hidden="true">
      <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"></path>
      <circle cx="12" cy="13" r="4"></circle>
    </svg>
    <span>Фото</span>
  `;
}

function setGroupPrivacyMode(isPrivate) {
  state.groupCreateIsPrivate = Boolean(isPrivate);
  const mode = state.groupCreateIsPrivate ? "private" : "public";
  if (groupPrivacyToggle) {
    groupPrivacyToggle.dataset.mode = mode;
  }
  groupTypePrivateBtn.classList.toggle("is-active", state.groupCreateIsPrivate);
  groupTypePublicBtn.classList.toggle("is-active", !state.groupCreateIsPrivate);
}

function renderGroupCreateBtnState() {
  const hasName = Boolean(groupNameInput.value.trim());
  groupCreateBtn.disabled = !hasName;
  const memberCount = state.groupSelectedMembers.length;
  if (groupCreateCount) {
    groupCreateCount.textContent = String(memberCount);
    groupCreateCount.classList.toggle("hidden", memberCount === 0);
  }
}

function renderGroupMemberResults(users = [], query = "") {
  groupMemberResults.innerHTML = "";

  if (query === "__loading__") {
    const note = document.createElement("p");
    note.className = "create-group-empty-note";
    note.textContent = "Поиск...";
    groupMemberResults.appendChild(note);
    return;
  }

  if (!query || query.length < 2) {
    const note = document.createElement("p");
    note.className = "create-group-empty-note";
    note.textContent = "Введите минимум 2 символа для поиска";
    groupMemberResults.appendChild(note);
    return;
  }

  if (!users.length) {
    const note = document.createElement("p");
    note.className = "create-group-empty-note";
    note.textContent = "Пользователи не найдены";
    groupMemberResults.appendChild(note);
    return;
  }

  for (const user of users) {
    const row = document.createElement("button");
    row.type = "button";
    row.className = "create-group-contact-item";

    const avatar = createGroupUserAvatar(user, "create-group-contact-avatar");

    const info = document.createElement("span");
    info.className = "create-group-contact-info";

    const nameEl = document.createElement("span");
    nameEl.className = "create-group-contact-name";
    nameEl.textContent = user.username || "Пользователь";

    const handleEl = document.createElement("span");
    handleEl.className = "create-group-contact-handle";
    handleEl.textContent = user.email || "";

    info.append(nameEl, handleEl);

    const marker = document.createElement("span");
    marker.className = "create-group-contact-check";
    marker.innerHTML = `
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" width="13" height="13" aria-hidden="true">
        <path d="M20 6 9 17l-5-5"></path>
      </svg>
    `;

    row.append(avatar, info, marker);
    row.addEventListener("click", () => {
      if (state.groupSelectedMembers.some((member) => member.id === user.id)) return;
      state.groupSelectedMembers.push(user);
      groupMemberSearch.value = "";
      renderGroupSelectedMembers();
      renderGroupMemberResults([], "");
      setGroupStatus("");
      groupMemberSearch.focus();
    });

    groupMemberResults.appendChild(row);
  }
}

function renderGroupSelectedMembers() {
  groupSelectedMembers.innerHTML = "";
  const members = state.groupSelectedMembers || [];
  groupSelectedMembers.classList.toggle("hidden", members.length === 0);

  for (const member of members) {
    const item = document.createElement("div");
    item.className = "create-group-selected-item";

    const avatar = createGroupUserAvatar(member, "create-group-selected-avatar");

    const removeBtn = document.createElement("button");
    removeBtn.type = "button";
    removeBtn.className = "create-group-selected-remove";
    removeBtn.setAttribute("aria-label", `Удалить ${member.username || "участника"}`);
    removeBtn.innerHTML = `
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round" width="12" height="12" aria-hidden="true">
        <path d="M18 6 6 18"></path>
        <path d="M6 6l12 12"></path>
      </svg>
    `;
    removeBtn.addEventListener("click", () => {
      state.groupSelectedMembers = state.groupSelectedMembers.filter((entry) => entry.id !== member.id);
      renderGroupSelectedMembers();
      setGroupStatus("");
    });

    const name = document.createElement("span");
    name.className = "create-group-selected-name";
    const firstName = String(member.username || "")
      .trim()
      .split(/\s+/)
      .filter(Boolean)[0];
    name.textContent = firstName || member.username || "Участник";

    item.append(avatar, removeBtn, name);
    groupSelectedMembers.appendChild(item);
  }

  renderGroupCreateBtnState();
}

function resetCreateGroupModal() {
  state.groupSelectedMembers = [];
  state.groupCreateIsPrivate = true;
  state.groupCreateAvatarData = "";

  groupNameInput.value = "";
  if (groupDescriptionInput) {
    groupDescriptionInput.value = "";
  }
  groupMemberSearch.value = "";
  if (groupAvatarFileInput) {
    groupAvatarFileInput.value = "";
  }

  renderGroupAvatarPreview();
  renderGroupSelectedMembers();
  renderGroupMemberResults([], "");
  setGroupPrivacyMode(true);
  setGroupStatus("");
  renderGroupCreateBtnState();
}

createGroupBtn.addEventListener("click", () => {
  resetCreateGroupModal();
  createGroupModal.classList.remove("hidden");
  setTimeout(() => groupNameInput.focus(), 10);
});

closeGroupModalBtn.addEventListener("click", () => createGroupModal.classList.add("hidden"));
createGroupModal.addEventListener("click", (e) => {
  if (e.target === createGroupModal) {
    createGroupModal.classList.add("hidden");
  }
});

groupNameInput.addEventListener("input", () => {
  setGroupStatus("");
  renderGroupCreateBtnState();
});

if (groupDescriptionInput) {
  groupDescriptionInput.addEventListener("input", () => setGroupStatus(""));
}

if (groupTypePrivateBtn && groupTypePublicBtn) {
  groupTypePrivateBtn.addEventListener("click", () => setGroupPrivacyMode(true));
  groupTypePublicBtn.addEventListener("click", () => setGroupPrivacyMode(false));
}

if (groupAvatarPickBtn && groupAvatarFileInput) {
  groupAvatarPickBtn.addEventListener("click", () => groupAvatarFileInput.click());
  groupAvatarFileInput.addEventListener("change", () => {
    const file = groupAvatarFileInput.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setGroupStatus("Можно выбрать только изображение");
      return;
    }
    if (file.size > GROUP_AVATAR_MAX_BYTES) {
      setGroupStatus("Файл слишком большой (макс 1.5MB)");
      groupAvatarFileInput.value = "";
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      state.groupCreateAvatarData = String(reader.result || "");
      renderGroupAvatarPreview();
      setGroupStatus("");
    };
    reader.readAsDataURL(file);
  });
}

groupMemberSearch.addEventListener("input", () => {
  const query = groupMemberSearch.value.trim();
  clearTimeout(state._groupSearchTimeout);
  setGroupStatus("");

  if (query.length < 2) {
    renderGroupMemberResults([], query);
    return;
  }

  renderGroupMemberResults([], "__loading__");
  const searchToken = Symbol("group-search");
  state._groupSearchToken = searchToken;

  state._groupSearchTimeout = setTimeout(async () => {
    try {
      const payload = await api(`/api/users?search=${encodeURIComponent(query)}`);
      if (state._groupSearchToken !== searchToken) return;

      const users = (payload.users || []).filter(
        (user) => user.id !== state.me?.id && !state.groupSelectedMembers.some((selected) => selected.id === user.id),
      );
      renderGroupMemberResults(users, query);
    } catch {
      if (state._groupSearchToken !== searchToken) return;
      groupMemberResults.innerHTML = "";
      const note = document.createElement("p");
      note.className = "create-group-empty-note";
      note.textContent = "Не удалось выполнить поиск";
      groupMemberResults.appendChild(note);
    }
  }, 250);
});

groupCreateBtn.addEventListener("click", async () => {
  const name = groupNameInput.value.trim();
  if (!name) {
    setGroupStatus("Введите название группы");
    return;
  }
  if (state.groupSelectedMembers.length === 0) {
    setGroupStatus("Добавьте участников");
    return;
  }

  setGroupStatus("");
  groupCreateBtn.disabled = true;

  try {
    const payload = await api("/api/conversations/group", {
      method: "POST",
      body: {
        name,
        description: groupDescriptionInput ? groupDescriptionInput.value.trim() : "",
        isPrivate: state.groupCreateIsPrivate,
        memberIds: state.groupSelectedMembers.map((member) => member.id),
      },
    });

    let conversation = payload.conversation;
    upsertConversation(conversation);

    if (state.groupCreateAvatarData) {
      try {
        const avatarPayload = await api(`/api/conversations/${conversation.id}/group`, {
          method: "PATCH",
          body: { avatarUrl: state.groupCreateAvatarData },
        });
        if (avatarPayload?.conversation) {
          conversation = avatarPayload.conversation;
          upsertConversation(conversation);
        }
      } catch (avatarError) {
        console.warn("Failed to apply group avatar during create flow", avatarError);
      }
    }

    renderConversationList();
    await selectConversation(conversation.id);
    createGroupModal.classList.add("hidden");
  } catch (e) {
    setGroupStatus(e.message);
  } finally {
    renderGroupCreateBtnState();
  }
});

// ========================
// GROUP SETTINGS
// ========================
function openGroupSettings() {
  const conv = getActiveConversation();
  if (!conv || conv.type !== "group") return;
  groupSettingsModal.classList.remove("hidden");
  gsStatus.textContent = "";
  gsAddMemberSearch.value = "";
  gsAddMemberResults.innerHTML = "";
  renderGroupSettingsHeader(conv);
  renderGroupSettingsMembers(conv);
  gsNameInput.value = conv.name || "";
  const isCreator = conv.creatorId === state.me?.id || (!conv.creatorId && conv.participantIds?.[0] === state.me?.id);
  gsDeleteGroupBtn.classList.toggle("hidden", !isCreator);
}

function closeGroupSettings() {
  groupSettingsModal.classList.add("hidden");
}

function renderGroupSettingsHeader(conv) {
  gsGroupName.textContent = conv.name || "Группа";
  const memberCount = conv.participants?.length || conv.participantIds?.length || 0;
  const onlineCount = (conv.participants || []).filter((p) => p.online).length;
  gsGroupMeta.textContent = `${memberCount} участников, ${onlineCount} онлайн`;
  gsMemberCount.textContent = `(${memberCount})`;

  // Avatar
  gsAvatarPreview.innerHTML = "";
  if (conv.avatarUrl) {
    const img = document.createElement("img");
    img.src = conv.avatarUrl;
    img.alt = conv.name || "Группа";
    gsAvatarPreview.appendChild(img);
  } else {
    const span = document.createElement("span");
    span.className = "gs-avatar-initial";
    span.textContent = (conv.name || "Г").charAt(0).toUpperCase();
    gsAvatarPreview.appendChild(span);
  }
}

function renderGroupSettingsMembers(conv) {
  gsMemberList.innerHTML = "";
  const creatorId = conv.creatorId || conv.participantIds?.[0];
  const isCreator = creatorId === state.me?.id;
  const participants = conv.participants || [];

  for (const member of participants) {
    const li = document.createElement("li");
    li.className = "gs-member-item";

    // Avatar
    const avatarDiv = document.createElement("div");
    avatarDiv.className = "gs-member-avatar";
    if (member.avatarUrl) {
      const img = document.createElement("img");
      img.src = member.avatarUrl;
      img.alt = member.username;
      avatarDiv.appendChild(img);
    } else {
      avatarDiv.textContent = (member.username || "?").charAt(0).toUpperCase();
    }
    li.appendChild(avatarDiv);

    // Info
    const infoDiv = document.createElement("div");
    infoDiv.className = "gs-member-info";
    const nameP = document.createElement("p");
    nameP.className = "gs-member-name";
    nameP.textContent = member.username || "—";

    if (member.id === creatorId) {
      const badge = document.createElement("span");
      badge.className = "gs-creator-badge";
      badge.textContent = "Создатель";
      nameP.appendChild(badge);
    }
    if (member.id === state.me?.id) {
      const badge = document.createElement("span");
      badge.className = "gs-you-badge";
      badge.textContent = "Вы";
      nameP.appendChild(badge);
    }
    infoDiv.appendChild(nameP);

    const statusP = document.createElement("p");
    statusP.className = "gs-member-status";
    if (member.online) {
      statusP.textContent = "онлайн";
      statusP.classList.add("online");
    } else {
      statusP.textContent = member.lastSeenAt ? formatLastSeen(member.lastSeenAt) : "оффлайн";
    }
    infoDiv.appendChild(statusP);
    li.appendChild(infoDiv);

    // Kick button (only for creator, not for self)
    if (isCreator && member.id !== state.me?.id) {
      const kickBtn = document.createElement("button");
      kickBtn.className = "gs-member-kick";
      kickBtn.textContent = "Удалить";
      kickBtn.title = "Удалить участника из группы";
      kickBtn.addEventListener("click", async () => {
        if (!confirm(`Удалить ${member.username} из группы?`)) return;
        try {
          const payload = await api(`/api/conversations/${conv.id}/members/${member.id}`, { method: "DELETE" });
          upsertConversation(payload.conversation);
          renderConversationList();
          renderActiveConversationHeader();
          openGroupSettings(); // refresh
        } catch (e) {
          gsStatus.textContent = e.message || "Ошибка";
        }
      });
      li.appendChild(kickBtn);
    }

    gsMemberList.appendChild(li);
  }
}

groupSettingsHeaderBtn.addEventListener("click", openGroupSettings);
closeGroupSettingsBtn.addEventListener("click", closeGroupSettings);
groupSettingsModal.addEventListener("click", (e) => {
  if (e.target === groupSettingsModal) closeGroupSettings();
});

// Chat title click also opens group settings
chatTitle.addEventListener("click", () => {
  const conv = getActiveConversation();
  if (conv && conv.type === "group") openGroupSettings();
});

// --- Rename group ---
gsNameSaveBtn.addEventListener("click", async () => {
  const conv = getActiveConversation();
  if (!conv || conv.type !== "group") return;
  const newName = gsNameInput.value.trim();
  if (!newName) { gsStatus.textContent = "Название не может быть пустым"; return; }
  if (newName === conv.name) { gsStatus.textContent = ""; return; }
  try {
    gsNameSaveBtn.disabled = true;
    const payload = await api(`/api/conversations/${conv.id}/group`, {
      method: "PATCH",
      body: { name: newName },
    });
    upsertConversation(payload.conversation);
    renderConversationList();
    renderActiveConversationHeader();
    renderGroupSettingsHeader(payload.conversation);
    gsStatus.textContent = "Название обновлено ✓";
    setTimeout(() => { gsStatus.textContent = ""; }, 2000);
  } catch (e) {
    gsStatus.textContent = e.message || "Ошибка";
  } finally {
    gsNameSaveBtn.disabled = false;
  }
});

// --- Group avatar upload ---
gsAvatarPreview.addEventListener("click", () => gsAvatarFileInput.click());
gsAvatarUploadBtn.addEventListener("click", () => gsAvatarFileInput.click());

gsAvatarFileInput.addEventListener("change", async () => {
  const file = gsAvatarFileInput.files?.[0];
  if (!file) return;
  if (file.size > 1.5 * 1024 * 1024) { gsStatus.textContent = "Макс размер 1.5MB"; return; }
  const conv = getActiveConversation();
  if (!conv || conv.type !== "group") return;
  try {
    const dataUrl = await new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
    const payload = await api(`/api/conversations/${conv.id}/group`, {
      method: "PATCH",
      body: { avatarUrl: dataUrl },
    });
    upsertConversation(payload.conversation);
    renderConversationList();
    renderActiveConversationHeader();
    renderGroupSettingsHeader(payload.conversation);
    gsStatus.textContent = "Фото обновлено ✓";
    setTimeout(() => { gsStatus.textContent = ""; }, 2000);
  } catch (e) {
    gsStatus.textContent = e.message || "Ошибка загрузки";
  }
  gsAvatarFileInput.value = "";
});

gsAvatarRemoveBtn.addEventListener("click", async () => {
  const conv = getActiveConversation();
  if (!conv || conv.type !== "group") return;
  try {
    const payload = await api(`/api/conversations/${conv.id}/group`, {
      method: "PATCH",
      body: { avatarUrl: "" },
    });
    upsertConversation(payload.conversation);
    renderConversationList();
    renderActiveConversationHeader();
    renderGroupSettingsHeader(payload.conversation);
    gsStatus.textContent = "Фото удалено";
    setTimeout(() => { gsStatus.textContent = ""; }, 2000);
  } catch (e) {
    gsStatus.textContent = e.message || "Ошибка";
  }
});

// --- Add member search ---
let gsSearchTimeout = null;
gsAddMemberSearch.addEventListener("input", () => {
  clearTimeout(gsSearchTimeout);
  const query = gsAddMemberSearch.value.trim();
  if (!query) { gsAddMemberResults.innerHTML = ""; return; }
  gsSearchTimeout = setTimeout(async () => {
    try {
      const results = await api(`/api/users/search?q=${encodeURIComponent(query)}`);
      const conv = getActiveConversation();
      if (!conv) return;
      const currentIds = new Set(conv.participantIds || []);
      gsAddMemberResults.innerHTML = "";
      for (const user of (results.users || results || [])) {
        if (currentIds.has(user.id)) continue;
        if (user.id === state.me?.id) continue;
        const li = document.createElement("li");
        li.className = "list-item";
        li.style.cursor = "pointer";
        li.textContent = user.username || user.email;
        li.addEventListener("click", async () => {
          try {
            const payload = await api(`/api/conversations/${conv.id}/members`, {
              method: "POST",
              body: { userId: user.id },
            });
            upsertConversation(payload.conversation);
            renderConversationList();
            renderActiveConversationHeader();
            openGroupSettings(); // refresh
            gsAddMemberSearch.value = "";
            gsAddMemberResults.innerHTML = "";
            gsStatus.textContent = `${user.username} добавлен ✓`;
            setTimeout(() => { gsStatus.textContent = ""; }, 2000);
          } catch (e) {
            gsStatus.textContent = e.message || "Ошибка";
          }
        });
        gsAddMemberResults.appendChild(li);
      }
      if (gsAddMemberResults.children.length === 0) {
        const empty = document.createElement("li");
        empty.className = "list-item";
        empty.style.color = "var(--text-subtle)";
        empty.textContent = "Не найдено";
        gsAddMemberResults.appendChild(empty);
      }
    } catch (e) {
      gsAddMemberResults.innerHTML = "";
    }
  }, 300);
});

// --- Leave group ---
gsLeaveBtn.addEventListener("click", async () => {
  const conv = getActiveConversation();
  if (!conv || conv.type !== "group") return;
  if (!confirm(`Покинуть группу "${conv.name}"? Вы не сможете вернуться сами.`)) return;
  try {
    await api(`/api/conversations/${conv.id}/leave`, { method: "POST" });
    closeGroupSettings();
    await removeConversationFromState(conv.id);
  } catch (e) {
    gsStatus.textContent = e.message || "Ошибка";
  }
});

// --- Delete group ---
gsDeleteGroupBtn.addEventListener("click", async () => {
  const conv = getActiveConversation();
  if (!conv || conv.type !== "group") return;
  if (!confirm(`Удалить группу "${conv.name}" для всех участников? Это действие нельзя отменить.`)) return;
  try {
    await api(`/api/conversations/${conv.id}`, { method: "DELETE" });
    closeGroupSettings();
    await removeConversationFromState(conv.id);
  } catch (e) {
    gsStatus.textContent = e.message || "Ошибка";
  }
});

// ========================
// PUSH NOTIFICATIONS (Service Worker + Web Push)
// ========================
let swRegistration = null;

async function registerServiceWorker() {
  if (!("serviceWorker" in navigator)) return null;
  try {
    const reg = await navigator.serviceWorker.register("/sw.js");
    swRegistration = reg;
    console.log("Service Worker registered");
    return reg;
  } catch (e) {
    console.warn("Service Worker registration failed:", e);
    return null;
  }
}

function urlBase64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const rawData = atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; i++) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

async function subscribeToPush() {
  if (!swRegistration) return;
  try {
    const keyResp = await api("/api/push/vapid-key");
    const applicationServerKey = urlBase64ToUint8Array(keyResp.publicKey);

    let subscription = await swRegistration.pushManager.getSubscription();
    if (!subscription) {
      subscription = await swRegistration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey,
      });
    }

    await api("/api/push/subscribe", {
      method: "POST",
      body: { subscription: subscription.toJSON() },
    });

    notifToggleBtn.textContent = "Включены ✓";
    console.log("Push subscription active");
  } catch (e) {
    console.warn("Push subscription failed:", e);
    notifToggleBtn.textContent = "Ошибка подписки";
  }
}

async function unsubscribeFromPush() {
  if (!swRegistration) return;
  try {
    const subscription = await swRegistration.pushManager.getSubscription();
    if (subscription) {
      await api("/api/push/unsubscribe", {
        method: "POST",
        body: { endpoint: subscription.endpoint },
      });
      await subscription.unsubscribe();
    }
    notifToggleBtn.textContent = "Включить";
  } catch (e) {
    console.warn("Push unsubscribe failed:", e);
  }
}

async function checkPushState() {
  if (!swRegistration || !("PushManager" in window)) {
    notifToggleBtn.textContent = "Не поддерживается";
    notifToggleBtn.disabled = true;
    return;
  }

  const permission = Notification.permission;
  if (permission === "denied") {
    notifToggleBtn.textContent = "Заблокированы";
    notifToggleBtn.disabled = true;
    return;
  }

  const subscription = await swRegistration.pushManager.getSubscription();
  if (subscription && permission === "granted") {
    notifToggleBtn.textContent = "Включены ✓";
  } else {
    notifToggleBtn.textContent = "Включить";
  }
}

notifToggleBtn.addEventListener("click", async () => {
  if (!("Notification" in window)) {
    alert("Браузер не поддерживает уведомления");
    return;
  }

  const subscription = swRegistration
    ? await swRegistration.pushManager.getSubscription()
    : null;

  if (subscription && Notification.permission === "granted") {
    await unsubscribeFromPush();
    return;
  }

  if (Notification.permission === "denied") {
    alert("Уведомления заблокированы в настройках браузера. Разрешите их вручную.");
    return;
  }

  const perm = await Notification.requestPermission();
  if (perm === "granted") {
    await subscribeToPush();
  } else {
    notifToggleBtn.textContent = "Отклонено";
  }
});

function showPushNotification(title, body) {
  if (!("Notification" in window) || Notification.permission !== "granted") return;
  if (!document.hidden) return;
  try {
    if (swRegistration) {
      swRegistration.showNotification(title, {
        body,
        icon: "/icons/icon-192.png",
        badge: "/icons/icon-192.png",
        tag: "wave-msg",
        renotify: true,
        vibrate: [200, 100, 200],
      });
    } else {
      new Notification(title, { body, icon: "/icons/icon-192.png", tag: "wave-msg" });
    }
  } catch { }
}

// ========================
// UPDATED RENDER FOR CONVERSATION LIST (groups + avatars)
// ========================
function getConversationTitle(conversation) {
  if (conversation.type === "group") return conversation.name || "Группа";
  return conversation.participant ? conversation.participant.username : "Диалог";
}

function getConversationAvatar(conversation) {
  if (conversation.type === "group") return conversation.avatarUrl || null;
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
  applyFullscreen();
  syncUiControls();
  renderTwoFaState();
  updateDeleteUi();
  updateChatLockUi();
  setSettingsPanelOpen(false);
  setAuthTab("login");
  renderSearchResults([]);

  await registerServiceWorker();
  await checkPushState();

  try {
    const payload = await api("/api/auth/me");
    await bootstrapSession(payload.user);

    if (
      swRegistration &&
      "PushManager" in window &&
      Notification.permission === "granted"
    ) {
      const existing = await swRegistration.pushManager.getSubscription();
      if (existing) {
        await api("/api/push/subscribe", {
          method: "POST",
          body: { subscription: existing.toJSON() },
        }).catch(() => { });
      }
    }
  } catch {
    showAuth();
  }
}

// ========================
// VIDEO / AUDIO SETTINGS HANDLERS
// ========================
function closePopovers() {
  [micSettingsPopover, videoSettingsPopover, speakerSettingsPopover].forEach(el => {
    el?.classList.add("hidden");
  });
  const splitGroups = document.querySelectorAll('.control-split-group');
  splitGroups.forEach(el => el.classList.remove('active-popover'));
  closeCpopLists();
}

function togglePopover(popover, triggerChevron) {
  const isHidden = popover.classList.contains("hidden");
  closePopovers();
  if (isHidden) {
    popover.classList.remove("hidden");
    triggerChevron.closest('.control-split-group').classList.add('active-popover');
    // Sync slider values and percent labels with current state
    syncCpopVolume("popoverMicVolume", "micVolPct", "micMuteBtn", state.call.micVolume);
    syncCpopVolume("popoverSpeakerVolume", "speakerVolPct", "speakerMuteBtn", state.call.speakerVolume);
  }
}

async function handleNegotiationNeeded() {
  if (!state.call.active || !state.call.peer) return;
  try {
    const offer = await state.call.peer.createOffer();
    await state.call.peer.setLocalDescription(offer);
    sendSocketPayload({
      type: "call:signal",
      targetUserId: state.call.targetUserId,
      signalType: "offer",
      conversationId: state.call.conversationId,
      data: { sdp: state.call.peer.localDescription },
    });
  } catch (err) {
    console.error("Negotiation failed:", err);
  }
}

function stopVideoTrack() {
  const stream = state.call.localStream;

  // Remove video sender from peer FIRST (before stopping the track)
  // so renegotiation properly signals track removal to remote
  if (state.call.peer) {
    const senders = state.call.peer.getSenders();
    for (const sender of senders) {
      if (sender.track && sender.track.kind === "video") {
        state.call.peer.removeTrack(sender);
      }
    }
  }

  // Now stop and remove local video tracks
  if (stream) {
    for (const videoTrack of stream.getVideoTracks()) {
      videoTrack.stop();
      stream.removeTrack(videoTrack);
    }
  }

  if (localVideo) {
    localVideo.srcObject = null;
    localVideo.classList.add("hidden");
  }
  if (activeCallMeAvatar) {
    activeCallMeAvatar.classList.remove("hidden");
  }
  state.call.videoEnabled = false;
  state.call.screenShareEnabled = false;

  // Trigger renegotiation so remote side learns the video track is gone
  handleNegotiationNeeded();
  renderActiveCallOverlay();
}

async function addVideoTrack(newStream) {
  const newVideoTrack = newStream.getVideoTracks()[0];
  if (!newVideoTrack) return;

  // If there is an existing audio track, keep it
  if (!state.call.localStream) {
    state.call.localStream = new MediaStream();
  }

  // Remove old video track if any
  const oldVideoTrack = state.call.localStream.getVideoTracks()[0];
  if (oldVideoTrack) {
    oldVideoTrack.stop();
    state.call.localStream.removeTrack(oldVideoTrack);
  }

  state.call.localStream.addTrack(newVideoTrack);

  // Add to peer
  if (state.call.peer) {
    // Check if we already have a video sender
    const senders = state.call.peer.getSenders();
    const videoSender = senders.find(s => s.track && s.track.kind === "video");

    if (videoSender) {
      videoSender.replaceTrack(newVideoTrack);
    } else {
      state.call.peer.addTrack(newVideoTrack, state.call.localStream);
    }
  }

  // Preview
  if (localVideo) {
    localVideo.srcObject = new MediaStream([newVideoTrack]);
    localVideo.classList.remove("hidden");
  }
  if (activeCallMeAvatar) {
    activeCallMeAvatar.classList.add("hidden");
  }

  newVideoTrack.onended = () => {
    stopVideoTrack();
  };

  handleNegotiationNeeded();
  renderActiveCallOverlay();
}

async function toggleWebcam() {
  if (state.call.videoEnabled) {
    stopVideoTrack();
    return;
  }

  try {
    const stream = await navigator.mediaDevices.getUserMedia({ video: true });
    state.call.videoEnabled = true;
    state.call.screenShareEnabled = false;
    await addVideoTrack(stream);
  } catch (err) {
    console.error("Webcam error:", err);
    setCallStatus("Не удалось включить камеру.", true);
  }
}

async function toggleScreenShare() {
  if (state.call.screenShareEnabled) {
    stopVideoTrack();
    return;
  }

  try {
    const stream = await navigator.mediaDevices.getDisplayMedia({ video: true });
    state.call.screenShareEnabled = true;
    state.call.videoEnabled = false;
    await addVideoTrack(stream);
  } catch (err) {
    console.error("Screen share error:", err);
  }
}

// Listeners
if (activeCallMuteChevron) {
  activeCallMuteChevron.addEventListener("click", (e) => {
    e.stopPropagation();
    togglePopover(micSettingsPopover, activeCallMuteChevron);
  });
}

if (activeCallVideoChevron) {
  activeCallVideoChevron.addEventListener("click", (e) => {
    e.stopPropagation();
    togglePopover(videoSettingsPopover, activeCallVideoChevron);
  });
}

if (activeCallSpeakerChevron) {
  activeCallSpeakerChevron.addEventListener("click", (e) => {
    e.stopPropagation();
    togglePopover(speakerSettingsPopover, activeCallSpeakerChevron);
  });
}

if (activeCallVideoBtn) {
  activeCallVideoBtn.addEventListener("click", () => {
    // If video is on -> turn off
    if (state.call.videoEnabled || state.call.screenShareEnabled) {
      stopVideoTrack();
    } else {
      // If off -> default to webcam
      toggleWebcam();
    }
  });
}

if (popoverWebcamBtn) {
  popoverWebcamBtn.addEventListener("click", () => {
    closePopovers();
    if (!state.call.videoEnabled) {
      toggleWebcam();
    } else {
      stopVideoTrack();
    }
  });
}

if (popoverScreenShareBtn) {
  popoverScreenShareBtn.addEventListener("click", () => {
    closePopovers();
    if (!state.call.screenShareEnabled) {
      toggleScreenShare();
    } else {
      stopVideoTrack();
    }
  });
}

function updateMicTestBars(level = 0) {
  if (!settingsMicTestBars) return;
  const bars = settingsMicTestBars.children;
  const active = Math.floor((bars.length || 1) * Math.max(0, Math.min(1, level)));
  for (let i = 0; i < bars.length; i += 1) {
    const bar = bars[i];
    const isActive = i < active;
    bar.classList.toggle("active", isActive);
    bar.style.height = (isActive ? 14 + Math.random() * 14 : 8) + "px";
  }
}

function stopMicTest() {
  micTestState.running = false;
  if (micTestState.rafId) cancelAnimationFrame(micTestState.rafId);
  micTestState.rafId = null;
  if (micTestState.stream) {
    micTestState.stream.getTracks().forEach((track) => track.stop());
  }
  if (micTestState.ctx) {
    micTestState.ctx.close().catch(() => {});
  }
  micTestState.stream = null;
  micTestState.ctx = null;
  micTestState.analyser = null;
  if (settingsMicTestBtn) {
    settingsMicTestBtn.classList.remove("testing");
    settingsMicTestBtn.textContent = "Mic Test";
  }
  updateMicTestBars(0);
}

async function startMicTest() {
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) return;
  ensureMicTestBars();
  try {
    const stream = await navigator.mediaDevices.getUserMedia(getAudioConstraints());
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const analyser = ctx.createAnalyser();
    analyser.fftSize = 128;
    const source = ctx.createMediaStreamSource(stream);
    source.connect(analyser);

    micTestState.stream = stream;
    micTestState.ctx = ctx;
    micTestState.analyser = analyser;
    micTestState.running = true;

    if (settingsMicTestBtn) {
      settingsMicTestBtn.classList.add("testing");
      settingsMicTestBtn.textContent = "Stop";
    }

    const data = new Uint8Array(analyser.frequencyBinCount);
    const tick = () => {
      if (!micTestState.running || !micTestState.analyser) return;
      micTestState.analyser.getByteTimeDomainData(data);
      let sum = 0;
      for (let i = 0; i < data.length; i += 1) {
        const v = (data[i] - 128) / 128;
        sum += v * v;
      }
      updateMicTestBars(Math.min(1, Math.sqrt(sum / data.length) * 4));
      micTestState.rafId = requestAnimationFrame(tick);
    };

    tick();
  } catch {
    stopMicTest();
  }
}

// ========================
// CPOP — helpers
// ========================

const MIC_ICON_SVG = `<path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/>`;
const MIC_MUTED_SVG = `<path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/><line x1="1" y1="1" x2="23" y2="23"/>`;
const SPK_ICON_SVG = `<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/>`;
const SPK_MUTED_SVG = `<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><line x1="23" y1="9" x2="17" y2="15"/><line x1="17" y1="9" x2="23" y2="15"/>`;

function syncCpopVolume(sliderId, pctId, muteId, value) {
  const slider = document.getElementById(sliderId);
  const pct = document.getElementById(pctId);
  const btn = document.getElementById(muteId);
  if (slider) { slider.value = value; }
  if (pct) pct.textContent = value + "%";
  if (btn) btn.classList.toggle("muted", value === 0);
}

function populateCpopList(listEl, devices, selectedId, onSelect, kind) {
  const itemIcon = kind === "mic"
    ? `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${MIC_ICON_SVG}</svg>`
    : `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg>`;
  const checkSvg = `<svg class="cpop-check" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>`;

  listEl.innerHTML = "";
  for (const d of devices) {
    const isSelected = d.deviceId === selectedId;
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "cpop-device-item" + (isSelected ? " selected" : "");
    btn.innerHTML = `<div class="cpop-device-item-left">${itemIcon}<span class="cpop-device-item-name">${d.label}</span></div>${isSelected ? checkSvg : ""}`;
    btn.addEventListener("click", () => onSelect(d.deviceId, d.label));
    listEl.appendChild(btn);
  }
}

function closeCpopLists() {
  ["micDeviceList", "speakerDeviceList"].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.classList.remove("open");
  });
  ["micDeviceBtn", "speakerDeviceBtn"].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.classList.remove("open");
  });
}

// Device dropdown toggles
const micDeviceBtn = document.getElementById("micDeviceBtn");
const micDeviceList = document.getElementById("micDeviceList");
const speakerDeviceBtn = document.getElementById("speakerDeviceBtn");
const speakerDeviceListEl = document.getElementById("speakerDeviceList");

function positionCpopList(listEl, selectorEl) {
  if (!listEl || !selectorEl) return;

  const rect = selectorEl.getBoundingClientRect();
  const viewportHeight = window.innerHeight || document.documentElement.clientHeight;
  const gap = 8;

  listEl.style.left = rect.left + "px";
  listEl.style.width = rect.width + "px";

  // Measure natural height in a hidden non-open state.
  listEl.classList.remove("open");
  listEl.style.visibility = "hidden";
  listEl.style.pointerEvents = "none";
  listEl.style.maxHeight = "none";

  const listHeight = listEl.scrollHeight;
  const spaceBelow = viewportHeight - rect.bottom - gap;
  const spaceAbove = rect.top - gap;
  const shouldOpenUp = spaceBelow < listHeight && spaceAbove > spaceBelow;
  const availableSpace = Math.max(120, shouldOpenUp ? spaceAbove : spaceBelow);

  listEl.style.maxHeight = availableSpace + "px";
  listEl.style.top = shouldOpenUp
    ? (Math.max(gap, rect.top - Math.min(listHeight, availableSpace)) + "px")
    : (rect.bottom + "px");

  listEl.classList.toggle("open-up", shouldOpenUp);
  listEl.style.visibility = "";
  listEl.style.pointerEvents = "";
}

if (micDeviceBtn) {
  micDeviceBtn.addEventListener("click", (e) => {
    e.stopPropagation();
    const isOpen = micDeviceList.classList.contains("open");
    closeCpopLists();
    if (!isOpen) {
      positionCpopList(micDeviceList, micDeviceBtn.closest(".cpop-device-selector"));
      micDeviceList.classList.add("open");
      micDeviceBtn.classList.add("open");
    }
  });
}
if (speakerDeviceBtn) {
  speakerDeviceBtn.addEventListener("click", (e) => {
    e.stopPropagation();
    const isOpen = speakerDeviceListEl.classList.contains("open");
    closeCpopLists();
    if (!isOpen) {
      positionCpopList(speakerDeviceListEl, speakerDeviceBtn.closest(".cpop-device-selector"));
      speakerDeviceListEl.classList.add("open");
      speakerDeviceBtn.classList.add("open");
    }
  });
}

// Volume sliders
let micPrevVol = 100;
let speakerPrevVol = 100;

const popoverMicVolume = document.getElementById("popoverMicVolume");
const popoverSpeakerVolume = document.getElementById("popoverSpeakerVolume");

if (popoverMicVolume) {
  popoverMicVolume.addEventListener("input", () => {
    const val = parseInt(popoverMicVolume.value, 10);
    state.call.micVolume = val;
    if (val > 0) micPrevVol = val;
    const pct = document.getElementById("micVolPct");
    if (pct) pct.textContent = val + "%";
    const btn = document.getElementById("micMuteBtn");
    if (btn) btn.classList.toggle("muted", val === 0);
    const icon = document.getElementById("micMuteIcon");
    if (icon) icon.innerHTML = val === 0 ? MIC_MUTED_SVG : MIC_ICON_SVG;
    if (state.call.micGainNode) state.call.micGainNode.gain.value = val / 100;
    if (settingsMicVolume) settingsMicVolume.value = String(val);
  });
}

if (popoverSpeakerVolume) {
  popoverSpeakerVolume.addEventListener("input", () => {
    const val = parseInt(popoverSpeakerVolume.value, 10);
    state.call.speakerVolume = val;
    if (val > 0) speakerPrevVol = val;
    const pct = document.getElementById("speakerVolPct");
    if (pct) pct.textContent = val + "%";
    const btn = document.getElementById("speakerMuteBtn");
    if (btn) btn.classList.toggle("muted", val === 0);
    const icon = document.getElementById("speakerMuteIcon");
    if (icon) icon.innerHTML = val === 0 ? SPK_MUTED_SVG : SPK_ICON_SVG;
    if (remoteAudio) remoteAudio.volume = val / 100;
    if (settingsSpeakerVolume) settingsSpeakerVolume.value = String(val);
  });
}

// Mute buttons
const micMuteBtn = document.getElementById("micMuteBtn");
if (micMuteBtn) {
  micMuteBtn.addEventListener("click", () => {
    const slider = document.getElementById("popoverMicVolume");
    if (!slider) return;
    const isMuted = parseInt(slider.value, 10) === 0;
    const newVal = isMuted ? micPrevVol : 0;
    slider.value = newVal;
    slider.dispatchEvent(new Event("input"));
  });
}

const speakerMuteBtn = document.getElementById("speakerMuteBtn");
if (speakerMuteBtn) {
  speakerMuteBtn.addEventListener("click", () => {
    const slider = document.getElementById("popoverSpeakerVolume");
    if (!slider) return;
    const isMuted = parseInt(slider.value, 10) === 0;
    const newVal = isMuted ? speakerPrevVol : 0;
    slider.value = newVal;
    slider.dispatchEvent(new Event("input"));
  });
}

// Close popovers on click outside
document.addEventListener("click", (e) => {
  if (!e.target.closest('.control-group-main') && !e.target.closest('.control-popover')) {
    closePopovers();
  }
});

window.addEventListener("beforeunload", stopMicTest);

// ── Custom audio device dropdowns (settings panel) ──
(function () {
  const micSelect = document.getElementById("microphoneSelect");
  const speakerSelect = document.getElementById("speakerSelect");
  const micDropdownBtn = document.getElementById("micDropdownBtn");
  const micDropdownPanel = document.getElementById("micDropdownPanel");
  const micChevron = document.getElementById("micDropdownChevron");
  const micNameEl = document.getElementById("micSelectedName");
  const speakerDropdownBtn = document.getElementById("speakerDropdownBtn");
  const speakerDropdownPanel = document.getElementById("speakerDropdownPanel");
  const speakerChevron = document.getElementById("speakerDropdownChevron");
  const speakerNameEl = document.getElementById("speakerSelectedName");
  const micVolSlider = document.getElementById("settingsMicVolume");
  const speakerVolSlider = document.getElementById("settingsSpeakerVolume");
  const micPctEl = document.getElementById("micVolPctDisplay");
  const speakerPctEl = document.getElementById("speakerVolPctDisplay");
  const micMuteToggle = document.getElementById("micMuteToggle");
  const speakerMuteToggle = document.getElementById("speakerMuteToggle");

  const SVG_MIC_ON = `<path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="22"/>`;
  const SVG_MIC_OFF = `<line x1="1" y1="1" x2="23" y2="23"/><path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6"/><path d="M17 16.95A7 7 0 0 1 5 12v-2m14 0v2a7 7 0 0 1-.11 1.23"/><line x1="12" y1="19" x2="12" y2="22"/>`;
  const SVG_VOL_ON = `<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/>`;
  const SVG_VOL_OFF = `<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><line x1="23" y1="9" x2="17" y2="15"/><line x1="17" y1="9" x2="23" y2="15"/>`;

  let micPrevVol2 = 75;
  let speakerPrevVol2 = 75;

  function syncDropdownName(select, nameEl) {
    if (!select || !nameEl) return;
    const opt = select.options[select.selectedIndex];
    nameEl.textContent = opt ? opt.textContent : "По умолчанию";
  }

  function buildOptionHTML(isMic) {
    return isMic
      ? `<path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="22"/>`
      : `<path d="M3 18v-6a9 9 0 0 1 18 0v6"/><path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/>`;
  }

  function rebuildDropdown(select, panel, nameEl, isMic) {
    if (!select || !panel) return;
    panel.innerHTML = "";
    Array.from(select.options).forEach((opt) => {
      const isSelected = opt.value === select.value;
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "audio-dropdown-option" + (isSelected ? " selected" : "");
      btn.dataset.value = opt.value;
      btn.setAttribute("role", "option");
      btn.setAttribute("aria-selected", isSelected ? "true" : "false");
      btn.innerHTML = `
        <span class="audio-option-left">
          <svg class="audio-option-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${buildOptionHTML(isMic)}</svg>
          <span class="audio-option-name">${opt.textContent}</span>
        </span>
        ${isSelected ? `<svg class="audio-option-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>` : ""}
      `;
      btn.addEventListener("click", () => {
        select.value = opt.value;
        select.dispatchEvent(new Event("change", { bubbles: true }));
        syncDropdownName(select, nameEl);
        closeDropdown(panel, isMic ? micDropdownBtn : speakerDropdownBtn, isMic ? micChevron : speakerChevron);
        panel.querySelectorAll(".audio-dropdown-option").forEach((b) => {
          const sel = b.dataset.value === opt.value;
          b.classList.toggle("selected", sel);
          b.setAttribute("aria-selected", sel ? "true" : "false");
          const existingCheck = b.querySelector(".audio-option-check");
          if (sel && !existingCheck) {
            b.insertAdjacentHTML("beforeend", `<svg class="audio-option-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>`);
          } else if (!sel && existingCheck) {
            existingCheck.remove();
          }
        });
      });
      panel.appendChild(btn);
    });
    syncDropdownName(select, nameEl);
  }

  function openDropdown(panel, btn, chevron) {
    panel.classList.add("open");
    btn.classList.add("open");
    chevron.classList.add("open");
    btn.setAttribute("aria-expanded", "true");
  }

  function closeDropdown(panel, btn, chevron) {
    panel.classList.remove("open");
    btn.classList.remove("open");
    chevron.classList.remove("open");
    btn.setAttribute("aria-expanded", "false");
  }

  function toggleDropdown(panel, btn, chevron, otherPanel, otherBtn, otherChevron) {
    const isOpen = panel.classList.contains("open");
    closeDropdown(otherPanel, otherBtn, otherChevron);
    if (isOpen) closeDropdown(panel, btn, chevron);
    else openDropdown(panel, btn, chevron);
  }

  if (micDropdownBtn) {
    micDropdownBtn.addEventListener("click", () => {
      toggleDropdown(micDropdownPanel, micDropdownBtn, micChevron, speakerDropdownPanel, speakerDropdownBtn, speakerChevron);
    });
  }

  if (speakerDropdownBtn) {
    speakerDropdownBtn.addEventListener("click", () => {
      toggleDropdown(speakerDropdownPanel, speakerDropdownBtn, speakerChevron, micDropdownPanel, micDropdownBtn, micChevron);
    });
  }

  document.addEventListener("mousedown", (e) => {
    const micRoot = document.getElementById("micDropdown");
    if (micRoot && !micRoot.contains(e.target)) closeDropdown(micDropdownPanel, micDropdownBtn, micChevron);
    const spkRoot = document.getElementById("speakerDropdown");
    if (spkRoot && !spkRoot.contains(e.target)) closeDropdown(speakerDropdownPanel, speakerDropdownBtn, speakerChevron);
  });

  // Observe hidden selects for option changes (device enumeration)
  function watchSelect(select, panel, nameEl, isMic) {
    if (!select) return;
    new MutationObserver(() => rebuildDropdown(select, panel, nameEl, isMic))
      .observe(select, { childList: true });
  }

  watchSelect(micSelect, micDropdownPanel, micNameEl, true);
  watchSelect(speakerSelect, speakerDropdownPanel, speakerNameEl, false);
  rebuildDropdown(micSelect, micDropdownPanel, micNameEl, true);
  rebuildDropdown(speakerSelect, speakerDropdownPanel, speakerNameEl, false);

  // Volume percentage
  function updateVolPct(slider, el) {
    if (slider && el) el.textContent = slider.value + "%";
  }

  function updateSettingsMicIcon(val) {
    const icon = document.getElementById("settingsMicMuteIcon");
    if (icon) icon.innerHTML = val === 0 ? SVG_MIC_OFF : SVG_MIC_ON;
  }

  function updateSettingsSpeakerIcon(val) {
    const icon = document.getElementById("settingsSpeakerMuteIcon");
    if (icon) icon.innerHTML = val === 0 ? SVG_VOL_OFF : SVG_VOL_ON;
  }

  if (micVolSlider) {
    micVolSlider.addEventListener("input", () => {
      const val = parseInt(micVolSlider.value, 10);
      updateVolPct(micVolSlider, micPctEl);
      updateSettingsMicIcon(val);
      if (val > 0) micPrevVol2 = val;
    });
  }

  if (speakerVolSlider) {
    speakerVolSlider.addEventListener("input", () => {
      const val = parseInt(speakerVolSlider.value, 10);
      updateVolPct(speakerVolSlider, speakerPctEl);
      updateSettingsSpeakerIcon(val);
      if (val > 0) speakerPrevVol2 = val;
    });
  }

  if (micMuteToggle && micVolSlider) {
    micMuteToggle.addEventListener("click", () => {
      const cur = parseInt(micVolSlider.value, 10);
      micVolSlider.value = cur === 0 ? String(micPrevVol2 || 75) : "0";
      micVolSlider.dispatchEvent(new Event("input", { bubbles: true }));
    });
  }

  if (speakerMuteToggle && speakerVolSlider) {
    speakerMuteToggle.addEventListener("click", () => {
      const cur = parseInt(speakerVolSlider.value, 10);
      speakerVolSlider.value = cur === 0 ? String(speakerPrevVol2 || 75) : "0";
      speakerVolSlider.dispatchEvent(new Event("input", { bubbles: true }));
    });
  }

  // Sync display when settings panel becomes visible
  const settingsPanelEl = document.getElementById("settingsPanel");
  if (settingsPanelEl) {
    new MutationObserver(() => {
      if (!settingsPanelEl.classList.contains("hidden")) {
        updateVolPct(micVolSlider, micPctEl);
        updateVolPct(speakerVolSlider, speakerPctEl);
        if (micVolSlider) updateSettingsMicIcon(parseInt(micVolSlider.value, 10));
        if (speakerVolSlider) updateSettingsSpeakerIcon(parseInt(speakerVolSlider.value, 10));
        rebuildDropdown(micSelect, micDropdownPanel, micNameEl, true);
        rebuildDropdown(speakerSelect, speakerDropdownPanel, speakerNameEl, false);
      }
    }).observe(settingsPanelEl, { attributes: true, attributeFilter: ["class"] });
  }
})();

init();
