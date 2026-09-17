---
name: tw-start
description: Start the workday — run the sod briefing (open Linear issues, +active tasks, notes' "## Next steps"), then draft end-of-day goals into today's Obsidian daily note. Trigger on "start the day", "morning routine", "what should I work on today", "draft EOD goals"
---

# Start of day

The deterministic gathering is one command:

```sh
taskwarrior_linear sod           # or --json
```

It returns: `+active` tasks (with each note's `## Next steps` section),
every note carrying a `## Next steps` heading, and due-today/overdue tasks.
Add open Linear issues with `taskwarrior_linear issues` when the user wants
the full picture.

## Today's daily note

The journal is the Obsidian daily note — `~/obsidian/journals/YYYY-MM-DD.md`,
the same file `:ObsidianToday` opens (obsidian.nvim `daily_notes.folder` is
`journals`). Ignore the `EOD-<date>.md` path the sod output names — legacy
location, superseded by the daily note.

- If today's note doesn't exist yet, create it already populated (Calendar
  table + Tasks, from the vault's `_meta/templates/daily_note.md` template):

  ```sh
  nvim --headless "+ObsidianToday" +qa
  ```

- If it exists, it was created through the same template — don't re-run the
  script substitutions or duplicate those sections; edit in place
- Goals go under `## Prepare` → `### EOD goals`, replacing the `- [ ] item`
  placeholders

## Brief the user

Summarize the sod output, don't dump it:

- active tasks and their next steps — quote the concrete actions, not the headings
- due-today / overdue work
- open issues worth importing (suggest `import` only if the user wants to work them)
- the day's meetings from the note's `## Calendar` section — they bound what
  fits; flag conflicts with the goals you're about to draft
- if nothing is `+active` or no notes have Next steps, say so and suggest the
  conventions: `task <id> modify +active`, `## Next steps` section in notes

## Draft EOD goals

- Propose goals **from the next steps of active tasks** — concrete and
  checkable ("annotate 20 prod conversations"), not vague ("make progress
  on dataset")
- Iterate with the user until they accept the set — goals are theirs
- Write them under `### EOD goals` in today's daily note
- Carry-over: read the newest earlier `journals/*.md` (by date, not mtime).
  Its `## Review` → `### Plan` section (written by tw-eod) and any unchecked
  `### EOD goals` there are candidates — ask whether to carry them into
  today's list, then check them off or strike them in the old note so they
  can't be carried twice
- Offer `taskwarrior_linear sync push` afterwards
