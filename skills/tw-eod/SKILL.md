---
name: tw-eod
description: End-of-day review — run the eod command (tasks finished/added/changed and notes edited in the last 24 hours, rolling window), read the changed notes, then review progress against today's Obsidian daily note's EOD goals with the user. Trigger on "end of day", "EOD", "wrap up", "daily review", "day is done"
---

# End of day

The deterministic gathering is one command (rolling 24h window — timezone-safe
by construction):

```sh
taskwarrior_linear eod            # or --json
```

It buckets tasks finished / removed / added / changed since the cutoff and
lists notes edited in the window. Read each edited note to see what moved in
it (new or worked `## Next steps`, checked-off subtasks) — don't paste whole
files, report the movement.

## Goals review

- The journal is today's Obsidian daily note —
  `~/obsidian/journals/YYYY-MM-DD.md`, the same file `:ObsidianToday` opens
  (obsidian.nvim `daily_notes.folder` is `journals`). Ignore the
  `EOD-<date>.md` path the eod output names — legacy location, superseded by
  the daily note. If today's note is missing, create it with:

  ```sh
  nvim --headless "+ObsidianToday" +qa
  ```

- Goals live under `## Prepare` → `### EOD goals` in that note. If the note
  has none (placeholders or empty), review without goals and say so
- For each goal: **met / partially met / missed**, citing evidence from the
  changed tasks and notes
- Walk the verdicts through with the user — they confirm or correct each
  one; then update the `### EOD goals` checkboxes in the note to match
  reality
- Fill in `## Review` as you go: `### Progress` with the day's movement
  (finished/added/changed tasks, notes edited), `### Blockers` with what
  stalled and why
- Missed/partial goals: if the user agrees, append them under
  `### Plan` — tomorrow's tw-start carries `### Plan` items into the new
  note's `### EOD goals`

## Wrap up

- Offer `taskwarrior_linear sync push` (tasks + notes)
- If a taskwarrior context is active (`task context show`), suggest
  `taskwarrior_linear context none`
