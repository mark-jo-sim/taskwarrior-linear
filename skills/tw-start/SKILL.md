---
name: tw-start
description: Start the workday — run the sod briefing (open Linear issues, +active tasks, notes' "## Next steps"), then draft end-of-day goals with the user into the journals dir. Trigger on "start the day", "morning routine", "what should I work on today", "draft EOD goals"
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

## Brief the user

Summarize the sod output, don't dump it:

- active tasks and their next steps — quote the concrete actions, not the headings
- due-today / overdue work
- open issues worth importing (suggest `import` only if the user wants to work them)
- if nothing is `+active` or no notes have Next steps, say so and suggest the
  conventions: `task <id> modify +active`, `## Next steps` section in notes

## Draft EOD goals

- Propose goals **from the next steps of active tasks** — concrete and
  checkable ("annotate 20 prod conversations"), not vague ("make progress
  on dataset")
- Iterate with the user until they accept the set — goals are theirs
- Write to the journals dir (`$TWL_JOURNALS_DIR`),
  file `EOD-$(date +%F).md`:

```markdown
---
date: YYYY-MM-DD
---

# EOD goals — YYYY-MM-DD

- [ ] first goal
- [ ] second goal
```

- If the newest existing `EOD-*.md` there has missed or unchecked goals, ask
  whether to carry them into today's list (tw-eod marks them under
  `## Carried over`)
- Offer `taskwarrior_linear sync push` afterwards
