# Operator Animation Events

Operator combat does not use animation-key events as simulation authority.
Attack windows, guard phases, damage reactions and action completion are owned
by fixed-tick gameplay systems. Presentation callbacks may observe clip
completion, but must not create hit windows or advance combat state.

For animation identity and playback ownership, see the parent
`animations/README.md`. For attack timing, see the active combat-feel design and
the Operator runtime architecture contract.
