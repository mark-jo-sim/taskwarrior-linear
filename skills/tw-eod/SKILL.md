---
name: tw-eod
description: End-of-day review — everything that changed in tasks and notes over the last 24 hours (rolling window, timezone-safe), then progress against the EOD goals, walked through with the user. Trigger on "end of day", "EOD", "wrap up", "daily review", "day is done"
---

# End of day

Use a **rolling 24-hour window**, never the calendar day — machines and the
sync server may sit in different timezones. "Past 24h" means exactly that.

## What changed

```sh
TWL_VAULT="${TWL_VAULT:-$HOME/obsidian/Tasks}"
# UTC cutoff 24h ago (BSD date = macOS; fallback GNU date)
CUTOFF=$(date -u -v-24H +%Y%m%dT%H%M%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y%m%dT%H%M%SZ)
# tasks modified in the window — TW timestamps are UTC YYYYMMDDTHHMMSSZ
task status.not:deleted export | jq --arg cutoff "$CUTOFF" 'map(select(.modified >= $cutoff))'
# notes edited in the window (mtime is rolling, excludes the goals file)
find "$TWL_VAULT" -name '*.md' -mtime -1 -not -name 'EOD-*'
```

From the task JSON, group and report:

- **completed** — has `end` within the window; name them
- **added** — `entry` within the window (new tasks, subtasks, umbrellas)
- **modified** — annotations, project/priority changes, new deps; say what
  changed where visible

Read each edited note; report what moved in it (new or worked `## Next
steps`, checked-off subtask lines). Don't paste whole files.

## Goals review

- Find the goals file: newest `"$TWL_VAULT"/EOD-*.md` modified within 24h
  (else the newest one; if none, say so and review without goals)
- For each goal: **met / partially met / missed**, citing the evidence from
  the changed tasks and notes above
- Walk the verdicts through with the user — they confirm or correct each
  one; then update the checkboxes in the goals file to match reality
- Missed/partial goals: if the user agrees, append them under
  `## Carried over` in the goals file so tw-start picks them up tomorrow

## Wrap up

- Offer `taskwarrior_linear sync push` (tasks + notes + goals file)
- If a taskwarrior context is active (`task context show`), suggest
  `taskwarrior_linear context none`
