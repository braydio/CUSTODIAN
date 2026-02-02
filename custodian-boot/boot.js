const terminal = document.getElementById("terminal");
const bootScreen = document.getElementById("boot-screen");
const baseScreen = document.getElementById("base-screen");

const lines = [
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

let i = 0;

function typeLine(text) {
  return new Promise(resolve => {
    let idx = 0;
    const interval = setInterval(() => {
      terminal.textContent += text[idx] || "";
      idx++;
      if (idx >= text.length) {
        clearInterval(interval);
        terminal.textContent += "\n";
        resolve();
      }
    }, 20 + Math.random() * 30);
  });
}

async function runBoot() {
  for (const line of lines) {
    await typeLine(line);
    terminal.classList.add("flicker");
    setTimeout(() => terminal.classList.remove("flicker"), 100);
    await new Promise(r => setTimeout(r, 200 + Math.random() * 300));
  }

  await new Promise(r => setTimeout(r, 800));
  transitionToBase();
}

function transitionToBase() {
  bootScreen.style.display = "none";
  baseScreen.hidden = false;
}

runBoot();

