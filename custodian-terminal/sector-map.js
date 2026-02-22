(() => {
  const ui = window.CustodianUiHelpers || {};
  const byId = ui.byId || ((id) => document.getElementById(id));
  const clearChildren = ui.clearChildren || ((node) => {
    while (node && node.firstChild) node.removeChild(node.firstChild);
  });

  const MAP_CONTAINER_ID = "sector-map";
  const SYSTEM_PANEL_ID = "system-panel";

  const STATUS_CLASS = {
    STABLE: "stable",
    ALERT: "alert",
    DAMAGED: "damaged",
    COMPROMISED: "compromised",
  };

  const WORLD_LINKS = [
    ["INGRESS_N", "T_NORTH"],
    ["INGRESS_S", "T_SOUTH"],
    ["T_NORTH", "COMMAND"],
    ["T_SOUTH", "COMMAND"],
    ["T_NORTH", "ARCHIVE"],
    ["T_NORTH", "COMMS"],
    ["T_NORTH", "STORAGE"],
    ["T_SOUTH", "DEFENSE GRID"],
    ["T_SOUTH", "HANGAR"],
    ["T_SOUTH", "GATEWAY"],
    ["COMMAND", "POWER"],
    ["COMMAND", "FABRICATION"],
  ];

  const MAP_POSITIONS = {
    INGRESS_N: { x: 420, y: 36, type: "ingress" },
    T_NORTH: { x: 420, y: 108, type: "transit" },
    COMMS: { x: 260, y: 172, type: "sector", id: "CM" },
    ARCHIVE: { x: 420, y: 172, type: "sector", id: "AR" },
    STORAGE: { x: 580, y: 172, type: "sector", id: "ST" },
    COMMAND: { x: 420, y: 260, type: "sector", id: "CC" },
    POWER: { x: 580, y: 260, type: "sector", id: "PW" },
    FABRICATION: { x: 580, y: 348, type: "sector", id: "FB" },
    T_SOUTH: { x: 420, y: 348, type: "transit" },
    DEFENSE_GRID: { x: 260, y: 348, type: "sector", id: "DF", label: "DEFENSE GRID" },
    HANGAR: { x: 260, y: 432, type: "sector", id: "HG" },
    GATEWAY: { x: 420, y: 432, type: "sector", id: "GS" },
    INGRESS_S: { x: 420, y: 500, type: "ingress" },
  };

  function renderSystemPanel(snapshot) {
    const panel = byId(SYSTEM_PANEL_ID);
    if (!panel) return;
    clearChildren(panel);

    [
      `TIME...... ${snapshot.time}`,
      `THREAT.... ${snapshot.threat}`,
      `ASSAULT... ${snapshot.assault}`,
      `MODE...... ${snapshot.player_mode}`,
      `ARCHIVE... ${snapshot.archive_losses} / ${snapshot.archive_limit}`,
    ].forEach((text) => {
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

  function renderCompactGrid(snapshot) {
    const container = byId(MAP_CONTAINER_ID);
    if (!container) return;
    clearChildren(container);

    const layout = window.CustodianSectorLayout?.SECTOR_LAYOUT || [];
    const sectorsById = new Map(snapshot.sectors.map((s) => [s.id, s]));

    const header = document.createElement("div");
    header.className = "sector-map-header";
    header.textContent = "SECTOR MAP";

    const grid = document.createElement("div");
    grid.className = "sector-map-grid";

    layout.forEach((entry) => {
      const sector = sectorsById.get(entry.id);
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

      card.appendChild(name);
      card.appendChild(status);
      grid.appendChild(card);
    });

    container.appendChild(header);
    container.appendChild(grid);
  }

  function renderOverviewMap(snapshot, targetId = "map-mode-map", detailed = false) {
    const container = byId(targetId);
    if (!container) return;
    clearChildren(container);

    const sectorsByName = new Map(snapshot.sectors.map((s) => [s.name, s]));

    const header = document.createElement("div");
    header.className = "sector-map-header";
    header.textContent = detailed ? "STRATEGIC MAP FEED" : "WORLD MAP";
    container.appendChild(header);

    const svgNs = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(svgNs, "svg");
    svg.setAttribute("viewBox", "0 0 840 540");
    svg.setAttribute("class", "map-canvas");

    WORLD_LINKS.forEach(([a, b]) => {
      const pa = MAP_POSITIONS[a];
      const pb = MAP_POSITIONS[b];
      if (!pa || !pb) return;
      const line = document.createElementNS(svgNs, "line");
      line.setAttribute("x1", String(pa.x));
      line.setAttribute("y1", String(pa.y));
      line.setAttribute("x2", String(pb.x));
      line.setAttribute("y2", String(pb.y));
      line.setAttribute("class", `map-link ${a.startsWith("INGRESS") || b.startsWith("INGRESS") ? "ingress-link" : ""}`);
      svg.appendChild(line);
    });

    Object.entries(MAP_POSITIONS).forEach(([key, pos]) => {
      const node = document.createElementNS(svgNs, "g");
      node.setAttribute("class", "map-node");
      node.setAttribute("transform", `translate(${pos.x},${pos.y})`);

      const circle = document.createElementNS(svgNs, "circle");
      circle.setAttribute("r", pos.type === "sector" ? "20" : "12");
      circle.setAttribute("fill", pos.type === "sector" ? "#0f2312" : "#102014");
      circle.setAttribute("stroke", pos.type === "ingress" ? "#a57934" : "#3f6f44");
      circle.setAttribute("stroke-width", "2");

      let labelText = pos.label || key.replaceAll("_", " ");
      if (pos.type === "sector") {
        const sector = sectorsByName.get(labelText);
        if (sector) {
          node.classList.add(`status-${sector.status}`);
          if (sector.status === "DAMAGED") circle.setAttribute("fill", "#2a1414");
          if (sector.status === "COMPROMISED") circle.setAttribute("fill", "#3a1111");
          if (sector.status === "ALERT") circle.setAttribute("fill", "#27200f");
        }
      }

      const label = document.createElementNS(svgNs, "text");
      label.setAttribute("class", "map-node-label");
      label.setAttribute("x", "0");
      label.setAttribute("y", pos.type === "sector" ? "34" : "28");
      label.setAttribute("text-anchor", "middle");
      label.textContent = labelText;

      node.appendChild(circle);
      node.appendChild(label);
      svg.appendChild(node);
    });

    container.appendChild(svg);
  }

  function renderSectorMap(snapshot) {
    renderCompactGrid(snapshot);
    renderSystemPanel(snapshot);
    renderOverviewMap(snapshot, "map-mode-map", true);
  }

  window.CustodianSectorMap = { renderSectorMap, renderOverviewMap };
})();
