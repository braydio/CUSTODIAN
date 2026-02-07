const terminal = document.getElementById("terminal");

const hum = document.getElementById("hum");
const relay = document.getElementById("relay");
const beep = document.getElementById("beep");
const alertSound = document.getElementById("alert");

const terminalController = window.CustodianTerminal;

/* =========================
   Audio: policy-safe init
   ========================= */

let audioReady = false;

function tryStartHum() {
  hum.volume = 0.15;
  hum.play().then(() => {
    audioReady = true;
  }).catch(() => {});
}

tryStartHum();

function unlockAudioOnce() {
  if (audioReady) return;
  tryStartHum();
  [relay, beep, alertSound].forEach((el) => {
    try {
      el.volume = 0.0;
      el.currentTime = 0;
      el.play().then(() => el.pause()).catch(() => {});
    } catch {}
  });
  audioReady = true;
  window.removeEventListener("pointerdown", unlockAudioOnce);
  window.removeEventListener("keydown", unlockAudioOnce);
}
window.addEventListener("pointerdown", unlockAudioOnce, { once: true });
window.addEventListener("keydown", unlockAudioOnce, { once: true });

/* =========================
   Audio: one-shot helper
   ========================= */

function playOneShot(el, { volume = 0.2, rateJitter = 0.03 } = {}) {
  if (!el) return;
  const a = el.cloneNode(true);
  a.volume = volume;
  a.playbackRate = 1 + (Math.random() * 2 - 1) * rateJitter;
  a.play().catch(() => {});
}

function isWarningLine(text) {
  const t = text.toUpperCase();
  return (
    t.includes("WARNING") ||
    t.includes("ALERT") ||
    t.includes("DEGRADED") ||
    t.includes("OFFLINE") ||
    t.includes("UNSTABLE")
  );
}

function isSystemNoiseLine(text) {
  const t = text.toUpperCase();
  return t.startsWith("[") || t.startsWith(">") || t.includes("STATUS");
}

/* =========================
   Boot text
   ========================= */

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

/**
 * Pause for a set duration.
 * @param {number} ms
 * @returns {Promise<void>}
 */
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Type out a single boot line to the terminal, with realistic audio cadence.
 * @param {string} text
 * @returns {Promise<void>}
 */
function typeLine(text) {
  return new Promise((resolve) => {
    let i = 0;

    if (text && isWarningLine(text)) {
      playOneShot(alertSound, { volume: 0.35, rateJitter: 0.02 });
      hum.volume = 0.18;
      setTimeout(() => (hum.volume = 0.15), 500);
    } else if (text && isSystemNoiseLine(text) && Math.random() < 0.35) {
      playOneShot(beep, { volume: 0.08, rateJitter: 0.02 });
    }

    let charsUntilClick = 1 + Math.floor(Math.random() * 4);
    const baseDelay = 16 + Math.random() * 18;

    const interval = setInterval(() => {
      const ch = text[i] || "";
      terminal.textContent += ch;
      i += 1;

      if (ch && ch !== " " && ch !== "\n") {
        charsUntilClick -= 1;
        if (charsUntilClick <= 0) {
          playOneShot(relay, { volume: 0.12, rateJitter: 0.05 });
          charsUntilClick = 2 + Math.floor(Math.random() * 5);
        }
      }

      if (i >= text.length) {
        clearInterval(interval);

        if (text && Math.random() < 0.25) {
          playOneShot(relay, { volume: 0.18, rateJitter: 0.03 });
        }

        terminal.textContent += "\n";
        terminal.scrollTop = terminal.scrollHeight;
        resolve();
      }
    }, baseDelay + Math.random() * 22);
  });
}

function appendStreamedLine(text) {
  if (text && isWarningLine(text)) {
    playOneShot(alertSound, { volume: 0.35, rateJitter: 0.02 });
    hum.volume = 0.18;
    setTimeout(() => (hum.volume = 0.15), 500);
  } else if (text && isSystemNoiseLine(text) && Math.random() < 0.35) {
    playOneShot(beep, { volume: 0.08, rateJitter: 0.02 });
  }
  terminalController.appendLine(text);
  terminal.classList.add("flicker");
  setTimeout(() => terminal.classList.remove("flicker"), 120);
}

/**
 * Stream boot lines from the server if available.
 * @returns {Promise<boolean>}
 */
function streamBootFromServer() {
  return new Promise((resolve) => {
    let hasData = false;
    let done = false;

    const source = new EventSource("/stream/boot");

    source.onmessage = (event) => {
      hasData = true;
      appendStreamedLine(event.data);
    };

    source.addEventListener("done", () => {
      done = true;
      source.close();
      resolve(true);
    });

    source.onerror = () => {
      if (!hasData && !done) {
        source.close();
        resolve(false);
      }
    };

    setTimeout(() => {
      if (!hasData && !done) {
        source.close();
        resolve(false);
      }
    }, 800);
  });
}

/**
 * Boot sequence before handing off to command mode.
 * @returns {Promise<void>}
 */
async function runBoot() {
  terminalController.setInputEnabled(false);

  const streamed = await streamBootFromServer();
  if (!streamed) {
    for (const line of bootLines) {
      await typeLine(line);
      terminal.classList.add("flicker");
      setTimeout(() => terminal.classList.remove("flicker"), 120);
      await sleep(180 + Math.random() * 280);
    }
  }

  await sleep(700);
  terminalController.syncBufferFromDom();
  await terminalController.runSystemLog();

  playOneShot(beep, { volume: 0.09, rateJitter: 0.01 });

  terminalController.startCommandMode();
}

runBoot();
