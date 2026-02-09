
(() => {
  const MAP_CONTAINER_ID = "sector-map";
  const SYSTEM_PANEL_ID = "system-panel";

  const STATUS_CLASS = {
    STABLE: "stable",
    ALERT: "alert",
    DAMAGED: "damaged",
    COMPROMISED: "compromised",
  };

  const STATUS_SEVERITY = {
    STABLE: 0,
    ALERT: 1,
    DAMAGED: 2,
    COMPROMISED: 3,
  };

  let lastSnapshot = null;

  function clearNode(node) {
    while (node.firstChild) node.removeChild(node.firstChild);
  }

  function getCommsStatus(snapshot) {
    return snapshot.sectors.find(s => s.id === "CM")?.status || "STABLE";
  }

  function formatPanelLine(label, value) {
    return `${label.padEnd(10, ".")} ${value}`;
  }

  function formatPosture(snapshot, layout) {
    if (snapshot.hardened) return "HARDENED";
    if (snapshot.focused_sector) {
      const entry = layout.find(s => s.id === snapshot.focused_sector);
      return `FOCUSED (${entry?.name || snapshot.focused_sector})`;
    }
    return "NONE";
  }

  function renderSystemPanel(snapshot, layout, commsStatus) {
    const panel = document.getElementById(SYSTEM_PANEL_ID);
    if (!panel) return;

    clearNode(panel);

    [
      formatPanelLine("TIME", snapshot.time),
      formatPanelLine("THREAT", snapshot.threat),
      formatPanelLine(
        "ASSAULT",
        commsStatus === "COMPROMISED" ? `${snapshot.assault}?` : snapshot.assault
      ),
      formatPanelLine("POSTURE", formatPosture(snapshot, layout)),
      formatPanelLine("ARCHIVE", `${snapshot.archive_losses} / ${snapshot.archive_limit}`)
    ].forEach(line => {
      const row = document.createElement("div");
      row.className = "system-panel-line";
      row.textContent = line;
      panel.appendChild(row);
    });

    panel.classList.toggle("panel-degraded", commsStatus === "DAMAGED");
    panel.classList.toggle("panel-compromised", commsStatus === "COMPROMISED");
    panel.classList.toggle("panel-failed", snapshot.failed);
  }

  function renderSectorMap(snapshot) {
    const container = document.getElementById(MAP_CONTAINER_ID);
    if (!container) return;

    clearNode(container);

    const layout = window.CustodianSectorLayout?.SECTOR_LAYOUT || [];
    const byId = new Map(snapshot.sectors.map(s => [s.id, s]));
    const commsStatus = getCommsStatus(snapshot);

    const header = document.createElement("div");
    header.className = "sector-map-header";
    header.textContent = "SECTOR MAP";

    const meta = document.createElement("div");
    meta.className = "sector-map-meta";
    meta.textContent =
      `TIME ${snapshot.time}  |  THREAT ${snapshot.threat}  |  ASSAULT ${snapshot.assault}`;

    const grid = document.createElement("div");
    grid.className = "sector-map-grid";

    layout.forEach(entry => {
      const sector = byId.get(entry.id);
      if (!sector) return;

      const card = document.createElement("div");
      card.className = `sector-card ${STATUS_CLASS[sector.status] || "stable"} role-${entry.role || "generic"}`;
      card.style.gridColumn = entry.x + 1;
      card.style.gridRow = entry.y + 1;

      const name = document.createElement("div");
      name.className = "sector-name";
      name.textContent = sector.name || entry.name;

      const status = document.createElement("div");
      status.className = "sector-status";
      status.textContent =
        commsStatus === "COMPROMISED" && entry.id !== "CC"
          ? "[NO SIGNAL]"
          : sector.status;

      if (
        lastSnapshot &&
        STATUS_SEVERITY[sector.status] >
        STATUS_SEVERITY[lastSnapshot.sectors.find(s => s.id === entry.id)?.status || "STABLE"]
      ) {
        card.classList.add("recent-hit");
        setTimeout(() => card.classList.remove("recent-hit"), 420);
      }

      card.appendChild(name);
      card.appendChild(status);
      grid.appendChild(card);
    });

    container.appendChild(header);
    container.appendChild(meta);
    container.appendChild(grid);

    container.classList.toggle("map-degraded", commsStatus === "ALERT");
    container.classList.toggle("map-damaged", commsStatus === "DAMAGED");
    container.classList.toggle("map-compromised", commsStatus === "COMPROMISED");
    container.classList.toggle("map-failed", snapshot.failed);

    renderSystemPanel(snapshot, layout, commsStatus);
    lastSnapshot = snapshot;
  }

  window.CustodianSectorMap = { renderSectorMap };
})();

