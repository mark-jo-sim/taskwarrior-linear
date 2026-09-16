---
name: tw-start
description: Start the workday — gather open Linear issues, active (+active) tasks, and their notes' "## Next steps" sections, brief the user, then draft end-of-day goals together. Trigger on "start the day", "morning routine", "what should I work on today", "draft EOD goals"
---

# Start of day

Morning briefing + EOD goal drafting. Notes live in `~/obsidian/Tasks`
(override: `$TWL_VAULT`) — one markdown file per issue/task.

## Gather

```sh
TWL_VAULT="${TWL_VAULT:-$HOME/obsidian/Tasks}"
taskwarrior_linear issues              # my open Linear issues
task status:pending +active            # tasks the user marked active
grep -l '^## Next steps' "$TWL_VAULT"/*.md   # notes carrying next steps
task status:pending due.before:tomorrow      # due today / overdue
```

Read each matched note's `## Next steps` section (to the next heading or
EOF). For active tasks with thin context, `taskwarrior_linear show <id>`.

## Brief the user

Summarize, don't dump:

- active tasks and their next steps — quote the concrete actions, not the headings
- open issues not yet imported as tasks — suggest `import` for any the user wants to work
- due-today / overdue work

## Draft EOD goals

- Propose goals **from the next steps of active tasks** — concrete and
  checkable ("annotate 20 prod conversations"), not vague ("make progress
  on dataset")
- Iterate with the user until they accept the set — goals are theirs
- Write to `"$TWL_VAULT/EOD-$(date +%F).md"` (local date):

```markdown
---
date: YYYY-MM-DD
---

# EOD goals — YYYY-MM-DD

- [ ] first goal
- [ ] second goal
```

- If yesterday's `EOD-*.md` has missed or unchecked goals, ask whether to
  carry them into today's list
- Offer `taskwarrior_linear sync push` so goals reach the other machines

To mark a task active for future mornings: `task <id> modify +active`.
