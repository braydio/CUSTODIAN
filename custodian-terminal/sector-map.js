(() => {
  const MAP_CONTAINER_ID = "sector-map";
  const SYSTEM_PANEL_ID = "system-panel";

  const STATUS_CLASS = {
    STABLE: "stable",
    ALERT: "alert",
    DAMAGED: "damaged",
    COMPROMISED: "compromised",
  };
  const ROLE_GLYPH = {
    info: "I",
    mitigation: "M",
    authority: "A",
    amplifier: "P",
    fabrication: "F",
    goal: "R",
    buffer: "B",
    egress: "E",
    ingress: "G",
  };

  let lastSnapshot = null;

  function clearNode(node) {
    while (node.firstChild) node.removeChild(node.firstChild);
  }

  function renderSystemPanel(snapshot) {
    const panel = document.getElementById(SYSTEM_PANEL_ID);
    if (!panel) return;

    clearNode(panel);

    const lines = [
      `TIME...... ${snapshot.time}`,
      `THREAT.... ${snapshot.threat}`,
      `ASSAULT... ${snapshot.assault}`,
      `POSTURE... ${snapshot.posture || "NONE"}`,
      `ARCHIVE... ${snapshot.archive_losses} / ${snapshot.archive_limit}`
    ];

    lines.forEach(text => {
      const row = document.createElement("div");
      row.className = "system-panel-line";
      row.textContent = text;
      panel.appendChild(row);
    });
    const log = Array.isArray(snapshot.operator_log) ? snapshot.operator_log.slice(-4) : [];
    if (log.length) {
      const spacer = document.createElement("div");
      spacer.className = "system-panel-line";
      spacer.textContent = "LOGBOOK...";
      panel.appendChild(spacer);
      log.forEach((entry) => {
        const row = document.createElement("div");
        row.className = "system-panel-line";
        row.textContent = entry;
        panel.appendChild(row);
      });
    }
  }

  function renderSectorMap(snapshot) {
    const container = document.getElementById(MAP_CONTAINER_ID);
    if (!container) return;

    clearNode(container);

    const layout = window.CustodianSectorLayout?.SECTOR_LAYOUT || [];
    const byId = new Map(snapshot.sectors.map(s => [s.id, s]));

    const header = document.createElement("div");
    header.className = "sector-map-header";
    header.textContent = "SECTOR MAP";

    const grid = document.createElement("div");
    grid.className = "sector-map-grid";

    layout.forEach(entry => {
      const sector = byId.get(entry.id);
      if (!sector) return;

      const card = document.createElement("div");
      card.className = `sector-card ${STATUS_CLASS[sector.status] || "stable"} role-${entry.role}`;

      card.style.gridColumn = entry.x + 1;
      card.style.gridRow = entry.y + 1;

      const name = document.createElement("div");
      name.className = "sector-name";
      name.textContent = sector.name || entry.name;

      const status = document.createElement("div");
      status.className = "sector-status";
      status.textContent = sector.status;
      const glyph = document.createElement("div");
      glyph.className = "sector-role-glyph";
      glyph.textContent = ROLE_GLYPH[entry.role] || "?";

      if (sector.repairing) {
        card.classList.add("repair-active");
      }

      card.appendChild(name);
      card.appendChild(status);
      card.appendChild(glyph);
      grid.appendChild(card);
    });

    container.appendChild(header);
    container.appendChild(grid);

    renderSystemPanel(snapshot);
    lastSnapshot = snapshot;
  }

  window.CustodianSectorMap = { renderSectorMap };
})();
