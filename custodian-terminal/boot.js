const terminal = document.getElementById("terminal");

const hum = document.getElementById("hum");
const relay = document.getElementById("relay");
const beep = document.getElementById("beep");
const timingRelay = document.getElementById("timingRelay");
const fourBeep = document.getElementById("fourBeep");
const hddSpin = document.getElementById("hddSpin");
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
  [relay, timingRelay, fourBeep, hddSpin, beep, alertSound].forEach((el) => {
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

function playOneShot(el, { volume = 0.2, rateJitter = 0.03, restart = true } = {}) {
  if (!el) return;
  const a = el.cloneNode(true);
  a.volume = volume;
  a.playbackRate = 1 + (Math.random() * 2 - 1) * rateJitter;
  if (restart) {
    a.currentTime = 0;
  }
  a.play().catch(() => {});
}

let alertPulseCooldown = 0;

function playSingleShot(el, { volume = 0.2, rate = 1.0 } = {}) {
  if (!el) return;
  el.volume = volume;
  try {
    el.currentTime = 0;
    el.playbackRate = rate;
    el.play().catch(() => {});
  } catch {}
}

function fadeOut(el, startMs, endMs, startVolume) {
  const start = performance.now() + startMs;
  const end = performance.now() + endMs;
  const initial = typeof startVolume === "number" ? startVolume : el.volume || 0.2;

  function tick(now) {
    if (now < start) {
      requestAnimationFrame(tick);
      return;
    }
    const t = Math.min(1, (now - start) / (end - start));
    el.volume = Math.max(0, initial * (1 - t));
    if (t < 1) {
      requestAnimationFrame(tick);
    }
  }

  requestAnimationFrame(tick);
}

function playRelaySequence() {
  if (timingRelay) {
    playSingleShot(timingRelay, { volume: 0.18 });
    fadeOut(timingRelay, 2000, 5000, 0.18);
  }
  if (fourBeep) {
    setTimeout(() => {
      playSingleShot(fourBeep, { volume: 0.18 });
    }, 1000);
  }
}

function playHddSpinOnce() {
  if (!hddSpin) return;
  hddSpin.loop = false;
  hddSpin.volume = 0.12;
  hddSpin.currentTime = 0;
  hddSpin.play().catch(() => {});
  fadeOut(hddSpin, 8000, 14000, 0.12);
}

function playAlertPulse() {
  const now = performance.now();
  if (now < alertPulseCooldown) return;
  const pulseRate = 1.0;
  const timings = [0, 1500, 3000].map((t) => t / pulseRate);
  alertPulseCooldown = now + 3600 / pulseRate;
  const sequence = [
    { el: alertSound, delay: timings[0], volume: 0.2, rate: 1.0 },
    { el: alertSound, delay: timings[1], volume: 0.18, rate: 1.0 },
    { el: alertSound, delay: timings[2], volume: 0.18, rate: 1.0 },
  ];
  sequence.forEach(({ el, delay, volume, rate }) => {
    setTimeout(() => {
      playSingleShot(el || alertSound, { volume, rate });
    }, delay);
  });
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

function isDirectiveLine(text) {
  const t = text.toUpperCase();
  return t.includes("DIRECTIVE") || t.includes("MANDATE") || t.includes("AUTHORITY");
}

function linePauseMs(text) {
  if (!text) {
    return 320 + Math.random() * 420;
  }
  if (isWarningLine(text)) {
    return 520 + Math.random() * 520;
  }
  if (isDirectiveLine(text)) {
    return 380 + Math.random() * 420;
  }
  if (isSystemNoiseLine(text)) {
    return 240 + Math.random() * 320;
  }
  return 200 + Math.random() * 280;
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
  "> Archive uplink: INACCESSIBLE",
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
      playAlertPulse();
      hum.volume = 0.18;
      setTimeout(() => (hum.volume = 0.15), 500);
    } else if (text && isSystemNoiseLine(text) && Math.random() < 0.35) {
      playOneShot(beep, { volume: 0.08, rateJitter: 0.02 });
    }

    const baseDelay = 22 + Math.random() * 32;

    const interval = setInterval(() => {
      const ch = text[i] || "";
      terminal.textContent += ch;
      i += 1;

      if (i >= text.length) {
        clearInterval(interval);

        if (text && Math.random() < 0.35) {
          playOneShot(relay, { volume: 0.14, rateJitter: 0.03 });
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
    playAlertPulse();
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

  playOneShot(relay, { volume: 0.2, rateJitter: 0.04 });
  playRelaySequence();
  await sleep(420);

  const streamed = await streamBootFromServer();
  if (!streamed) {
    for (const line of bootLines) {
      await typeLine(line);
      terminal.classList.add("flicker");
      setTimeout(() => terminal.classList.remove("flicker"), 120);
      await sleep(linePauseMs(line));
    }
  }

  await sleep(900);
  terminalController.syncBufferFromDom();
  await terminalController.runSystemLog();

  playOneShot(beep, { volume: 0.09, rateJitter: 0.01 });
  setTimeout(() => {
    playOneShot(beep, { volume: 0.09, rateJitter: 0.01 });
  }, 500);

  terminalController.startCommandMode();
  playHddSpinOnce();
}

runBoot();
