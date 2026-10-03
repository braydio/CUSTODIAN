# Review Runtime Change

Repository workflow and review defaults are inherited from
`custodian/AGENTS.md`.

## Task

Review this runtime change: {{change_or_diff_scope}}

**Active design authority:** {{design_doc}}

**Relevant task acceptance:** {{acceptance_or_none}}

## Output

Report findings first, with file and line references. Assign stable cycle IDs
(`R<cycle>-<NN>`) and record each finding's class (`blocking_defect`,
`evidence_gap`, `non_blocking_issue`, `optional_improvement`), domain
(`implementation`, `pipeline`), affected acceptance, evidence, disposition,
and rationale. Prioritize behavior or determinism regressions, ownership leaks,
stale documentation, missing proof for the changed behavior, and unsafe side
effects. Distinguish confirmed failures from questions or assumptions.

Recommend correction work only for confirmed acceptance/correctness defects or
evidence gaps that prevent confidence in required acceptance. Route other
issues to next-slice/deferred unless separately justified. Treat pipeline and
process failures as task feedback, not product-code findings. Preserve independence: paired reviews must run from a **fresh reviewer context** that is separate from the implementation session. The same model/agent family may review its own prior work only as `same-agent-fresh-context`, reconstructing the task from durable repository evidence and fresh traces/mutations; continuing the implementation conversation/session is not independent review. Record reviewer context/provenance in the durable receipt. Paired reviews never edit reviewed implementation files. Use the
repository's V2 review packet and correction delta template, then summarize the
change only after findings.
