
(() => {
  const terminal = document.getElementById("terminal");
  const terminalContainer = document.getElementById("terminal-container");
  const inputForm = document.getElementById("terminal-input-form");
  const inputField = document.getElementById("terminal-input");
  const outputIndicator = document.getElementById("new-output-indicator");
  const idleTip = document.getElementById("idle-tip");
  const liveRegion = document.getElementById("terminal-live");
  const offlineBanner = document.getElementById("offline-banner");
  const inputFocusZone = document.getElementById("input-focus-zone");

  const keyClick = document.getElementById("keyClick");

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
  };

  const CURSOR_IDLE_MS = 420;
  const SCROLL_THRESHOLD = 8;
  const IDLE_TIP_MS = 5000;

  let lastKeyClickAt = 0;
  const KEY_CLICK_MIN_INTERVAL = 28;

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

  function syncBufferFromDom() {
    state.buffer = terminal.textContent
      ? terminal.textContent.split("\n")
      : [];
  }

  function escapeHtml(text) {
    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  function classifyLine(line) {
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
    if (line.startsWith("[ASSAULT]") || line.startsWith("=== ASSAULT")) {
      return "assault";
    }
    if (line.startsWith("[FOCUS SET]") || line.startsWith("[HARDENING")) {
      return "intent";
    }
    return "";
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
    const isAssault = (line) =>
      line.startsWith("[ASSAULT]") || line.startsWith("=== ASSAULT");

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
      showSecondary
        ? '<span class="hint-sep">|</span><span class="hint-secondary">TYPE HELP FOR AVAILABLE COMMANDS</span>'
        : ""
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
    if (!state.hintFocusIntent) return;
    if (state.hintLocked || state.hintFocusStarted) return;
    state.hintFocusStarted = true;
    renderHint(true, false);
    if (state.hintTimer) clearTimeout(state.hintTimer);
    state.hintTimer = setTimeout(() => {
      if (state.hintLocked || state.hintSecondaryShown) return;
      if (!state.inputEnabled) return;
      if (document.activeElement !== inputField) return;
      if (state.liveInput.trim() !== "") return;
      state.hintSecondaryShown = true;
      renderHint(true, true);
    }, IDLE_TIP_MS);
  }

  function clearBuffer() {
    state.buffer = [];
    render();
  }

  function appendLine(line) {
    appendLines([line]);
  }

  function appendLines(lines) {
    const lastLine = state.buffer.at(-1);
    state.buffer.push(...normalizeAssaultSpacing(lines, lastLine));
    render();
    if (!state.userAtBottom) outputIndicator?.classList.add("visible");
  }

  function renderLiveLine() {
    if (!state.inputEnabled) return;
    const last = state.buffer.at(-1);
    if (last?.startsWith("> ")) state.buffer.pop();
    const cursor = state.cursorVisible && !state.typingActive ? "_" : "";
    state.buffer.push(`> ${state.liveInput}${cursor}`);
    render();
  }

  setInterval(() => {
    if (!state.inputEnabled) return;
    state.cursorVisible = !state.cursorVisible;
    renderLiveLine();
  }, CURSOR_IDLE_MS);

  inputField.addEventListener("input", () => {
    if (!state.inputEnabled) return;
    playKeyClick();

    state.typingActive = true;
    state.liveInput = inputField.value.toUpperCase();
    renderLiveLine();
    if (state.liveInput.trim() !== "" && state.hintTimer) {
      clearTimeout(state.hintTimer);
    }

    clearTimeout(state._typingTimer);
    state._typingTimer = setTimeout(() => {
      state.typingActive = false;
    }, 220);
  });

  inputField.addEventListener("keydown", (e) => {
    if (!state.inputEnabled) return;
    if (e.key.length === 1 || e.key === "Backspace" || e.key === "Enter") {
      playKeyClick();
    }
  });

  function setInputEnabled(enabled) {
    console.log("[TERMINAL] setInputEnabled:", enabled);
    state.inputEnabled = enabled;
    inputField.disabled = !enabled;
    inputForm.classList.toggle("disabled", !enabled);
    if (enabled) {
      inputField.focus();
      state.cursorVisible = true;
      renderLiveLine();
      primeHint();
    } else {
      state.cursorVisible = false;
    }
  }

  function focusInputIfEnabled() {
    if (!state.inputEnabled) return;
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
    return {
      ok: Boolean(payload.ok),
      lines: Array.isArray(payload.lines) ? payload.lines : [],
    };
  }

  async function fetchSnapshot() {
    return fetch("/snapshot").then((r) => r.json());
  }

  function shouldRefreshSnapshot(command, ok) {
    if (!ok) return false;
    const verb = command.trim().toUpperCase().split(/\s+/)[0];
    return [
      "WAIT",
      "RESET",
      "REBOOT",
      "FOCUS",
      "HARDEN",
      "SCAVENGE",
      "REPAIR",
      "DEPLOY",
      "MOVE",
      "RETURN",
    ].includes(verb);
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
      updateCommsPresentation(snapshot);
      if (!state.mapHintShown) {
        appendLine("[MAP UPDATED]");
        state.mapHintShown = true;
      }
    } catch {}
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!state.inputEnabled) return;

    const cmd = inputField.value.trim();
    if (!cmd) return;

    lockHints();
    if (state.buffer.at(-1)?.startsWith("> ")) state.buffer.pop();

    state.history.push(cmd.toUpperCase());
    state.historyIndex = state.history.length;

    appendLine(`> ${cmd.toUpperCase()}`);
    inputField.value = "";
    state.liveInput = "";
    state.cursorVisible = false;
    setInputEnabled(false);

    try {
      const result = await submitCommand(cmd);
      state.failureCount = 0;
      setOfflineBanner(false);
      appendLines(result.lines);
      setLiveSummary(result.ok ? "Command executed." : "Command failed.");
      if (shouldRefreshSnapshot(cmd, result.ok)) await refreshSnapshot();
    } catch {
      state.failureCount += 1;
      if (state.failureCount >= 3) setOfflineBanner(true);
      appendLines(["COMMAND LINK FAILED.", "VERIFY SERVER AND RETRY."]);
      setLiveSummary("Command link failed.");
    } finally {
      setInputEnabled(true);
    }
  }

  
  function startCommandMode() {
    console.log("[TERMINAL] startCommandMode()")
    appendLines([
      "",
      "--- COMMAND INTERFACE ACTIVE ---",
      "Awaiting directives.",
    ]);

    setInputEnabled(true);
    console.log("[ TERMINAL ] enabling input");
    primeHint();
  }


  inputForm.addEventListener("submit", handleSubmit);
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
    if (!state.inputEnabled) return;
    if (e.key === "ArrowUp") {
      e.preventDefault();
      if (!state.history.length) return;
      state.historyIndex = Math.max(0, state.historyIndex - 1);
      inputField.value = state.history[state.historyIndex] || "";
      state.liveInput = inputField.value;
      renderLiveLine();
      return;
    }
    if (e.key === "ArrowDown") {
      e.preventDefault();
      if (!state.history.length) return;
      state.historyIndex = Math.min(state.history.length, state.historyIndex + 1);
      inputField.value = state.history[state.historyIndex] || "";
      state.liveInput = inputField.value;
      renderLiveLine();
    }
  });
  terminal.addEventListener("scroll", () => {
    const atBottom =
      terminal.scrollTop + terminal.clientHeight >=
      terminal.scrollHeight - SCROLL_THRESHOLD;
    state.userAtBottom = atBottom;
    if (atBottom) outputIndicator?.classList.remove("visible");
  });

  window.CustodianTerminal = {
    appendLine,
    appendLines,
    clearBuffer,
    setInputEnabled,
    startCommandMode,
    syncBufferFromDom,
  };
})();
