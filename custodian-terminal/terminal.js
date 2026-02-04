(() => {
  const terminal = document.getElementById("terminal");
  const inputForm = document.getElementById("terminal-input-form");
  const inputField = document.getElementById("terminal-input");

  const state = {
    buffer: [],
    inputEnabled: false,
  };

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
   * Handle submitted commands and echo them back.
   * @param {SubmitEvent} event
   * @returns {void}
   */
  function handleSubmit(event) {
    event.preventDefault();
    if (!state.inputEnabled) {
      return;
    }

    const command = inputField.value.trim();
    if (!command) {
      return;
    }

    appendLine(`> ${command}`);
    appendLine(`ECHO: ${command}`);
    inputField.value = "";
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

  inputForm.addEventListener("submit", handleSubmit);
  setInputEnabled(false);

  // TODO: Add automated UI tests for terminal input and echo once a JS harness exists.
  window.CustodianTerminal = {
    appendLine,
    appendLines,
    setInputEnabled,
    startCommandMode,
    syncBufferFromDom,
  };
})();
