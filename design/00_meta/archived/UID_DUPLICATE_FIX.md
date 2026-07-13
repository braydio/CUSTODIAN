# UID Duplicate Error Fix

**Date:** 2026-06-22
**Issue:** Godot UID system conflicts when duplicate files exist with shared UIDs

---

## Root Cause

When you copy sprite files between directories (e.g., `default_locomotion/` → `default/`), Godot's UID system assigns UIDs based on file content hash. If the source files had identical content, they get the same UID — but now point to different source files.

**Affected duplicate domains:**

| Canonical location | Noncanonical location | Role |
|---|---|---|
| `custodian/content/sprites/operator/runtime/curated/body/default/` | `custodian/content/sprites/operator/runtime/curated/body/default_locomotion/` | normalized active files vs. legacy staging |
| `custodian/content/tiles/interiors/runtime/` | `custodian/content/tiles/interiors/temp/` | runtime tiles vs. temporary source/staging |
| `custodian/content/props/gothic/` | `custodian/props/gothic/` | runtime props vs. legacy duplicate |

The historical `enemy.tres` / `archive/enemy_drone_legacy.tres` collision should be handled with the same
noncanonical-metadata workflow if it recurs.

---

## Fix Strategy

### Option A: Regenerate Noncanonical Imports (Recommended)

For each duplicate pair:

1. Confirm which side is canonical using the table above and search runtime resources/scenes for references.
2. Delete only the `.import` metadata on the noncanonical side. Do not delete the source PNG.
3. Clear `custodian/.godot/imported/`.
4. Start Godot once so it regenerates valid import metadata and UIDs.

Do not hand-write or invent UID strings. Godot owns generated import UIDs.

---

### Option B: Full Fix — Remove Duplicate Files

If a later migration explicitly removes duplicate source art, consolidate only after all runtime references have
been moved to the canonical location:

1. Update all runtime references to the canonical location.
2. Validate scenes and resources.
3. Delete or archive the noncanonical source only when that removal is explicitly in scope.
4. Delete the `.import` cache: `rm -rf custodian/.godot/imported/`.
5. Restart Godot so it reimports the project.

**Pros:** Clean, no more duplicates
**Cons:** If files ARE different, this breaks references

---

## Step-by-Step Fix (Option A)

### 1. Confirm Runtime References

Search scenes, resources, and scripts before removing metadata:

```bash
cd ~/Projects/CUSTODIAN
rg -n "default_locomotion|tiles/interiors/temp|props/gothic" custodian \
  -g '*.tscn' -g '*.tres' -g '*.gd'
```

### 2. Remove Noncanonical Import Metadata

Delete the colliding `.png.import` files under:

- `custodian/content/sprites/operator/runtime/curated/body/default_locomotion/`
- `custodian/content/tiles/interiors/temp/`
- `custodian/props/gothic/`

Keep the PNGs unless production-art deletion is separately authorized.

### 3. Clear Godot Import Cache

After fixing UIDs:
```bash
cd ~/Projects/CUSTODIAN/custodian
rm -rf .godot/imported/
godot --headless --path . --editor --quit
```

---

## Verification

Restart Godot and check for warnings in output:
- Should see **zero** UID duplicate warnings
- If warnings persist, check for additional duplicate pairs

---

## Prevention

When copying source art:

1. Do not copy `.import` files; copy only source assets.
2. Prefer Godot's filesystem-aware move/duplicate operations when practical.
3. Keep runtime and staging ownership explicit in local READMEs.
4. Reimport and check the editor log after bulk asset operations.
