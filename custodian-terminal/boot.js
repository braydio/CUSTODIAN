const terminal = document.getElementById("terminal");

const hum = document.getElementById("hum");
const relay = document.getElementById("relay");
const alertSound = document.getElementById("alert");

hum.volume = 0.15;
hum.play().catch(() => {
  // Browser requires user interaction.
});

const bootLines = [
  "[ SYSTEM POWER: UNSTABLE ]",
  "[ AUXILIARY POWER ROUTED ]",
  "",
  "CUSTODIAN NODE - ONLINE",
  "STATUS: DEGRADED",
  "",
  "> Running integrity check...",
  "> Memory blocks: 12% intact",
  "> Long-range comms: OFFLINE",
  "> Archive uplink: OFFLINE",
  "> Automated defense grid: PARTIAL",
  "",
  "DIRECTIVE FOUND",
  "RETENTION MANDATE - ACTIVE",
  "",
  "WARNING:",
  "Issuing authority presumed defunct.",
  "",
  "Residual Authority accepted.",
  "",
  "Initializing Custodian interface...",
];

const terminalController = window.CustodianTerminal;

/**
 * Pause for a set duration.
 * @param {number} ms
 * @returns {Promise<void>}
 */
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Type out a single boot line to the terminal.
 * @param {string} text
 * @returns {Promise<void>}
 */
function typeLine(text) {
  return new Promise((resolve) => {
    let i = 0;

    relay.currentTime = 0;
    relay.volume = 0.25;
    relay.play().catch(() => {});

    if (text.includes("WARNING")) {
      alertSound.volume = 0.4;
      alertSound.play().catch(() => {});
    }

    const interval = setInterval(() => {
      terminal.textContent += text[i] || "";
      i += 1;

      if (i >= text.length) {
        clearInterval(interval);
        terminal.textContent += "\n";
        terminal.scrollTop = terminal.scrollHeight;
        resolve();
      }
    }, 18 + Math.random() * 25);
  });
}

/**
 * Play the boot sequence before handing off to command mode.
 * @returns {Promise<void>}
 */
async function runBoot() {
  terminalController.setInputEnabled(false);

  for (const line of bootLines) {
    await typeLine(line);
    terminal.classList.add("flicker");
    setTimeout(() => terminal.classList.remove("flicker"), 120);
    await sleep(200 + Math.random() * 300);
  }

  await sleep(800);
  terminalController.syncBufferFromDom();
  await terminalController.runSystemLog();
  terminalController.startCommandMode();
}

runBoot();
