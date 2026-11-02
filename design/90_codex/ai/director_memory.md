# Director Memory

Status: candidate
Category: ai
Priority: P1
Maturity: system
Cost: medium
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

The encounter director remembers how the player behaves instead of only tracking difficulty.

## Problem it solves

Most adaptive difficulty reacts only to deaths. This system reacts to habits.

## Why it fits CUSTODIAN

Enemy factions should appear to study and adapt to the Operator.

## Player-facing effect

Examples:

Player relies on rifle, so enemies begin carrying shields.

Player always retreats, so enemies attempt flanking.

Player never repairs armor, so enemies use sustained suppression.

## Systems touched

Enemy Director, combat, AI, telemetry.

## Dependencies

Developer Observatory.

## Risks

Must feel believable rather than punitive.

## Minimal version

Track weapon preference and healing frequency.

## Full version

Behavioral clustering and faction-specific adaptation.

## Graduation criteria

Graduate once multiple enemy factions exist.

## Notes / references

Related: Navigation and Combat Heatmaps, Simulation Camera, Faction Knowledge System.

