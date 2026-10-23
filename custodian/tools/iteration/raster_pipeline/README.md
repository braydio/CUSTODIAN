# Humanoid raster pipeline (review only)

This plan driven helper extracts directional humanoid ROIs, measures alpha and
foot registration, exports 96×96 candidates through the existing
`custodian_pixelart_converter.py`, and reports pixel facts. It is not an art
approval or an Asset V2 ingest path. It does not modify source art, the original
12 Grunt previews, runtime content, family metadata, or inbox files.

From the repository root, reproduce the Grunt candidate set with:

```bash
python3 custodian/tools/iteration/raster_pipeline/raster_pipeline.py \
  --plan custodian/tools/iteration/grunt_candidate_ab/grunt_raster_plan.json \
  --out .ai/grunt-candidate-raster-workflow-v1/out
```

The pinned plan names four directional source ROIs and a source SHA-256. The
output contains one 12-image set per declared converter mode under `crisp/`,
`balanced/`, and `clustered/`, plus stable `raster_report.json`. The three
conversion methods call the existing converter's actual candidate functions;
edge cleanup is disabled so highlights and disconnected source details are
never silently erased. The report includes source and output hashes, measured
alpha/contact bounds, palette counts, bright isolated pixels, near-black foot
regions, alpha fringe counts, and placement error. These are measurements, not
visual quality scores. Registration reports the actor-space ground projection
from the measured frame row, AnimatedSprite offset/centering, and the Grunt
collision ground. The pinned baseline is a 0.5px residual against a declared
1px tolerance; it is reported as within tolerance, not exact alignment.

Open `custodian/game/actors/enemies/dev/grunt_candidate_ab.tscn` and press **M**
to switch the candidate converter mode, **1/2/3** to select body height, and
Left/Right for facing. Its missing, invalid, or empty image state is displayed
on screen. The dev harness remains dev only and keeps the baseline comparison
images intact.

Cleanup is report only by default. To create a cleaned *copy* requires a
separate reviewed JSON approval (`custodian.raster_cleanup_approval.v1`) naming
the candidate SHA, reviewer, and exact before/after RGBA values for each unique
coordinate. Pass it as `--cleanup-approval <file>` with the same `--out`; the
tool checks every preimage and writes a reversible audit and cleaned copy under
`approved_cleanup/`. The original candidate and source remain untouched.

Outputs must resolve to a Git-ignored review directory. Source hashes, ROI
bounds, output containment, dimensions, and all cleanup preimages fail closed.
If the source is missing or is an unhydrated Git LFS pointer, the tool reads
the plan's checked-in ZIP member, verifies its bytes against the pinned source
SHA, then extracts only into the ignored output workspace. Any ordinary source
hash mismatch or fallback hash mismatch fails closed. Human selection of the
best material rendering and sole alignment remains separate from the tooling
result.
