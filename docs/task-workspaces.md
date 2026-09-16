# Task Workspaces — design notes

> **Status: shelved** (2026-09-16). Captured from discussion; resume when
> file/workspace linking is wanted. Everything here is additive to the
> bridge — no schema changes required for the recommended path.

Goal: workflows for mapping **files** and **tmux sessions** to a task,
beyond the directory-level `workdirs.toml` mapping that `here` already uses.

## 1. Pin a list of files to a task

| Option | How | Trade-off |
|---|---|---|
| **Note-embedded** | `## Files` section in the task's Obsidian note, one link per line | Syncs via the Tasks git repo · clickable in Obsidian · greppable · agent-readable · matches the `## Next steps` convention. Wrinkle: paths are machine-specific (same caveat as workdirs.toml). |
| **workdirs.toml** | `[task."VOIP-5914"] files = [...]` beside `dirs` | One config, one resolver; `map` grows a `--file` mode. Machine-local — arguably correct since checkouts differ per box. |
| **Taskwarrior UDA** | `task 12 modify files:a.md,b.md` | Weakest: UDA strings choke on spaces/commas; clutters every report. |
| **nvim session file** | `:mksession` to `Tasks/.sessions/VOIP-5914.vim` | Restores tabs/windows/buffers exactly — a *workspace*, not a file list. Heavier; layer later via possession.nvim. |

**Lean:** `## Files` in the note — zero new schema, syncs, human-editable.
CLI reads it the way `sod` reads Next steps: a `files <ref>` command prints
paths; nvim's task picker gains a mapping that edits each (or drops them
into a fresh tab). File list is 80% of the value; window layouts layer on
top only if missed.

Prior art: `taskopen` — classic TW tool opening files/URIs attached to a
task via annotations. Predates the bridge, knows nothing of Linear/notes,
but validated the pattern.

## 2. Pin a tmux session to a task

Key move: **don't store the pin — derive it.** Name the session after the
Linear identifier; session `VOIP-5914` *is* the task's session. "Open task
workspace" becomes pure lookup:

```sh
tmux attach -t VOIP-5914 2>/dev/null || (cd <workdir> && tmux new -s VOIP-5914)
```

No UDA, no toml entry, self-documenting in `tmux ls`, identical from either
machine. `<workdir>` resolution rides the existing workdirs.toml machinery.

## 3. Persistence across reboots

tmux has none natively. Two routes:

- **tmux-resurrect + tmux-continuum** — resurrect snapshots layouts
  (window/pane dirs, sizes) to disk; continuum auto-saves every 15 min and
  auto-restores when the tmux server starts. Closest to true persistence:
  after reboot sessions reappear with names intact, panes back in their
  dirs. Running processes restore only approximately; long-lived daemons
  don't survive.
- **tmuxp / tmuxinator / sesh** — declarative YAML per session; "restore" =
  re-create from spec. Loses process state entirely but deterministic and
  versionable. **sesh** is the modern option: sessions-per-directory, fzf
  picker, zoxide integration — built for exactly this project↔session
  workflow.

**Lean:** derived names + resurrect/continuum. Session `VOIP-5914` with
continuum auto-restore ≈ pinned across reboots, zero per-task config. Add a
tmuxp YAML keyed by the same ident only if fixed window layouts per task
("editor | server | tests") turn out to matter.

## 4. Unified command

```
taskwarrior_linear workspace <ref>
  --files   print the task's pinned files
  --tmux    attach-or-create the named session; first window in the
            workdir, optional second window in nvim with the pinned
            files / note
```

Neovim: `:TWHere` / `:TWTasks` gain a mapping (say `<C-w>`) shelling out to
`workspace --tmux`.

## 5. The daily shape this buys

sod briefs → pick a task → one command lands in the right tmux session,
right dir, right files in nvim, note one keystroke away → eod sees
everything, because it was all task-linked from the start.

## 6. Open questions for the resume

- Machine-specific file paths: accept per-machine pinning (note content
  diverges across sync) or keep pins machine-local in workdirs.toml?
- Does a file list suffice, or do window layouts earn their keep?
- Should `workspace` open the task note in a second window by default?
