# UID Duplicate Error Fix

**Date:** 2026-03-31
**Issue:** Godot UID system conflicts when duplicate files exist with shared UIDs

---

## Root Cause

When you copy sprite files between directories (e.g., `default_locomotion/` → `default/`), Godot's UID system assigns UIDs based on file content hash. If the source files had identical content, they get the same UID — but now point to different source files.

**Affected pairs:**
| Source A | Source B | Shared UID |
|----------|----------|------------|
| `default/run_right_body.png` | `default_locomotion/run_right_body.png` | uid://cnmplpgp62rvr |
| `default/walk_down_body.png` | `default_locomotion/walk_down_body.png` | (same UID) |
| `default/walk_right_body.png` | `default_locomotion/walk_right_body.png` | (same UID) |
| `default/walk_up_body.png` | `default_locomotion/walk_up_body.png` | (same UID) |
| `enemy.tres` | `archive/enemy_drone_legacy.tres` | (shared UID) |

---

## Fix Strategy

### Option A: Quick Fix — Regenerate UIDs (Recommended)

**For each duplicate pair:**

1. Open the `.import` file in a text editor
2. Change the `uid="uid://..."` to a new unique value
3. Save and restart Godot — it will regenerate

**Example fix for `run_right_body.png`:**

In `default/run_right_body.png.import`:
```ini
uid="uid://cnmplpgp62rvr"  # BAD — conflicts with default_locomotion/
```
Change to:
```ini
uid="uid://unique_NEW_uid_123"  # GOOD — unique
```

**How to generate new UID:**
- Use any random 12-character hex string after `uid://`
- Example: `uid://a1b2c3d4e5f6`

---

### Option B: Full Fix — Remove Duplicate Files

If `default/` and `default_locomotion/` contain identical sprites, consolidate to one location:

1. Delete the entire `default_locomotion/` folder (or move to archive)
2. Delete the `.import` cache: `rm -rf .godot/imported/`
3. Restart Godot — it will re-import all files with fresh UIDs

**Pros:** Clean, no more duplicates
**Cons:** If files ARE different, this breaks references

---

## Step-by-Step Fix (Option A)

### 1. Fix Sprite UIDs (5 files in `default/` folder)

Edit these files and change the UID to be unique:

| File | Current UID | New UID Suggestion |
|------|-------------|---------------------|
| `default/run_right_body.png.import` | uid://cnmplpgp62rvr | uid://drunr001 |
| `default/walk_down_body.png.import` | (same) | uid://dwnkd001 |
| `default/walk_right_body.png.import` | (same) | uid://dwnkr001 |
| `default/walk_up_body.png.import` | (same) | uid://dwnku001 |

**Script to find UIDs:**
```bash
cd ~/Projects/CUSTODIAN/custodian/assets/sprites/operator/runtime/curated/body/default
grep -h "uid=" *.import | sort -u
```

### 2. Fix Enemy .tres UID

In `entities/enemies/archive/enemy_drone_legacy.tres`:
- Add `uid="uid://unique_NEW_uid"` to the first line after `[gd_resource]`

Or simply delete the legacy file if not used:
```bash
rm custodian/entities/enemies/archive/enemy_drone_legacy.tres
```

### 3. Clear Godot Import Cache

After fixing UIDs:
```bash
cd ~/Projects/CUSTODIAN/custodian
rm -rf .godot/imported/
# Then restart Godot — it will re-import everything
```

---

## Verification

Restart Godot and check for warnings in output:
- Should see **zero** UID duplicate warnings
- If warnings persist, check for additional duplicate pairs

---

## Prevention

When copying sprite files in Godot:
1. **Don't copy .import files** — copy only the source .png files
2. **Or** use Godot's built-in duplicate rather than filesystem copy
3. **Or** run `rm -rf .godot/imported/` after any bulk file operations