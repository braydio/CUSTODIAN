# CUSTODIAN Implementation Handoff

Use the inbound lane when a task needs an image, ZIP, or other explicit binary
payload produced or selected in ChatGPT and delivered to a CUSTODIAN execution
workstation. Dropbox is transport for these files; Git remains the authority for
code, design, task packets, schemas, and durable receipts. A fetched file is
untrusted staging input. The owning task packet and Asset Pipeline V2 remain the
authority for any later source/inbox promotion.

## Durable authored asset batches

Some tasks begin from reviewed high-resolution source masters rather than from a final immutable runtime payload. Those durable authored sources live under:

```text
CUSTODIAN/asset_batches/
```

They are indexed through:

```text
CUSTODIAN/asset_batches/_registry/
```

See `custodian/docs/ai_context/DROPBOX_ASSET_BATCH_REGISTRY.md` before searching Dropbox broadly.

The distinction is intentional:

- `asset_batches/` stores durable authored/source-master handoffs and provenance;
- `implementation_inputs/` stores exact immutable inputs explicitly consumed as packet gates;
- `visual_review/` stores outbound review evidence only.

A source-master batch may be the approved raw material from which an implementation packet derives final Asset V2 states. Presence in `asset_batches/` does not automatically satisfy a final implementation gate unless the owning packet says that exact batch is sufficient to begin work.

The current AP2 Alpine cliff source family is:

```text
CUSTODIAN/asset_batches/procgen-alpine-presentation/alpine-cliff-source-family-v1/
custodian_alpine_cliff_source_family_v1.zip
SHA-256 e804c5d9d55f0610cafde5f4169a6b36438b0e08469b212ac3fff84618b127f3
```

That package is approved source-master authority. AP2 must derive and validate the final runtime semantic states from it before producing/claiming its final Gate B handoff.

## Canonical contract

The only canonical inbound root is:

```text
CUSTODIAN/implementation_inputs/
```

Each handoff is immutable and identified by both a lowercase kebab-case
workstream and handoff ID:

```text
CUSTODIAN/implementation_inputs/<workstream>/<handoff-id>/
    HANDOFF_MANIFEST.json
    payload/
        <declared file paths>
```

The `HANDOFF_MANIFEST.json` is the commit marker. Upload all payload bytes first
and upload the manifest last. Never revise a committed handoff, upload over an
existing handoff ID, or use a mutable `LATEST.json` for inbound inputs. Create a
new handoff ID for every retry or revision. `prepare` rejects any existing
handoff path, including one that contains only a partial upload.

The manifest uses schema `custodian.implementation_handoff.v1`:

```json
{
  "schema": "custodian.implementation_handoff.v1",
  "workstream": "example-workstream",
  "handoff_id": "concept-sketch-20261005-a1",
  "created_at_utc": "2026-10-05T12:00:00Z",
  "authoring_chat": "not-recorded",
  "payloads": [
    {
      "path": "payload/concept.png",
      "size_bytes": 12345,
      "sha256": "<64 lowercase hexadecimal characters>",
      "purpose": "front-facing room concept",
      "mime_type": "image/png"
    }
  ]
}
```

`authoring_chat` is the exact originating conversation URL when supplied, or
`not-recorded` / `n/a`; never derive or invent a conversation URL. Every payload
entry has a normalized relative `payload/...` path, exact byte size, lowercase
SHA-256, and short purpose. `mime_type` is optional. The manifest is UTF-8 JSON
and limited to 1 MiB. The default combined payload ceiling is 256 MiB; use
`fetch --max-bytes <bytes>` only when the task explicitly needs a larger package.

## Prepare, upload, fetch

Check or create the root, then reserve a fresh handoff:

```bash
python3 custodian/tools/iteration/implementation_handoff.py doctor --ensure-root
python3 custodian/tools/iteration/implementation_handoff.py prepare \
  --workstream <workstream-id> \
  --handoff-id <new-lowercase-kebab-id>
```

`prepare` emits the exact remote path, payload folder, manifest path, and required
upload order in `CUSTODIAN_IMPLEMENTATION_HANDOFF_JSON`. The payload folder is
created empty. If nested payload paths are used, create their parent directories
before uploading. In ChatGPT, upload each generated/selected file to the exact
`payload/.../<filename>` destination under the prepared folder. Upload the
completed `HANDOFF_MANIFEST.json` to the prepared manifest path only after every
payload upload has completed. Do not rename, shuffle, or extract the files
between upload and fetch.

Fetch from the same workstream and ID:

```bash
python3 custodian/tools/iteration/implementation_handoff.py fetch \
  --workstream <workstream-id> \
  --handoff-id <handoff-id>
```

The default verified staging root is
`$XDG_CACHE_HOME/custodian/implementation_inputs`, falling back to
`~/.cache/custodian/implementation_inputs`. The final directory is
`<staging-root>/<workstream>/<handoff-id>/`. A different `--staging-root` may be
used, but it must be outside the CUSTODIAN checkout; direct fetches into runtime,
content, or Asset V2 directories are rejected. An existing destination is never
overwritten. Successful fetch emits a machine-readable
`CUSTODIAN_IMPLEMENTATION_HANDOFF_JSON` receipt with local path, remote path,
sizes, hashes, and `extracted: false`.

Before exposing the staging directory, the fetcher validates the manifest and
identity, verifies that the remote file set is exactly the manifest plus its
declared payload files, enforces the combined byte limit, downloads only those
files to temporary staging, and checks every size and SHA-256. It atomically
renames the complete verified directory into place. Any error removes temporary
staging and leaves no final destination. ZIPs stay opaque; the fetcher never
extracts archives, edits runtime/content, writes Asset V2 `source_work` or
`inbox`, routes files into `asset_drop`, or infers semantic destinations.

## Remote selection and credentials

Both directions share `custodian/tools/iteration/dropbox_transport.py` and never
read or print rclone credentials. Inbound remote selection is:

1. `--remote`;
2. `CUSTODIAN_IMPLEMENTATION_REMOTE`;
3. legacy `CUSTODIAN_REVIEW_REMOTE`;
4. exact `dropbox:` remote, or one unambiguous configured remote whose name
   contains `dropbox`.

Outbound selection remains `--remote`, then `CUSTODIAN_REVIEW_REMOTE`, then the
same auto-detection. When multiple Dropbox-like remotes exist, select one
explicitly. Keep rclone config, OAuth tokens, and app keys outside Git. The
inbound root is transient external implementation input; the existing
`CUSTODIAN/visual_review/` root remains transient outbound review evidence and
continues to use `publish_review_artifacts.py`.
