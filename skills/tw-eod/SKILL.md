---
name: tw-eod
description: End-of-day review — run the eod command (tasks finished/added/changed and notes edited in the last 24 hours, rolling window), read the changed notes, then review progress against the EOD goals with the user. Trigger on "end of day", "EOD", "wrap up", "daily review", "day is done"
---

# End of day

The deterministic gathering is one command (rolling 24h window — timezone-safe
by construction; it also names the latest EOD journal):

```sh
taskwarrior_linear eod            # or --json
```

It buckets tasks finished / removed / added / changed since the cutoff and
lists notes edited in the window. Read each edited note to see what moved in
it (new or worked `## Next steps`, checked-off subtasks) — don't paste whole
files, report the movement.

## Goals review

- Open the journal the `eod` output names — `$TWL_JOURNALS_DIR/EOD-<date>.md`. If it says "none yet", review without
  goals and say so
- For each goal: **met / partially met / missed**, citing evidence from the
  changed tasks and notes
- Walk the verdicts through with the user — they confirm or correct each
  one; then update the checkboxes in the journal to match reality
- Missed/partial goals: if the user agrees, append them under
  `## Carried over` so tw-start picks them up tomorrow

## Wrap up

- Offer `taskwarrior_linear sync push` (tasks + notes)
- If a taskwarrior context is active (`task context show`), suggest
  `taskwarrior_linear context none`
