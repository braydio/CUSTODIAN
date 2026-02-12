
(() => {
  const terminal = document.getElementById("terminal");
  const terminalContainer = document.getElementById("terminal-container");
  const inputForm = document.getElementById("terminal-input-form");
  const inputField = document.getElementById("terminal-input");
  const outputIndicator = document.getElementById("new-output-indicator");
  const idleTip = document.getElementById("idle-tip");

  const keyClick = document.getElementById("keyClick");

  const state = {
    buffer: [],
    inputEnabled: false,
    cursorVisible: false,
    liveInput: "",
    typingActive: false,
    mapHintShown: false,
    userAtBottom: true,
    idleTimer: null,
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

  function scheduleIdleTip() {
    console.log("[TERMINAL] scheduleIdleTip")
    if (!state.inputEnabled) return;
    if (state.idleTimer) clearTimeout(state.idleTimer);
    idleTip?.classList.remove("visible");
    state.idleTimer = setTimeout(() => {
      if (state.inputEnabled) idleTip?.classList.add("visible");
    }, IDLE_TIP_MS);
  }

  function hideIdleTip() {
    if (state.idleTimer) clearTimeout(state.idleTimer);
    idleTip?.classList.remove("visible");
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
    scheduleIdleTip();

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
      scheduleIdleTip();
    } else {
      state.cursorVisible = false;
      hideIdleTip();
    }
  }

  async function submitCommand(command) {
    const res = await fetch("/command", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ raw: command }),
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

    hideIdleTip();
    if (state.buffer.at(-1)?.startsWith("> ")) state.buffer.pop();

    appendLine(`> ${cmd.toUpperCase()}`);
    inputField.value = "";
    state.liveInput = "";
    state.cursorVisible = false;
    setInputEnabled(false);

    try {
      const result = await submitCommand(cmd);
      appendLines(result.lines);
      if (shouldRefreshSnapshot(cmd, result.ok)) await refreshSnapshot();
    } catch {
      appendLines(["COMMAND LINK FAILED.", "VERIFY SERVER AND RETRY."]);
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
    scheduleIdleTip();
  }


  inputForm.addEventListener("submit", handleSubmit);
  inputField.addEventListener("keydown", () => {
    if (state.inputEnabled) scheduleIdleTip();
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
