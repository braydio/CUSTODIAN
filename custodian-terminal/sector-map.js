(() => {
  const MAP_CONTAINER_ID = "sector-map";

  const STATUS_CLASS = {
    STABLE: "stable",
    ALERT: "alert",
    DAMAGED: "damaged",
    COMPROMISED: "compromised",
  };

  function clearNode(node) {
    while (node.firstChild) {
      node.removeChild(node.firstChild);
    }
  }

  function renderSectorMap(snapshot) {
    const container = document.getElementById(MAP_CONTAINER_ID);
    if (!container) return;

    clearNode(container);

    const layout = window.CustodianSectorLayout?.SECTOR_LAYOUT || [];
    const sectorById = new Map(
      snapshot.sectors.map((sector) => [sector.id, sector])
    );

    const header = document.createElement("div");
    header.className = "sector-map-header";
    header.textContent = "SECTOR SNAPSHOT";

    const meta = document.createElement("div");
    meta.className = "sector-map-meta";
    meta.textContent = `TIME ${snapshot.time} | THREAT ${snapshot.threat} | ASSAULT ${snapshot.assault}`;

    const grid = document.createElement("div");
    grid.className = "sector-map-grid";

    const renderList = layout.length > 0 ? layout : snapshot.sectors;

    renderList.forEach((layoutItem) => {
      const sector =
        layout.length > 0
          ? sectorById.get(layoutItem.id)
          : layoutItem;

      if (!sector) {
        return;
      }

      const card = document.createElement("div");
      card.className = "sector-card";

      const statusClass = STATUS_CLASS[sector.status] || "stable";
      card.classList.add(statusClass);

      const name = document.createElement("div");
      name.className = "sector-name";
      name.textContent = sector.name || layoutItem.name;

      const status = document.createElement("div");
      status.className = "sector-status";
      status.textContent = sector.status;

      if (layout.length > 0) {
        card.style.gridColumn = layoutItem.x + 1;
        card.style.gridRow = layoutItem.y + 1;
      }

      card.appendChild(name);
      card.appendChild(status);
      grid.appendChild(card);
    });

    container.appendChild(header);
    container.appendChild(meta);
    container.appendChild(grid);
  }

  window.CustodianSectorMap = {
    renderSectorMap,
  };
})();
