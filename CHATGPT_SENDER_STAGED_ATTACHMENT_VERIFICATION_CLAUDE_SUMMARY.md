# ChatGPT sender attachment and submit verification

Workstream: `chatgpt-sender-staged-attachment-verification`

Updated `custodian/tools/orchestration/send_chatgpt_message.py` to read staged
attachment chips from the exact composer form as well as populated file inputs.
An exact staged filename set is reused without another upload; mismatched sets,
attachments not requested by the caller, and duplicate requested basenames fail
closed.

The `--submit` path clicks Send once and waits for a new user message matching
the requested text, a cleared composer, and cleared attachment state before it
prints `SENT`. If those signals do not arrive, it reports the send as
unconfirmed and explicitly says not to retry automatically.

Validation performed:

- Python AST parse passed.
- CLI dry run passed for the exact CUSTODIAN conversation URL; it reported that
  no browser state changed.
- No live submit was attempted. The existing browser composer draft and its
  staged files were left untouched, so real-browser integration remains
  unverified.
