
const terminal = document.getElementById("terminal");

const hum = document.getElementById("hum");
const relay = document.getElementById("relay");
const alertSound = document.getElementById("alert");

hum.volume = 0.15;
hum.play().catch(() => { /* browser requires user interaction */ });

const bootLines = [
  "[ SYSTEM POWER: UNSTABLE ]",
  "[ AUXILIARY POWER ROUTED ]",
  "",
  "CUSTODIAN NODE — ONLINE",
  "STATUS: DEGRADED",
  "AUTHORITY: RESIDUAL",
  "",
  "> Running integrity check…",
  "> Memory blocks: 12% intact",
  "> Long-range comms: OFFLINE",
  "> Archive uplink: OFFLINE",
  "> Automated defense grid: PARTIAL",
  "",
  "DIRECTIVE FOUND",
  "RETENTION MANDATE — ACTIVE",
  "",
  "WARNING:",
  "Issuing authority presumed defunct.",
  "",
  "Residual Authority accepted.",
  "",
  "Initializing Custodian interface…"
];

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function typeLine(text) {
  return new Promise(resolve => {
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
      i++;

      if (i >= text.length) {
        clearInterval(interval);
        terminal.textContent += "\n";
        terminal.scrollTop = terminal.scrollHeight;
        resolve();
      }
    }, 18 + Math.random() * 25);
  });
}

async function runBoot() {
  for (const line of bootLines) {
    await typeLine(line);
    terminal.classList.add("flicker");
    setTimeout(() => terminal.classList.remove("flicker"), 120);
    await sleep(200 + Math.random() * 300);
  }

  await sleep(800);
  enterCommandMode();
}

function enterCommandMode() {
  terminal.textContent += "\n--- COMMAND INTERFACE ACTIVE ---\n";
  terminal.textContent += "Awaiting directives.\n\n";
  terminal.scrollTop = terminal.scrollHeight;

  setTimeout(simulateTelemetry, 1500);
}

function simulateTelemetry() {
  const messages = [
    "[ SENSOR ] Movement detected near Security Gate.",
    "[ POWER ] Output stable at 83%.",
    "[ DEFENSE ] Turret A responding.",
    "[ ALERT ] Ideological markers detected.",
    "[ SENSOR ] Multiple hostiles converging."
  ];

  let i = 0;
  const interval = setInterval(() => {
    if (i >= messages.length) {
      clearInterval(interval);
      return;
    }

    terminal.textContent += messages[i] + "\n";
    terminal.scrollTop = terminal.scrollHeight;

    alertSound.volume = 0.3;
    alertSound.play().catch(() => {});

    i++;
  }, 2500);
}

runBoot();

