(() => {
  const terminal = document.getElementById("terminal");
  const inputForm = document.getElementById("terminal-input-form");
  const inputField = document.getElementById("terminal-input");

  const state = {
    buffer: [],
    inputEnabled: false,
  };

  const tutorialFeedLines = [
    "",
    "--- TUTORIAL FEED ---",
    "STATUS: View current situation.",
    "WAIT: Advance time by one tick.",
    "HELP: Review available commands.",
    "",
    "--- END FEED ---",
  ];

  /**
   * Rebuild the output buffer from the current terminal text.
   * @returns {void}
   */
  function syncBufferFromDom() {
    const rawText = terminal.textContent;
    state.buffer = rawText ? rawText.split("\n") : [];
  }

  /**
   * Render the buffer to the terminal display.
   * @returns {void}
   */
  function render() {
    terminal.textContent = state.buffer.join("\n");
    terminal.scrollTop = terminal.scrollHeight;
  }

  /**
   * Append a single line to the output buffer.
   * @param {string} line
   * @returns {void}
   */
  function appendLine(line) {
    state.buffer.push(line);
    render();
  }

  /**
   * Append multiple lines to the output buffer.
   * @param {string[]} lines
   * @returns {void}
   */
  function appendLines(lines) {
    lines.forEach((line) => appendLine(line));
  }

  /**
   * Pause for a set duration.
   * @param {number} ms
   * @returns {Promise<void>}
   */
  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Enable or disable terminal input.
   * @param {boolean} enabled
   * @returns {void}
   */
  function setInputEnabled(enabled) {
    state.inputEnabled = enabled;
    inputField.disabled = !enabled;
    inputForm.classList.toggle("disabled", !enabled);
    if (enabled) {
      inputField.focus();
    }
  }

  /**
   * Submit a command to the backend command endpoint.
   * @param {string} raw
   * @returns {Promise<{ok: boolean, lines: string[]}>}
   */
  async function submitCommand(raw) {
    const response = await fetch("/command", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ raw }),
    });

    const payload = await response.json();
    return {
      ok: Boolean(payload.ok),
      lines: Array.isArray(payload.lines) ? payload.lines : [],
    };
  }

  /**
   * Handle submitted commands and display backend responses.
   * @param {SubmitEvent} event
   * @returns {Promise<void>}
   */
  async function handleSubmit(event) {
    event.preventDefault();
    if (!state.inputEnabled) {
      return;
    }

    const command = inputField.value.trim();
    if (!command) {
      return;
    }

    appendLine(`> ${command.toUpperCase()}`);
    inputField.value = "";

    setInputEnabled(false);
    try {
      const result = await submitCommand(command);
      appendLines(result.lines);
    } catch (_error) {
      appendLines([
        "COMMAND LINK FAILED.",
        "VERIFY SERVER AND RETRY.",
      ]);
    } finally {
      setInputEnabled(true);
    }
  }

  /**
   * Play the scripted tutorial feed before unlocking input.
   * @returns {Promise<void>}
   */
  async function runTutorialFeed() {
    setInputEnabled(false);
    for (const line of tutorialFeedLines) {
      appendLine(line);
      await sleep(350);
    }
  }

  /**
   * Switch the terminal into command mode.
   * @returns {void}
   */
  function startCommandMode() {
    appendLines([
      "",
      "--- COMMAND INTERFACE ACTIVE ---",
      "Awaiting directives.",
      "",
    ]);
    setInputEnabled(true);
  }

  inputForm.addEventListener("submit", (event) => {
    handleSubmit(event);
  });
  setInputEnabled(false);

  window.CustodianTerminal = {
    appendLine,
    appendLines,
    setInputEnabled,
    startCommandMode,
    runTutorialFeed,
    syncBufferFromDom,
  };
})();
