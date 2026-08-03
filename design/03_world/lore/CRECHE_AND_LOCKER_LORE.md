# Custodian Crèches and Crèche Lockers — Lore

> **Status:** active lore — Custodian institutional infrastructure canon
> **Created:** 2026-08-03
> **Last Updated:** 2026-08-03
> **Source:** Two-section lore drop. SECTION 1 = **First Draft**; SECTION 2 = **Refinement**.
> **Precedence:** SECTION 2 (the refinement) **takes precedence** wherever it conflicts with SECTION 1. Where SECTION 2 is silent, SECTION 1 stands.
> **Lore Canon Authority:** `design/03_world/lore/CORE_LORE.md` — this document is a content-facing lore reference and must stay consistent with that canon.
> **Related Docs:** `design/03_world/GAME_PROTOCOLS_AND_WORLD_LORE.md`, `design/04_architecture/HOME_CUSTODIAN_FIELD_TERMINAL.md`, `design/02_features/operator/SIDEARM_UNLOCK.md`, `custodian/docs/ai_context/CURRENT_STATE.md`

---

## Canon Summary (from SECTION 2)

The P-9 sidearm is **assigned to the Custodian designation, not proven to belong to the person currently carrying it**. During the `custodian_home` terminal-recognition phase, the crèche recognizes or issues the player's Custodian designation; that designation already carries an equipment assignment, so the locker releases the P-9. The system does **not** answer whether the designation belonged to the same person before, whether the player died and was restored, whether the designation has passed through multiple bodies, or whether this is genuinely the player's first awakening with the weapon provisioned in advance. The crèche treats all of those possibilities as operationally equivalent. **It verifies continuity of assignment without verifying continuity of personhood.**

---

## SECTION 1 — First Draft

### Custodian Crèches

Crèches were institutional recovery sites where Custodians were returned to service after death, catastrophic injury, memory failure, or prolonged disappearance. Whether they genuinely resurrected the dead, rebuilt surviving bodies, or simply issued the identity to a replacement is deliberately unclear.

They were designed to feel medical and protective, but operated more like automated military processing centers. A Custodian awakened, received a designation, underwent a basic readiness assessment, and was sent back into the field—often with little explanation of what had happened before.

### Crèche Lockers

Each recovery bay had an assigned locker containing the equipment considered essential to that Custodian's continued service:

- sidearm and ammunition;
- damaged or recovered personal effects;
- mission credentials and route authority;
- sealed records from previous deployments.

The locker was tied to the **Custodian designation**, not necessarily to the person occupying it. A newly awakened Operator could therefore inherit weapons, effects, and unresolved duties belonging to an earlier version of themselves—or to someone else who once carried the same designation.

### The sinister implication

The crèche does not distinguish between healing a person and replacing an asset. Its systems recognize authorization, continuity, and operational need—not identity.

A locker opening is therefore both reassuring and disturbing: the institution remembers what the Custodian requires, even when it no longer remembers—or refuses to reveal—who the Custodian was.

---

## SECTION 2 — Refinement (Takes Precedence Over SECTION 1)

### The designation, not the person

Yes—that distinction is the core of it:

**The P-9 is assigned to the designation, not proven to belong to the person currently carrying it.**

During the `custodian_home` terminal-recognition phase, the crèche recognizes or issues the player's Custodian designation. That designation already carries an equipment assignment, so the locker releases the P-9.

But the system does **not** answer whether:

- this designation belonged to the same person before;
- the player died and was restored;
- the designation has passed through multiple bodies;
- or this is genuinely the player's first awakening, with the weapon provisioned in advance.

The crèche treats all of those possibilities as operationally equivalent. That is the disturbing part: **it verifies continuity of assignment without verifying continuity of personhood.**

### Crèche-locker lore

Crèche lockers are keyed to Custodian designations. They retain the weapons, credentials, and field equipment attached to that designation between activations.

When a crèche recognizes a designation, its associated locker becomes accessible. The system does not describe the equipment as previously owned, inherited, or newly issued. It merely confirms that the assignment remains valid.

The P-9 therefore provides no proof that the player existed before awakening. It only proves that the institution expected **someone bearing this designation** to require it.

### Recommended item description

> A standard Custodian sidearm registered to the designation recognized by the crèche. No surviving record explains when the assignment was made.

That preserves every possibility without inventing an operator record or declaring that the weapon personally belonged to "you."

### Recommended acquisition presentation

```text
P-9 FIELD SIDEARM RECOVERED
DESIGNATION MATCH CONFIRMED
```

That subtitle reports exactly why the locker opened. It does not claim prior personal ownership, resurrection, or replacement.

A slightly more procedural alternative:

```text
P-9 FIELD SIDEARM RECOVERED
ASSIGNED ARMAMENT RELEASED
```

Preference: **DESIGNATION MATCH CONFIRMED** — it quietly reinforces the central mystery: the system recognizes the designation with certainty, while the player still has no idea what that recognition actually says about them.

---

## Runtime Alignment Note

This document is **lore authority only**; it does not change runtime behavior.

- The `custodian_home` terminal-recognition phase referenced above is defined in `design/04_architecture/HOME_CUSTODIAN_FIELD_TERMINAL.md` (Objective 01: RETURN TO POST, witness contact with the Custodian Field Terminal).
- The P-9 Field Sidearm's current runtime expression is the Sundered Keep **field-retention locker** at `[73, 27]`, implemented per `design/02_features/operator/SIDEARM_UNLOCK.md` (recovery into carried inventory, then Equipment-page equip).
- Whether the crèche locker is later realized directly inside the home scene is a downstream implementation decision, not settled here. Any such realization must preserve the Section 2 constraint: the acquisition presentation may report designation recognition, never prior personal ownership, resurrection, or replacement.
