(() => {
  const SECTOR_LAYOUT = [
    { id: "CM", name: "COMMS", x: 1, y: 0, role: "info" },
    { id: "DF", name: "DEFENSE GRID", x: 0, y: 1, role: "mitigation" },
    { id: "CC", name: "COMMAND", x: 1, y: 1, role: "authority" },
    { id: "PW", name: "POWER", x: 2, y: 1, role: "amplifier" },
    { id: "AR", name: "ARCHIVE", x: 1, y: 2, role: "goal" },
    { id: "ST", name: "STORAGE", x: 1, y: 3, role: "buffer" },
    { id: "HG", name: "HANGAR", x: 0, y: 4, role: "egress" },
    { id: "GS", name: "GATEWAY", x: 1, y: 4, role: "ingress" },
  ];

  window.CustodianSectorLayout = {
    SECTOR_LAYOUT,
  };
})();
