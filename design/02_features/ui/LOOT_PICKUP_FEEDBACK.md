# Loot Pickup Feedback

Status: implemented-v1

## Purpose

All collectible feedback routes through one HUD queue while retaining the
existing small world-space floating text. This gives parts, cognitive items,
ammo, field patches, and stolen vault resources a shared readable channel.

## Runtime contract

`LootToastQueue` is mounted beneath the main HUD at `(18,126)` and registers
the `loot_toast_queue` group. Producers call `push_pickup(item_id, display_name,
quantity, accent, icon, detail)`. Four entries remain visible at most; matching
items merge for `0.75s`. Entries animate in for `0.12s`, hold for `1.80s`, and
fade/slide out for `0.25s`.

The queue is presentation-only. Inventory, material, vault, ammo, and consumable
authorities remain in their existing owning systems. Stolen resources use one
summary entry listing each recovered resource in the detail line.

Depleting a harvest node pushes one entry for each primary and secondary yield,
using the resource definition label and its single-frame inventory icon. Forest
Shrumb cognitive pickups likewise use their single-frame 64px item icons in the
toast; their animated four-frame sheets remain world-pickup presentation only.

## Visual contract

Entries are `320×52` panels with a 4px category accent, optional 32px icon,
14px title, and 11px detail. The initial style uses a dark `StyleBoxFlat` with
1px border, 3px corners, and a small black shadow; no new artwork is required.
