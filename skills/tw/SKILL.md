---
name: tw
description: Pull taskwarrior/Linear context for the current directory or a named project/issue/milestone — run before starting work in a project dir, when the user asks what they should be working on, mentions a task or Linear identifier, or wants task notes as context
---

# Task context (taskwarrior ↔ Linear ↔ Obsidian notes)

The `taskwarrior_linear` CLI bridges Taskwarrior, Linear, and the notes vault (`~/obsidian/Tasks`, one markdown file per issue/task). Use it to ground work in the user's actual task list.

## By current directory

1. Run `taskwarrior_linear here --json` — tasks whose work dirs cover $PWD. Empty result usually means no `workdirs.toml` mapping for this project; say so and move on.
2. Read the notes: each entry's `note` field when `note_exists` is true. `taskwarrior_linear here --notes` prints just the existing paths.
3. Summarize: what's pending, what blocks on what, and any note content that bears on the work. Don't dump JSON.

## By project / issue / milestone

When the user names a scope instead of a directory:

- `taskwarrior_linear show <ref>` — one task + its linked issue/milestone/project and everything it blocks on
- `taskwarrior_linear here --json --dir <workdir>` — scope by a mapped directory
- `taskwarrior_linear context list` — see existing scopes

## Taskwarrior context (global state — handle with care)

`taskwarrior_linear context <ref>` scopes ALL taskwarrior output (reports, `taskwarrior-tui`) to a project/issue/milestone and its children; `context none` clears it.

- Only set a context when the user explicitly asks
- Always say which context you set, and clear it (`context none`) when the work session ends — it silently filters every later `task` command

## Useful follow-ups

- `taskwarrior_linear sub <IDENT> "description"` — add a local-only subtask (never pushed to Linear); the parent issue blocks on it. Say you did this.
- `taskwarrior_linear done <id>` — completes the task; issue-tasks also move the Linear issue to Done. Outward action: confirm with the user first.
- `taskwarrior_linear map <ref> <dir>` — persist a work-dir mapping so `here` picks this project up next time.
- `taskwarrior_linear sync push` — after task/note changes, if the user syncs machines.

## Conventions

- Issue-task descriptions start with the Linear identifier (`VOIP-5914 Sample prod convos`); subtasks share the identifier.
- `[project]` / `[milestone]` prefixed tasks are umbrella tasks — they block on their children; don't `done` them by hand.
- `⇢`/`D` marks tasks that wait on others; a pending umbrella means its children aren't all done.
