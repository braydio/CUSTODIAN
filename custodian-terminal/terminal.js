(() => {
  const ui = window.CustodianUiHelpers || {};
  const byId = ui.byId || ((id) => document.getElementById(id));
  const escapeHtml = ui.escapeHtml || ((text) => String(text));
  const isAtBottom = ui.isAtBottom || ((node, threshold) =>
    node.scrollTop + node.clientHeight >= node.scrollHeight - threshold);

  const appShell = byId("app-shell");
  const terminal = byId("terminal");
  const terminalContainer = byId("terminal-container");
  const inputForm = byId("terminal-input-form");
  const inputField = byId("terminal-input");
  const outputIndicator = byId("new-output-indicator");
  const idleTip = byId("idle-tip");
  const liveRegion = byId("terminal-live");
  const offlineBanner = byId("offline-banner");
  const inputFocusZone = byId("input-focus-zone");
  const modeLabel = byId("display-mode-label");
  const mapModeToggle = byId("map-mode-toggle");
  const mapModePanel = byId("map-mode-panel");
  const mapModeLog = byId("map-mode-log");

  const keyClick = byId("keyClick");

  const state = {
    buffer: [],
    inputEnabled: false,
    cursorVisible: false,
    liveInput: "",
    typingActive: false,
    mapHintShown: false,
    userAtBottom: true,
    history: [],
    historyIndex: -1,
    failureCount: 0,
    hintLocked: false,
    hintFocusStarted: false,
    hintSecondaryShown: false,
    hintTimer: null,
    hintFocusIntent: false,
    completionMatches: [],
    completionIndex: -1,
    completionSeed: "",
    mapMode: false,
    mapAutoTimer: null,
    mapAutoBusy: false,
  };

  const CURSOR_IDLE_MS = 420;
  const SCROLL_THRESHOLD = 8;
  const IDLE_TIP_MS = 5000;
  const MAP_AUTOWAIT_MS = 2000;

  let lastKeyClickAt = 0;
  const KEY_CLICK_MIN_INTERVAL = 28;
  let alertBurstTimer = null;
  const COMPLETION_TOKENS = [
    "HELP", "HELP CORE", "HELP MOVEMENT", "HELP SYSTEMS", "HELP POLICY", "HELP FABRICATION", "HELP ASSAULT", "HELP STATUS",
    "STATUS", "STATUS FULL", "WAIT", "WAIT UNTIL", "DEPLOY", "MOVE", "RETURN", "FOCUS", "HARDEN", "REPAIR", "SCAVENGE",
    "SET", "SET FAB", "POLICY SHOW", "POLICY PRESET", "FORTIFY", "CONFIG DOCTRINE", "ALLOCATE DEFENSE", "SCAN RELAYS",
    "STABILIZE RELAY", "SYNC", "FAB ADD", "FAB QUEUE", "FAB CANCEL", "FAB PRIORITY", "REROUTE POWER", "BOOST DEFENSE",
    "DRONE DEPLOY", "DEPLOY DRONE", "LOCKDOWN", "PRIORITIZE REPAIR", "STATUS RELAY", "DEBUG HELP",
  ];

  function playKeyClick() {
    if (!keyClick) return;
    const now = performance.now();
    if (now - lastKeyClickAt < KEY_CLICK_MIN_INTERVAL) return;
    lastKeyClickAt = now;

    try {
      keyClick.currentTime = 0;
      keyClick.volume = 0.05 + Math.random() * 0.03;
      keyClick.playbackRate = 0.95 + Math.random() * 0.1;
      keyClick.play().catch(() => {});
    } catch {}
  }

  function classifyLine(line) {
    if (line.startsWith("> ")) return "command";
    if (line.startsWith("--- ") && line.endsWith(" ---")) return "banner";
    if (line.includes("(+)") || line.includes("(-)")) return "delta";
    const heatMatch = line.match(/^\s*[> ]?\s*[A-Z ]{3,}\s+([X!~?.])(?:\s+\([+-]\))?\s*$/);
    if (heatMatch) {
      const marker = heatMatch[1];
      if (marker === "X") return "heat-critical";
      if (marker === "!") return "heat-damaged";
      if (marker === "~") return "heat-alert";
      if (marker === "?") return "heat-unknown";
      if (marker === ".") return "heat-stable";
    }
    if (line.startsWith("[EVENT]")) return "event";
    if (line.startsWith("[WARNING]")) return "warning";
    if (line.startsWith("[ASSAULT]") || line.startsWith("=== ASSAULT")) return "assault";
    if (line.startsWith("[FOCUS SET]") || line.startsWith("[HARDENING")) return "intent";
    return "";
  }

  function hasCriticalSignal(lines) {
    return lines.some((line) => {
      const text = (line || "").toUpperCase();
      if (!text) return false;
      if (text.startsWith("[WARNING]") || text.startsWith("[ASSAULT]")) return true;
      if (text.includes(" COMPROMISED") || text.endsWith(" X") || text.includes(" X(")) return true;
      if (text.includes("(+)") || text.includes("(-)")) return true;
      return false;
    });
  }

  function triggerAlertFlashBurst(pulses = 3) {
    if (!terminal) return;
    if (window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches) return;
    if (alertBurstTimer) {
      clearTimeout(alertBurstTimer);
      alertBurstTimer = null;
    }
    terminal.classList.remove("flicker");

    const pulseMs = 120;
    const gapMs = 90;
    for (let i = 0; i < pulses; i++) {
      const start = i * (pulseMs + gapMs);
      setTimeout(() => terminal.classList.add("flicker"), start);
      setTimeout(() => terminal.classList.remove("flicker"), start + pulseMs);
    }
    alertBurstTimer = setTimeout(() => {
      terminal.classList.remove("flicker");
      alertBurstTimer = null;
    }, pulses * (pulseMs + gapMs) + 10);
  }

  function render() {
    const shouldScroll = state.userAtBottom;
    const previousScrollTop = terminal.scrollTop;

    terminal.innerHTML = state.buffer
      .map((line) => {
        const cls = classifyLine(line);
        const safe = line ? escapeHtml(line) : "&nbsp;";
        const className = cls ? `terminal-line ${cls}` : "terminal-line";
        return `<div class="${className}">${safe}</div>`;
      })
      .join("");

    if (shouldScroll) {
      terminal.scrollTop = terminal.scrollHeight;
      outputIndicator?.classList.remove("visible");
    } else {
      terminal.scrollTop = previousScrollTop;
    }
  }

  function normalizeAssaultSpacing(lines, lastLine) {
    const output = [];
    let inAssault = false;
    const isAssault = (line) => line.startsWith("[ASSAULT]") || line.startsWith("=== ASSAULT");

    for (const line of lines) {
      const assaultLine = isAssault(line);
      if (assaultLine && !inAssault) {
        const previous = output.length ? output[output.length - 1] : lastLine;
        if (previous && previous !== "") output.push("");
        inAssault = true;
      }
      if (!assaultLine && inAssault) {
        if (line === "") {
          if (!output.length || output.at(-1) !== "") output.push("");
          inAssault = false;
          continue;
        }
        if (output.length && output.at(-1) !== "") output.push("");
        inAssault = false;
      }
      output.push(line);
    }

    if (inAssault && output.at(-1) !== "") output.push("");
    return output;
  }

  function renderHint(primaryFaded = false, showSecondary = false) {
    if (!idleTip || state.hintLocked) return;
    const primaryClass = primaryFaded ? "hint-primary faded" : "hint-primary";
    idleTip.innerHTML = `<span class="${primaryClass}">CLICK TO FOCUS INPUT</span>${
      showSecondary ? '<span class="hint-sep">|</span><span class="hint-secondary">TYPE HELP FOR AVAILABLE COMMANDS</span>' : ""
    }`;
    idleTip.classList.add("visible");
  }

  function primeHint() {
    if (state.hintLocked) return;
    renderHint(false, false);
  }

  function lockHints() {
    state.hintLocked = true;
    if (state.hintTimer) clearTimeout(state.hintTimer);
    idleTip?.classList.remove("visible");
  }

  function startFocusedHintSequence() {
    if (!state.hintFocusIntent || state.hintLocked || state.hintFocusStarted) return;
    state.hintFocusStarted = true;
    renderHint(true, false);
    if (state.hintTimer) clearTimeout(state.hintTimer);
    state.hintTimer = setTimeout(() => {
      if (state.hintLocked || state.hintSecondaryShown) return;
      if (!state.inputEnabled || document.activeElement !== inputField) return;
      if (state.liveInput.trim() !== "") return;
      state.hintSecondaryShown = true;
      renderHint(true, true);
    }, IDLE_TIP_MS);
  }

  function clearBuffer() {
    state.buffer = [];
    render();
  }

  function resetCompletionState() {
    state.completionMatches = [];
    state.completionIndex = -1;
    state.completionSeed = "";
  }

  function applyInputValue(value) {
    inputField.value = value;
    state.liveInput = value;
    renderLiveLine();
  }

  function autocompleteInput(reverse = false) {
    const seed = inputField.value.trim().toUpperCase();
    if (!seed) return false;

    if (state.completionSeed !== seed || !state.completionMatches.length) {
      state.completionSeed = seed;
      state.completionMatches = COMPLETION_TOKENS.filter((token) => token.startsWith(seed));
      state.completionIndex = -1;
      if (!state.completionMatches.length) return false;
    }

    const count = state.completionMatches.length;
    state.completionIndex = reverse
      ? (state.completionIndex - 1 + count) % count
      : (state.completionIndex + 1) % count;
    const suggestion = state.completionMatches[state.completionIndex];
    if (!suggestion) return false;
    applyInputValue(`${suggestion} `);
    return true;
  }

  function appendLines(lines) {
    const lastLine = state.buffer.at(-1);
    const normalized = normalizeAssaultSpacing(lines, lastLine);
    state.buffer.push(...normalized);
    render();
    if (hasCriticalSignal(normalized)) triggerAlertFlashBurst(3);
    if (!state.userAtBottom) outputIndicator?.classList.add("visible");
  }

  function appendLine(line) {
    appendLines([line]);
  }

  function appendMapLog(lines) {
    if (!mapModeLog || !Array.isArray(lines) || !lines.length) return;
    const cleaned = lines.filter((line) => String(line || "").trim() !== "").slice(-8);
    cleaned.forEach((line) => {
      const row = document.createElement("div");
      row.className = "map-mode-log-line";
      row.textContent = line;
      mapModeLog.appendChild(row);
      setTimeout(() => row.classList.add("faded"), 5000);
    });
    while (mapModeLog.children.length > 16) {
      mapModeLog.removeChild(mapModeLog.firstChild);
    }
    mapModeLog.scrollTop = mapModeLog.scrollHeight;
  }

  function renderLiveLine() {
    if (!state.inputEnabled || state.mapMode) return;
    const last = state.buffer.at(-1);
    if (last?.startsWith("> ")) state.buffer.pop();
    const cursor = state.cursorVisible && !state.typingActive ? "_" : "";
    state.buffer.push(`> ${state.liveInput}${cursor}`);
    render();
  }

  setInterval(() => {
    if (!state.inputEnabled || state.mapMode) return;
    state.cursorVisible = !state.cursorVisible;
    renderLiveLine();
  }, CURSOR_IDLE_MS);

  inputField.addEventListener("input", () => {
    if (!state.inputEnabled) return;
    playKeyClick();
    state.typingActive = true;
    state.liveInput = inputField.value.toUpperCase();
    if (inputField.value !== state.liveInput) inputField.value = state.liveInput;
    resetCompletionState();
    renderLiveLine();

    clearTimeout(state._typingTimer);
    state._typingTimer = setTimeout(() => {
      state.typingActive = false;
    }, 220);
  });

  function setInputEnabled(enabled) {
    state.inputEnabled = enabled;
    inputField.disabled = !enabled;
    inputForm.classList.toggle("disabled", !enabled);
    if (enabled && !state.mapMode) {
      inputField.focus();
      state.cursorVisible = true;
      renderLiveLine();
      primeHint();
    } else {
      state.cursorVisible = false;
    }
  }

  function focusInputIfEnabled() {
    if (!state.inputEnabled || state.mapMode) return;
    state.hintFocusIntent = true;
    inputField.focus();
    startFocusedHintSequence();
  }

  async function submitCommand(command) {
    const commandId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    const res = await fetch("/command", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ raw: command, command_id: commandId }),
    });
    const payload = await res.json();
    return { ok: Boolean(payload.ok), lines: Array.isArray(payload.lines) ? payload.lines : [] };
  }

  async function fetchSnapshot() {
    return fetch("/snapshot").then((r) => r.json());
  }

  function shouldRefreshSnapshot(command, ok) {
    if (!ok) return false;
    const verb = command.trim().toUpperCase().split(/\s+/)[0];
    return ["STATUS", "WAIT", "RESET", "REBOOT", "SET", "FAB", "CONFIG", "ALLOCATE", "FOCUS", "HARDEN", "SCAVENGE", "REPAIR", "DEPLOY", "MOVE", "RETURN"].includes(verb);
  }

  function setLiveSummary(text) {
    if (liveRegion) liveRegion.textContent = text;
  }

  function setOfflineBanner(visible) {
    offlineBanner?.classList.toggle("visible", visible);
  }

  function updateCommsPresentation(snapshot) {
    const comms = snapshot.sectors?.find((s) => s.id === "CM");
    const status = comms?.status || "STABLE";
    terminalContainer.classList.toggle("comms-alert", status === "ALERT");
    terminalContainer.classList.toggle("comms-damaged", status === "DAMAGED");
    terminalContainer.classList.toggle("comms-compromised", status === "COMPROMISED");
  }

  async function refreshSnapshot() {
    if (!window.CustodianSectorMap) return;
    try {
      const snapshot = await fetchSnapshot();
      window.CustodianSectorMap.renderSectorMap(snapshot);
      window.CustodianSectorMap.renderOverviewMap(snapshot, "map-mode-map", true);
      updateCommsPresentation(snapshot);
      if (!state.mapHintShown) {
        appendLine("[MAP UPDATED]");
        state.mapHintShown = true;
      }
    } catch {}
  }

  async function executeCommandFlow(cmd, options = {}) {
    const { echo = true, mapFeed = false, appendHelpShortcut = false } = options;
    if (!cmd) return;

    if (echo) appendLine(`> ${cmd.toUpperCase()}`);
    try {
      const result = await submitCommand(cmd);
      state.failureCount = 0;
      setOfflineBanner(false);
      appendLines(result.lines);
      if (mapFeed) appendMapLog(result.lines);
      if (appendHelpShortcut) appendLines(["UI SHORTCUTS: TAB COMPLETE | UP/DOWN HISTORY | ESC CLEAR | CTRL+L CLEAR SCREEN"]);
      setLiveSummary(result.ok ? "Command executed." : "Command failed.");
      if (shouldRefreshSnapshot(cmd, result.ok)) await refreshSnapshot();
    } catch {
      state.failureCount += 1;
      if (state.failureCount >= 3) setOfflineBanner(true);
      const failLines = ["COMMAND LINK FAILED.", "VERIFY SERVER AND RETRY."];
      appendLines(failLines);
      if (mapFeed) appendMapLog(failLines);
      setLiveSummary("Command link failed.");
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!state.inputEnabled || state.mapMode) return;

    const cmd = inputField.value.trim();
    if (!cmd) return;

    lockHints();
    if (state.buffer.at(-1)?.startsWith("> ")) state.buffer.pop();

    state.history.push(cmd.toUpperCase());
    state.historyIndex = state.history.length;
    inputField.value = "";
    state.liveInput = "";
    state.cursorVisible = false;
    setInputEnabled(false);

    await executeCommandFlow(cmd, {
      echo: true,
      mapFeed: false,
      appendHelpShortcut: cmd.trim().toUpperCase() === "HELP",
    });

    setInputEnabled(true);
  }

  function stopMapAutoWait() {
    if (!state.mapAutoTimer) return;
    clearInterval(state.mapAutoTimer);
    state.mapAutoTimer = null;
  }

  function startMapAutoWait() {
    stopMapAutoWait();
    state.mapAutoTimer = setInterval(async () => {
      if (!state.mapMode || state.mapAutoBusy) return;
      state.mapAutoBusy = true;
      await executeCommandFlow("WAIT", { echo: false, mapFeed: true, appendHelpShortcut: false });
      state.mapAutoBusy = false;
    }, MAP_AUTOWAIT_MS);
  }

  function setMapMode(enabled) {
    state.mapMode = enabled;
    appShell?.classList.toggle("map-mode", enabled);
    mapModePanel?.classList.toggle("hidden", !enabled);
    if (modeLabel) modeLabel.textContent = enabled ? "MODE: MAP MONITOR" : "MODE: COMMAND";
    if (mapModeToggle) mapModeToggle.textContent = enabled ? "RETURN TO COMMAND" : "ENTER MAP MODE";

    if (enabled) {
      setInputEnabled(false);
      appendMapLog(["MAP MONITOR ACTIVE", "AUTO-WAIT LOOP ENGAGED (2S CADENCE)"]);
      startMapAutoWait();
      refreshSnapshot();
    } else {
      stopMapAutoWait();
      setInputEnabled(true);
    }
  }

  function startCommandMode() {
    appendLines(["", "--- COMMAND INTERFACE ACTIVE ---", "Awaiting directives."]);
    setInputEnabled(true);
    primeHint();
    refreshSnapshot();
  }

  inputForm.addEventListener("submit", handleSubmit);
  mapModeToggle?.addEventListener("click", () => setMapMode(!state.mapMode));
  outputIndicator?.addEventListener("click", () => {
    terminal.scrollTop = terminal.scrollHeight;
    state.userAtBottom = true;
    outputIndicator.classList.remove("visible");
    focusInputIfEnabled();
  });
  inputFocusZone?.addEventListener("click", focusInputIfEnabled);
  inputField.addEventListener("mousedown", () => {
    state.hintFocusIntent = true;
  });
  inputField.addEventListener("focus", startFocusedHintSequence);
  terminalContainer.addEventListener("click", (e) => {
    if (e.target === terminal || e.target === terminalContainer) {
      focusInputIfEnabled();
    }
  });

  inputField.addEventListener("keydown", (e) => {
    if (!state.inputEnabled || state.mapMode) return;
    if (e.key === "Tab") {
      e.preventDefault();
      if (autocompleteInput(e.shiftKey)) playKeyClick();
      return;
    }
    if (e.key === "Escape") {
      e.preventDefault();
      applyInputValue("");
      resetCompletionState();
      return;
    }
    if (e.ctrlKey && e.key.toLowerCase() === "l") {
      e.preventDefault();
      clearBuffer();
      renderLiveLine();
      return;
    }
    if (e.key === "ArrowUp") {
      e.preventDefault();
      if (!state.history.length) return;
      state.historyIndex = Math.max(0, state.historyIndex - 1);
      applyInputValue(state.history[state.historyIndex] || "");
      resetCompletionState();
      return;
    }
    if (e.key === "ArrowDown") {
      e.preventDefault();
      if (!state.history.length) return;
      state.historyIndex = Math.min(state.history.length, state.historyIndex + 1);
      applyInputValue(state.history[state.historyIndex] || "");
      resetCompletionState();
    }
  });

  terminal.addEventListener("scroll", () => {
    const atBottom = isAtBottom(terminal, SCROLL_THRESHOLD);
    state.userAtBottom = atBottom;
    if (atBottom) outputIndicator?.classList.remove("visible");
  });

  window.CustodianTerminal = {
    appendLine,
    appendLines,
    clearBuffer,
    setInputEnabled,
    startCommandMode,
    setMapMode,
  };
})();
