# Awakening Connector A Replacement

- Replaced only `connector_a` in `awakening_reliquary_dust_lung_connector`; Asset V2 job `job_20260925T173131Z_7b8c6208` processed one input/output and imported it successfully.
- Input `connector_a.png` was 1254×1254 RGBA with transparency. Preserved it as `connector_a_source_v2_20260925.png`; normalized uniformly with Lanczos to 128×128, centered on a transparent 128×160 RGBA canvas (16px top/bottom, no crop/stretch).
- Canonical A runtime output is 128×160 RGBA. Asset status reports 3/3 states present/imported/bound; only A's catalog hash changed. B/C hashes and scene/layout files remained unchanged.
- `awakening_first_return_smoke.gd` passed. `asset doctor --json` reported only the pre-existing unrelated unregistered Operator inbox warning.
- Scene capture: `reports/awakening_visual_walkthrough/connector_04_05_A.png`; headless capture was unavailable with the dummy renderer, so capture used display-backed OpenGL.
