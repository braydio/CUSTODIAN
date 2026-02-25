(() => {
  const ui = window.CustodianUiHelpers || {};
  const byId = ui.byId || ((id) => document.getElementById(id));
  const clearChildren = ui.clearChildren || ((node) => {
    while (node && node.firstChild) node.removeChild(node.firstChild);
  });

  const MAP_CONTAINER_ID = "sector-map";
  const SYSTEM_PANEL_ID = "system-panel";
  const MAP_MODE_TITLE_ID = "map-mode-title";

  const FOCUS_MODES = ["general", "defense", "logistics"];
  let activeFocusMode = "general";
  let lastSnapshot = null;

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
    INGRESS_N: { x: 420, y: 36, type: "ingress", label: "NORTH INGRESS" },
    T_NORTH: { x: 420, y: 108, type: "transit", label: "NORTH TRANSIT" },
    COMMS: { x: 260, y: 172, type: "sector", id: "CM" },
    ARCHIVE: { x: 420, y: 172, type: "sector", id: "AR" },
    STORAGE: { x: 580, y: 172, type: "sector", id: "ST" },
    COMMAND: { x: 420, y: 260, type: "sector", id: "CC" },
    POWER: { x: 580, y: 260, type: "sector", id: "PW" },
    FABRICATION: { x: 580, y: 348, type: "sector", id: "FB" },
    T_SOUTH: { x: 420, y: 348, type: "transit", label: "SOUTH TRANSIT" },
    DEFENSE_GRID: { x: 260, y: 348, type: "sector", id: "DF", label: "DEFENSE GRID" },
    HANGAR: { x: 260, y: 432, type: "sector", id: "HG" },
    GATEWAY: { x: 420, y: 432, type: "sector", id: "GS" },
    INGRESS_S: { x: 420, y: 500, type: "ingress", label: "SOUTH INGRESS" },
  };

  const DEFENSE_GROUP_BY_SECTOR = {
    COMMAND: "COMMAND",
    POWER: "POWER",
    FABRICATION: "POWER",
    COMMS: "SENSORS",
  };

  const LOGISTICS_FLOW_LINKS = [
    ["INGRESS_N", "T_NORTH"],
    ["INGRESS_S", "T_SOUTH"],
    ["T_NORTH", "STORAGE"],
    ["T_SOUTH", "STORAGE"],
    ["STORAGE", "FABRICATION"],
    ["FABRICATION", "DEFENSE_GRID"],
    ["FABRICATION", "HANGAR"],
    ["FABRICATION", "COMMAND"],
  ];

  function clampNumber(value, min, max) {
    const num = Number.isFinite(value) ? value : 0;
    return Math.max(min, Math.min(max, num));
  }

  function formatLevel(value) {
    const level = clampNumber(value, 0, 4);
    return String(Math.round(level));
  }

  function renderPips(value, max = 4) {
    const count = clampNumber(value, 0, max);
    const filled = "#".repeat(Math.round(count));
    const empty = ".".repeat(max - Math.round(count));
    return `${filled}${empty}`;
  }

  function renderMiniBar(value) {
    const scaled = clampNumber(Math.round(value / 10), 0, 5);
    return `[${"#".repeat(scaled)}${".".repeat(5 - scaled)}]`;
  }

  function sectorNameForKey(key, pos) {
    if (!pos || pos.type !== "sector") return null;
    return pos.label || key.replaceAll("_", " ");
  }

  function overlayAnchorFor(pos) {
    if (pos.x < 320) return { x: 26, y: -8, anchor: "start" };
    if (pos.x > 520) return { x: -26, y: -8, anchor: "end" };
    return { x: 0, y: -48, anchor: "middle" };
  }

  function defenseGroupForSector(name) {
    return DEFENSE_GROUP_BY_SECTOR[name] || "PERIMETER";
  }

  function buildOverlayLines(sectorName, snapshot, focusMode) {
    const policies = snapshot.policies || {};
    const defense = snapshot.defense || {};
    const logistics = snapshot.logistics || {};
    const fortLevel = (policies.fortification || {})[sectorName] ?? 0;
    const defenseAlloc = defense.allocation || {};
    const defenseReadiness = policies.defense_readiness ?? 2;
    const repairIntensity = policies.repair_intensity ?? 2;
    const surveillanceCoverage = policies.surveillance_coverage ?? 2;
    const focus = snapshot.focused_sector;
    const focusName = snapshot.sectors?.find((sector) => sector.id === focus)?.name || focus;
    const hardened = snapshot.hardened;
    const doctrine = defense.doctrine || "STANDARD";
    const readiness = defense.readiness ?? 1;
    const materials = snapshot.resources?.materials ?? 0;
    const stocks = snapshot.stocks || {};
    const inventory = snapshot.inventory || {};
    const fabAllocation = policies.fabrication_allocation || {};
    const fabQueue = Array.isArray(snapshot.fabrication_queue) ? snapshot.fabrication_queue : [];
    const group = defenseGroupForSector(sectorName);
    const weight = Number(defenseAlloc[group] ?? 1);

    if (focusMode === "general") {
      if (sectorName === "COMMAND") {
        return [
          `POSTURE ${hardened ? "HARDENED" : "BASELINE"}`,
          focus ? `FOCUS ${focusName}` : "FOCUS NONE",
          `POL R${formatLevel(repairIntensity)} D${formatLevel(defenseReadiness)} S${formatLevel(surveillanceCoverage)}`,
        ];
      }
      if (sectorName === "FABRICATION") {
        return [
          `FORT ${formatLevel(fortLevel)}`,
          `FAB DEF${formatLevel(fabAllocation.DEFENSE)} DRN${formatLevel(fabAllocation.DRONES)}`,
          `FAB REP${formatLevel(fabAllocation.REPAIRS)} ARC${formatLevel(fabAllocation.ARCHIVE)}`,
        ];
      }
      return [
        `FORT ${formatLevel(fortLevel)}`,
        `DEF ${group} ${weight.toFixed(2)}`,
      ];
    }

    if (focusMode === "defense") {
      if (sectorName === "COMMAND") {
        return [
          `DOCTRINE ${doctrine}`,
          `READINESS ${readiness.toFixed(2)}`,
          `POSTURE ${hardened ? "HARDENED" : "BASELINE"}`,
        ];
      }
      if (sectorName === "DEFENSE GRID") {
        return [
          `DEF ${group} ${weight.toFixed(2)}`,
          `FORT ${formatLevel(fortLevel)}`,
          `UNITS ${renderPips(defenseReadiness)}`,
        ];
      }
      return [
        `DEF ${group} ${weight.toFixed(2)}`,
        `FORT ${formatLevel(fortLevel)}`,
      ];
    }

    if (focusMode === "logistics") {
      if (sectorName === "STORAGE") {
        const invCount = Object.values(inventory).reduce((sum, val) => sum + (Number(val) || 0), 0);
        return [
          `MATS ${materials} ${renderMiniBar(materials)}`,
          `STORE ${invCount} ${renderMiniBar(invCount)}`,
          `FLOW ${logistics.throughput ?? 0} / ${logistics.load ?? 0}`,
        ];
      }
      if (sectorName === "FABRICATION") {
        return [
          `QUEUE ${fabQueue.length} ${renderMiniBar(fabQueue.length * 5)}`,
          `DEF${formatLevel(fabAllocation.DEFENSE)} DRN${formatLevel(fabAllocation.DRONES)}`,
          `REP${formatLevel(fabAllocation.REPAIRS)} ARC${formatLevel(fabAllocation.ARCHIVE)}`,
        ];
      }
      if (sectorName === "HANGAR") {
        return [
          `DRONES ${stocks.repair_drones ?? 0} ${renderMiniBar(stocks.repair_drones ?? 0)}`,
          `OUTFLOW ${logistics.pressure ?? 0}`,
        ];
      }
      if (sectorName === "DEFENSE GRID") {
        return [
          `AMMO ${stocks.turret_ammo ?? 0} ${renderMiniBar(stocks.turret_ammo ?? 0)}`,
          `LOAD ${logistics.load ?? 0}`,
        ];
      }
      if (sectorName === "COMMAND") {
        return [
          `THRU ${logistics.throughput ?? 0}`,
          `LOAD ${logistics.load ?? 0}`,
          `PRESS ${logistics.pressure ?? 0}`,
        ];
      }
      return [`FORT ${formatLevel(fortLevel)}`, `DEF ${group} ${weight.toFixed(2)}`];
    }

    return [];
  }

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

    lastSnapshot = snapshot;
    const sectorsByName = new Map(snapshot.sectors.map((s) => [s.name, s]));

    const mapTitle = byId(MAP_MODE_TITLE_ID);
    if (targetId === "map-mode-map" && mapTitle) {
      mapTitle.textContent = detailed ? "STRATEGIC MAP FEED" : "WORLD MAP";
    } else {
      const header = document.createElement("div");
      header.className = "sector-map-header";
      header.textContent = detailed ? "STRATEGIC MAP FEED" : "WORLD MAP";
      container.appendChild(header);
    }

    const svgNs = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(svgNs, "svg");
    svg.setAttribute("viewBox", "0 0 840 540");
    svg.setAttribute("class", "map-canvas");

    if (activeFocusMode === "logistics" && detailed) {
      const defs = document.createElementNS(svgNs, "defs");
      const marker = document.createElementNS(svgNs, "marker");
      marker.setAttribute("id", "flow-arrow");
      marker.setAttribute("markerWidth", "10");
      marker.setAttribute("markerHeight", "10");
      marker.setAttribute("refX", "6");
      marker.setAttribute("refY", "3");
      marker.setAttribute("orient", "auto");
      const arrow = document.createElementNS(svgNs, "path");
      arrow.setAttribute("d", "M0,0 L6,3 L0,6 Z");
      arrow.setAttribute("fill", "#7bbf86");
      marker.appendChild(arrow);
      defs.appendChild(marker);
      svg.appendChild(defs);
    }

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

    if (activeFocusMode === "logistics" && detailed) {
      LOGISTICS_FLOW_LINKS.forEach(([a, b]) => {
        const pa = MAP_POSITIONS[a];
        const pb = MAP_POSITIONS[b];
        if (!pa || !pb) return;
        const line = document.createElementNS(svgNs, "line");
        line.setAttribute("x1", String(pa.x));
        line.setAttribute("y1", String(pa.y));
        line.setAttribute("x2", String(pb.x));
        line.setAttribute("y2", String(pb.y));
        line.setAttribute("class", "map-link logistics-link");
        line.setAttribute("marker-end", "url(#flow-arrow)");
        svg.appendChild(line);
      });
    }

    if (activeFocusMode === "defense" && detailed) {
      Object.entries(MAP_POSITIONS).forEach(([key, pos]) => {
        if (pos.type !== "sector") return;
        const sectorName = sectorNameForKey(key, pos);
        if (!sectorName) return;
        const defenseAlloc = snapshot.defense?.allocation || {};
        const group = defenseGroupForSector(sectorName);
        const weight = Number(defenseAlloc[group] ?? 1);
        const ring = document.createElementNS(svgNs, "circle");
        ring.setAttribute("cx", String(pos.x));
        ring.setAttribute("cy", String(pos.y));
        ring.setAttribute("r", String(26 + Math.max(0, weight - 0.6) * 12));
        ring.setAttribute("class", "map-defense-ring");
        svg.appendChild(ring);
      });
    }

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

    if (detailed) {
      const overlayGroup = document.createElementNS(svgNs, "g");
      overlayGroup.setAttribute("class", `map-overlays mode-${activeFocusMode}`);
      Object.entries(MAP_POSITIONS).forEach(([key, pos]) => {
        if (pos.type !== "sector") return;
        const sectorName = sectorNameForKey(key, pos);
        if (!sectorName) return;
        const lines = buildOverlayLines(sectorName, snapshot, activeFocusMode);
        if (!lines.length) return;
        const anchor = overlayAnchorFor(pos);
        lines.forEach((text, index) => {
          const row = document.createElementNS(svgNs, "text");
          row.setAttribute("class", "map-overlay-text");
          row.setAttribute("x", String(pos.x + anchor.x));
          row.setAttribute("y", String(pos.y + anchor.y + index * 12));
          row.setAttribute("text-anchor", anchor.anchor);
          row.textContent = text;
          overlayGroup.appendChild(row);
        });
      });
      svg.appendChild(overlayGroup);
    }

    container.appendChild(svg);
  }

  function renderSectorMap(snapshot) {
    renderCompactGrid(snapshot);
    renderSystemPanel(snapshot);
    renderOverviewMap(snapshot, "map-mode-map", true);
  }

  function setMapFocusMode(mode) {
    if (!FOCUS_MODES.includes(mode)) return;
    activeFocusMode = mode;
    if (lastSnapshot) renderOverviewMap(lastSnapshot, "map-mode-map", true);
  }

  window.CustodianSectorMap = { renderSectorMap, renderOverviewMap, setMapFocusMode };
})();
