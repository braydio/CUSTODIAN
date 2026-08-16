# Sundered Keep Cliff Vocabulary + Context Lab

Status: complete

## Outcome

The shared shoreline compositor now plans and renders the existing 15-piece
cliff vocabulary with occupancy-driven corners, pivot-aware placement,
deterministic horizontal face-slice variation, and corner exclusion. It remains
presentation-only.

The shoreline lab preserves live transform parity and adds a controlled cliff
vocabulary fixture, topology diagnostics, and optional production context. The
lab and production instance one passive vista-art bundle and use one ocean-mask
builder. Context controls do not affect shoreline plans or placement.

## Authority and boundaries

- `SunderedKeepShorelineCompositor` owns shoreline presentation planning.
- Generated floor/ocean topology remains gameplay authority.
- The asset catalog contains no collision or navigation construction.
- Face slices are restricted to N/S-facing coastlines; no source art rotates.
- The new 128x128 macro-corner artwork is intentionally not registered.
- Full Vista is authoritative only for fixtures carrying `vista_context`.

## Validation

- Catalog coverage, corner orientation, face-slice eligibility, exclusion,
  transform parity, rendered-position parity, and context purity are covered by
  `sundered_keep_shoreline_compositor_smoke.gd`.
- Production bundle layering is covered by the procgen vista and world-vista
  smokes.
- Automated lab captures live under
  `reports/visual_labs/sundered_keep_shoreline/vocabulary_context/`.
