
(() => {
  const terminal = document.getElementById("terminal");

  const hum = document.getElementById("hum");
  const relay = document.getElementById("relay");
  const beep = document.getElementById("beep");
  const timingRelay = document.getElementById("timingRelay");
  const fourBeep = document.getElementById("fourBeep");
  const hddSpin = document.getElementById("hddSpin");

  const alertPulseA = document.getElementById("alertPulseA");
  const alertPulseB = document.getElementById("alertPulseB");

  const terminalController = window.CustodianTerminal;

  const BOOT_PAUSES = {
    INITIAL: 1000,
    PRE_FINAL: 2000,
    FINAL: 3000,
  };

  /* =========================
     Audio: policy-safe init
     ========================= */

  let audioReady = false;

  function tryStartHum() {
    if (!hum) return;
    hum.volume = 0.15;
    hum.play().then(() => {
      audioReady = true;
    }).catch(() => {});
  }

  tryStartHum();

  function unlockAudioOnce() {
    if (audioReady) return;
    tryStartHum();

    [
      relay,
      timingRelay,
      fourBeep,
      hddSpin,
      beep,
      alertPulseA,
      alertPulseB,
    ].forEach((el) => {
      if (!el) return;
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
     Audio helpers
     ========================= */

  function playTimingRelayTransition({
    volume = 0.18,
    holdMs = 5000,
    fadeMs = 4000,
  } = {}) {
    if (!timingRelay) return;

    timingRelay.loop = true;
    timingRelay.currentTime = 0;
    timingRelay.volume = volume;

    timingRelay.play().catch(() => {});

    // Start fade after hold
    setTimeout(() => {
      const start = performance.now();
      const startVol = volume;

      function fade(now) {
        const t = Math.min(1, (now - start) / fadeMs);
        timingRelay.volume = Math.max(0, startVol * (1 - t));

        if (t < 1) {
          requestAnimationFrame(fade);
        } else {
          timingRelay.pause();
          timingRelay.currentTime = 0;
        }
      }

      requestAnimationFrame(fade);
    }, holdMs);
  }
  
  function playOneShot(el, { volume = 0.2, rateJitter = 0.03 } = {}) {
    if (!el) return;
    const a = el.cloneNode(true);
    a.volume = volume;
    a.playbackRate = 1 + (Math.random() * 2 - 1) * rateJitter;
    a.currentTime = 0;
    a.play().catch(() => {});
  }

  function playSingleShot(el, { volume = 0.2 } = {}) {
    if (!el) return;
    try {
      el.volume = volume;
      el.currentTime = 0;
      el.play().catch(() => {});
    } catch {}
  }

  function fadeOut(el, startMs, endMs, startVolume) {
    if (!el) return;
    const start = performance.now() + startMs;
    const end = performance.now() + endMs;
    const initial = startVolume ?? el.volume ?? 0.2;

    function tick(now) {
      if (now < start) return requestAnimationFrame(tick);
      const t = Math.min(1, (now - start) / (end - start));
      el.volume = Math.max(0, initial * (1 - t));
      if (t < 1) requestAnimationFrame(tick);
    }

    requestAnimationFrame(tick);
  }

  /* =========================
     HUM DIP (final pause)
     ========================= */

  function dipHum({
    from = 0.15,
    to = 0.06,
    downMs = 600,
    holdMs = 1200,
    upMs = 800,
  } = {}) {
    if (!hum) return;

    const t0 = performance.now();
    hum.volume = from;

    function step(now) {
      const dt = now - t0;

      if (dt < downMs) {
        hum.volume = from - (from - to) * (dt / downMs);
      } else if (dt < downMs + holdMs) {
        hum.volume = to;
      } else if (dt < downMs + holdMs + upMs) {
        const t = (dt - downMs - holdMs) / upMs;
        hum.volume = to + (from - to) * t;
      } else {
        hum.volume = from;
        return;
      }

      requestAnimationFrame(step);
    }

    requestAnimationFrame(step);
  }

  /* =========================
     Alert pulses
     ========================= */

  let alertPulseCooldown = 0;

  function playAlertPulse() {
    const now = performance.now();
    if (now < alertPulseCooldown) return;
    alertPulseCooldown = now + 3600;

    [
      { el: alertPulseA, delay: 0,   volume: 0.22 },
      { el: alertPulseB, delay: 420, volume: 0.20 },
      { el: alertPulseA, delay: 860, volume: 0.18 },
    ].forEach(({ el, delay, volume }) => {
      setTimeout(() => playSingleShot(el, { volume }), delay);
    });
  }

  /* =========================
     Mechanical ambience
     ========================= */

  function playRelaySequence() {
    if (timingRelay) {
      playSingleShot(timingRelay, { volume: 0.18 });
      fadeOut(timingRelay, 2000, 5000, 0.18);
    }
    if (fourBeep) {
      setTimeout(() => playSingleShot(fourBeep, { volume: 0.18 }), 1000);
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

  /* =========================
     Clear terminal (UNCHANGED)
     ========================= */

  function clearTerminalAnimated(durationMs = 5000) {
    return new Promise((resolve) => {
      const text = terminal.textContent || "";
      const total = text.length;
      if (!total) return resolve();

      const start = performance.now();

      function tick(now) {
        const progress = Math.min(1, (now - start) / durationMs);
        const remaining = Math.ceil(total * (1 - progress));
        terminal.textContent = text.slice(0, remaining);
        terminal.scrollTop = terminal.scrollHeight;
        if (progress < 1) requestAnimationFrame(tick);
        else {
          terminal.textContent = "";
          resolve();
        }
      }

      requestAnimationFrame(tick);
    });
  }

  /* =========================
     Line classification
     ========================= */

  function isWarningLine(t = "") {
    t = t.toUpperCase();
    return t.includes("WARNING") || t.includes("DEGRADED") || t.includes("OFFLINE");
  }

  function isFinalBootLine(t = "") {
    return t.toUpperCase().includes("INITIALIZING CUSTODIAN INTERFACE");
  }

  function isPreFinalBootLine(_, i, lines) {
    return isFinalBootLine(lines[i + 1]);
  }

  function linePauseMs(text, index, lines) {
    if (index === 0) return BOOT_PAUSES.INITIAL;
    if (isPreFinalBootLine(text, index, lines)) return BOOT_PAUSES.PRE_FINAL;
    if (isFinalBootLine(text)) return BOOT_PAUSES.FINAL;
    return 160 + Math.random() * 220;
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
    "Initializing Custodian Interface...",
  ];

  function sleep(ms) {
    return new Promise((r) => setTimeout(r, ms));
  }

  /* =========================
     Typing logic
     ========================= */

  function typeLine(text) {
    return new Promise((resolve) => {
      let i = 0;

      if (isWarningLine(text)) playAlertPulse();
      if (Math.random() < 0.25) playOneShot(beep, { volume: 0.06 });

      const interval = setInterval(() => {
        terminal.textContent += text[i++] || "";
        if (i >= text.length) {
          clearInterval(interval);
          terminal.textContent += "\n";
          terminal.scrollTop = terminal.scrollHeight;
          if (Math.random() < 0.3) playOneShot(relay, { volume: 0.06 });
          resolve();
        }
      }, 10 + Math.random() * 12);
    });
  }

  /* =========================
     Boot sequence
     ========================= */

  async function runBoot() {
    terminalController.setInputEnabled(false);

    playOneShot(relay, { volume: 0.18 });
    playRelaySequence();
    await sleep(400);

    for (let i = 0; i < bootLines.length; i++) {
      const line = bootLines[i];
      await typeLine(line);

      if (isFinalBootLine(line)) dipHum();

      terminal.classList.add("flicker");
      setTimeout(() => terminal.classList.remove("flicker"), 120);

      await sleep(linePauseMs(line, i, bootLines));
    }

    playTimingRelayTransition({
      volume: 0.18,
      holdMs: 5000,
      fadeMs: 4000,
    });

    await clearTerminalAnimated(5000);
    terminalController.clearBuffer();

    terminalController.startCommandMode();
    playHddSpinOnce();
  }

  runBoot();
})();

