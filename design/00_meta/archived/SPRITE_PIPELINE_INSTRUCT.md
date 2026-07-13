Sprite pipeline commands:

cd /home/braydenchaffee/Projects/CUSTODIAN

If inbox PNGs already have matching .json manifests:

rtk python custodian/tools/pipelines/ingest.py

If inbox PNGs need manifests generated automatically, then ingested:

rtk python custodian/tools/pipelines/generate_inbox_manifests.py

Dry run first:

rtk python custodian/tools/pipelines/generate_inbox_manifests.py
--dry-run

After ingest, run a Godot import pass:

rtk godot --headless --path custodian --quit

Notes:

- Source files go in custodian/content/sprites/\_pipeline/inbox/.
- Each ingest job is name.png plus name.json.
- Successful ingest writes live assets under custodian/content/
  sprites/..., previews to \_pipeline/normalized/, logs to \_pipeline/
  logs/, and archives processed inbox files to \_pipeline/archive/.
- Do not keep inbox .import files as source assets; the pipeline
  removes them after ingest.
