# Sundered Keep game32 extraction: documentation drift review

Generated assets: `62`

## Checks
- `OK` — repo_guidance: `/home/braydenchaffee/Projects/CUSTODIAN/AGENTS.md`
- `OK` — active_ai_context_current_state: `/home/braydenchaffee/Projects/CUSTODIAN/custodian/docs/ai_context/CURRENT_STATE.md`
- `OK` — active_ai_context_context: `/home/braydenchaffee/Projects/CUSTODIAN/custodian/docs/ai_context/CONTEXT.md`
- `OK` — active_ai_context_file_index: `/home/braydenchaffee/Projects/CUSTODIAN/custodian/docs/ai_context/FILE_INDEX.md`

## Potential drift
- CURRENT_STATE.md does not appear to mention the generated Sundered Keep runtime asset set.
- FILE_INDEX.md does not appear to list content/runtime/sundered_keep outputs.
- CONTEXT.md may not mention the Sundered Keep master/runtime asset workflow.

## Recommended action
Add a short note to custodian/docs/ai_context/CURRENT_STATE.md and FILE_INDEX.md that Sundered Keep masters live under content/masters/sundered_keep and generated runtime slices/metadata live under content/runtime/sundered_keep. This is an asset-pipeline update, not a gameplay behavior change.
