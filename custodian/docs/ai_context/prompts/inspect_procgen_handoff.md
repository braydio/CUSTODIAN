# Inspect Procgen Handoff

Repository workflow and authority defaults are inherited from
`custodian/AGENTS.md`.

## Task

Inspect the handoff from {{procgen_system}} to {{target_system}}.

**Relevant design authority:** {{procgen_design_doc}}

**Known entrypoints:** {{generator_renderer_consumer_files}}

Trace only the handoff in scope. Check:

1. Data flow from generated output to the consumer.
2. Signals/events and their ordering across generation, rendering, or nav bake.
3. Runtime segments or streaming behavior when they participate in this path.
4. Ownership and integration boundaries relevant to the target system.

## Output

Record the handoff, key signals, file ownership, and unresolved assumptions in
the requested deliverable. Update current-state documentation only if this
inspection is authorized to change documentation and the current summary would
otherwise be stale.
