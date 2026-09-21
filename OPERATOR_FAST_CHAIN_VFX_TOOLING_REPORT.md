# Operator Fast-Chain VFX Tooling Report

Date: 2026-09-21

## Summary

The tooling made the task substantially safer and more repeatable, but not yet
smooth. The Source Session workflow handled normalization, candidate generation,
registration, conversion, review artifacts, and handoff well. The specialized
Operator ingest then produced canonical E/W assets and refreshed runtime data
without requiring hand-authored runtime destinations.

The remaining friction came from integration seams between tools rather than
from the art operations themselves.

## What worked well

- Source Session confinement prevented raw-source mutation and kept prepared
  inputs in the approved `asset_drop/source_work` area.
- Crisp/balanced/clustered conversion candidates made reduction choices
  explicit. Crisp was the right default for these thin amber strokes.
- Per-frame registration was bounded and deterministic. The center anchor and
  integer offsets were appropriate for VFX.
- Border-connected alpha cleanup preserved intentional dark afterimage pixels
  while removing generated matte material.
- The ingest pipeline correctly generated mirrored W strips without reversing
  temporal order or enabling runtime `flip_h`.
- Generated runtime manifests, SpriteFrames, previews, and validation reports
  provided useful evidence of frame counts and dimensions.
- The Moment Forge capture made it possible to check the complete four-link
  chain instead of reviewing isolated strips only.

## What was cumbersome

1. The Source Session review helper interpreted a flattened horizontal output as
   the original multi-row grid. It reported false frame-edge clipping and would
   not permit handoff, even though the actual 96×96 frames were clean.
2. Handoff was not replacement-aware. An existing Fast 04 destination caused a
   refusal rather than offering an explicit, reviewable supersession flow.
3. The documented inbox concepts are split: Source Session handoff uses
   `asset_drop/inbox/operator`, while manifest generation scans
   `content/sprites/_pipeline/inbox`. Moving between those locations was
   manual.
4. The pipeline generated useful intermediate archive/normalized/log files but
   did not clearly distinguish task outputs from disposable staging artifacts.
5. Compatibility resources were not automatically reconciled when old strips
   were superseded. Running the dedicated compatibility-resource updater was
   necessary to remove stale references and frame regions.
6. Headless Godot output contained substantial unrelated parser, UID, plugin,
   and resource-leak noise. Focused smoke results were still clear, but the
   signal-to-noise ratio was poor.
7. The available command-line tooling was good, but the requested Art MCP
   surface was not directly discoverable in this environment; the local CLI
   wrapper was the practical interface.

## Recommendations

### High priority

- Make Source Session review understand both grid candidates and flattened
  handoff strips. Review should extract frames using the session's declared
  target size, not infer rows from the flattened output.
- Add an explicit `handoff --replace` mode requiring the exact semantic identity,
  a dry-run confirmation, and a superseded-file report.
- Create one canonical handoff command that stages to the correct inbox and
  invokes manifest generation, avoiding manual copies between two inbox roots.
- Add a post-ingest compatibility refresh as a mandatory pipeline step whenever
  a semantic identity changes frame count or frame size.

### Medium priority

- Emit a single machine-readable task manifest containing source hash, prepared
  hash, selected candidate, scale, registration offsets, canonical paths,
  runtime paths, and validation results.
- Mark generated staging artifacts with lifecycle metadata and provide a
  cleanup command that only removes files belonging to the current task.
- Add a focused `operator fast-chain` validation command that checks all four
  E/W FX contracts, body/FX clock equality, contact-frame invariants, and
  `flip_h == false` in one invocation.
- Separate expected known warnings from actual failures in headless Godot
  output, especially parser errors from unrelated scenes and resource-leak
  shutdown diagnostics.

### Lower priority

- Expose Source Session and bounded Art operations through one stable MCP/CLI
  namespace with matching names and help text.
- Generate a standard E/W body+FX contact sheet directly from the pipeline,
  including frame labels and contact-frame markers.

## Overall assessment

The tooling already provides a strong safety foundation for production asset
work. It reduced the risk of corrupting originals, losing alpha, drifting frame
counts, or publishing the wrong runtime path. It did not yet provide a single
seamless path from source image to published runtime asset; the operator still
had to understand several internal boundaries and repair one review-tool edge
case. Fixing the high-priority seams would turn this from a careful operator
workflow into a genuinely efficient batch workflow.
