(() => {
  const terminal = document.getElementById("terminal");
  const inputForm = document.getElementById("terminal-input-form");
  const inputField = document.getElementById("terminal-input");

  const state = {
    buffer: [],
    inputEnabled: false,
    cursorVisible: false,
    liveInput: "",
    typingActive: false,
    mapHintShown: false,
  };

  const CURSOR_IDLE_MS = 420;

  const systemLogLines = [
    "",
    "--- SYSTEM LOG ---",
    "Residual command index recovered.",
    "Directive access granted.",
    "",
    "AVAILABLE DIRECTIVES:",
    "- STATUS",
    "- WAIT",
    "- WAIT 10X",
    "- FOCUS",
    "- HELP",
    "",
  ];

  function syncBufferFromDom() {
    state.buffer = terminal.textContent
      ? terminal.textContent.split("\n")
      : [];
  }

  function render() {
    terminal.textContent = state.buffer.join("\n");
    terminal.scrollTop = terminal.scrollHeight;
  }

  function appendLine(line) {
    state.buffer.push(line);
    render();
  }

  function appendLines(lines) {
    lines.forEach(appendLine);
  }

  function renderLiveLine() {
    if (!state.inputEnabled) return;
    const last = state.buffer[state.buffer.length - 1];
    if (last && last.startsWith("> ")) state.buffer.pop();
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
    state.typingActive = true;
    state.liveInput = inputField.value.toUpperCase();
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
    if (enabled) {
      inputField.focus();
      state.cursorVisible = true;
      renderLiveLine();
    } else {
      state.cursorVisible = false;
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
    const res = await fetch("/snapshot");
    return res.json();
  }

  function shouldRefreshMap(command, ok) {
    if (!ok) return false;
    const normalized = command.trim().toUpperCase();
    if (!normalized) return false;
    const verb = normalized.split(/\s+/)[0];
    return verb === "WAIT" || verb === "RESET" || verb === "REBOOT";
  }

  async function refreshMap() {
    if (!window.CustodianSectorMap) return;
    try {
      const snapshot = await fetchSnapshot();
      window.CustodianSectorMap.renderSectorMap(snapshot);
      if (!state.mapHintShown) {
        appendLine("[MAP UPDATED]");
        state.mapHintShown = true;
      }
    } catch {
      // Map projection failures should not block terminal flow.
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!state.inputEnabled) return;

    const cmd = inputField.value.trim();
    if (!cmd) return;

    const last = state.buffer[state.buffer.length - 1];
    if (last && last.startsWith("> ")) state.buffer.pop();

    appendLine(`> ${cmd.toUpperCase()}`);
    inputField.value = "";
    state.liveInput = "";
    state.cursorVisible = false;
    setInputEnabled(false);

    try {
      const result = await submitCommand(cmd);
      appendLines(result.lines);
      if (shouldRefreshMap(cmd, result.ok)) {
        await refreshMap();
      }
    } catch {
      appendLines(["COMMAND LINK FAILED.", "VERIFY SERVER AND RETRY."]);
    } finally {
      setInputEnabled(true);
    }
  }

  async function runSystemLog() {
    setInputEnabled(false);
    for (const line of systemLogLines) {
      appendLine(line);
      await new Promise((r) => setTimeout(r, 350));
    }
  }

  function startCommandMode() {
    appendLines([
      "",
      "--- COMMAND INTERFACE ACTIVE ---",
      "Awaiting directives.",
      "",
    ]);
    setInputEnabled(true);
  }

  inputForm.addEventListener("submit", handleSubmit);
  setInputEnabled(false);

  window.CustodianTerminal = {
    appendLine,
    appendLines,
    setInputEnabled,
    startCommandMode,
    runSystemLog,
    syncBufferFromDom,
  };
})();
