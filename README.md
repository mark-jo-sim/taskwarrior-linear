# taskwarrior-linear

Bridge [Linear](https://linear.app) into [Taskwarrior](https://taskwarrior.org) — issues, projects, and milestones become tasks; small one-off work stays local; every task can carry an [Obsidian](https://obsidian.md) note. Neovim pickers included.

```
[project] ASR error detection            ← Linear project (umbrella task)
├── VOIP-5914 Sample prod convos          ← Linear issue
│   ├── pull 20 random conversations      ← local subtask (never in Linear)
│   └── transcribe + spot-check           ← local subtask
└── [milestone] Labeled set of ASR errors ← Linear milestone (umbrella task)
    └── VOIP-5910 Annotation guidelines   ← Linear issue
```

## How it links

- Every task tied to a Linear issue carries a Taskwarrior UDA `linear` (the issue identifier, e.g. `ENG-123`), whether it's the issue itself or a local-only subtask.
- The issue-task `depends:` on its local subtasks — the issue stays blocked until its parts are done, the same model the umbrellas use. Subtasks carry the same UDA but no `depends` of their own. **Subtasks are never pushed to Linear** — break big issues down without cluttering the tracker.
- A Linear project imports as an umbrella task (`[project] name`, UDA `linearproject`) that `depends:` on its issue-tasks and milestone umbrellas. Issues also get Taskwarrior's dotted project hierarchy (`TEAMKEY.project-slug`).
- A Linear milestone imports as an umbrella task (`[milestone] name`, UDA `linearmilestone`) blocked on its issue-tasks. Umbrellas stay pending until their issues are done — an honest "not finished yet" signal.
- Completing an issue-task (`done`) also moves the Linear issue to Done. Umbrella completions never write back to Linear.
- Notes live at `<vault>/Tasks/<IDENT or uuid> <title>.md` with frontmatter (issue url, task uuid, description, subtask checklist).

## Requirements

- Python 3.8+ (stdlib only)
- Taskwarrior 3.x
- A Linear API key (linear.app → Settings → API)
- Neovim 0.9+ with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional)
- macOS (Keychain storage, `open`) — Linux works if you use the env-var/file key options and don't rely on `open`

## Install

```sh
git clone <this repo> taskwarrior-linear
cd taskwarrior-linear
./install.sh
```

The installer symlinks the CLI into `~/.local/bin` and the Neovim module into `~/.config/nvim/lua/`. Then:

**1. Taskwarrior UDAs** — add to `~/.taskrc` (installer prints this reminder):

```
uda.linear.type = string
uda.linear.label = Linear

uda.linearproject.type = string
uda.linearproject.label = LinearProject

uda.linearmilestone.type = string
uda.linearmilestone.label = LinearMilestone
```

**2. Linear API key** — pick one:

```sh
# macOS Keychain (recommended)
security add-generic-password -a "$USER" -s taskwarrior_linear -w "<key>"

# or a file
mkdir -p ~/.config/taskwarrior_linear && echo "<key>" > ~/.config/taskwarrior_linear/key
chmod 600 ~/.config/taskwarrior_linear/key

# or export LINEAR_API_KEY in your shell profile
```

Resolution order: `LINEAR_API_KEY` → key file → Keychain.

**3. Neovim** — add to your `init.lua` (after your plugin manager setup):

```lua
require("taskwarrior_linear").setup()
```

Optional config:

```lua
require("taskwarrior_linear").setup({
  cli = "taskwarrior_linear",  -- name/path of the CLI
})
```

**4. Obsidian vault** — defaults to `~/obsidian`; override with the `TWL_VAULT` environment variable.

## Usage

### CLI

```
taskwarrior_linear issues                        # my open Linear issues
taskwarrior_linear import ENG-123                # issue → task
taskwarrior_linear sub ENG-123 "small chore"     # local-only subtask
taskwarrior_linear note 1                        # create/open Obsidian note (or --print)
taskwarrior_linear open 1                        # open linked Linear issue in browser
taskwarrior_linear show 1                        # task + issue side by side
taskwarrior_linear done 1                        # finish task; issue-tasks close in Linear

taskwarrior_linear projects [--search X] [--lead me]   # list/filter projects
taskwarrior_linear milestones                          # list milestones
taskwarrior_linear import-project <slugId> [--all]     # umbrella + all open issues
taskwarrior_linear import-milestone <id> [--all]       # umbrella + its issues
```

`--all` imports every open issue; the default imports only issues assigned to you. `--lead` filters by project lead (`me` = projects you lead); `--search` is a case-insensitive name substring — both run server-side.

### Neovim

| Command | Action |
|---|---|
| `:LinearIssues` | telescope picker over my issues — `<CR>` import, `<C-o>` browser |
| `:LinearProjects [term]` | picker over projects — `<CR>` imports umbrella + issues |
| `:LinearMilestones` | picker over milestones — `<CR>` imports umbrella + issues |
| `:TWTasks` | picker over pending tasks — `<CR>` opens its note, `<C-o>` opens Linear |
| `:TWNote` | jump straight to a task's note |
| `<leader>tt` | toggle taskwarrior-tui terminal |

### Multi-machine sync (git only, no third-party services)

The notes dir (`<vault>/Tasks`) **is** the git repo — notes live directly in the working tree, git tracks them with no copying. Only the task DB needs bridging:

```
taskwarrior_linear sync push   # task export → tasks.json, commit, push
taskwarrior_linear sync pull   # pull, task import (uuid upsert)
```

How it works:

- `task export` covers **all** statuses — completions and deletions travel as tombstones; `task import` upserts by uuid (add / update / skip).
- Export emits one task per line, so git merges tasks.json cleanly; you only get a conflict when the *same task* changed on both machines since the last sync.
- Note edits/deletes are ordinary git working-tree changes — commit and merge like any file.
- The repo (default `~/obsidian/Tasks`, override with `TWL_SYNC_REPO`) auto-inits on first push, with a `.gitignore` for `.DS_Store`; add your remote once:

```sh
git -C ~/obsidian/Tasks remote add origin git@yourserver:git/tw-notes.git
```

Server side, once: `git init --bare ~/git/tw-notes.git`.

Ordering matters: run `sync push` after working on a machine and `sync pull` before working on the next — a pull from a stale repo resurrects tasks you deleted after its last push (the file predates the deletion). Twice-a-day cron on both machines works if edits don't overlap:

```
15 9,17 * * *  taskwarrior_linear sync pull && taskwarrior_linear sync push
```

### Work directories — tasks by where you are

Map projects to the directories you work in (`~/.config/taskwarrior_linear/workdirs.toml`):

```toml
[project."VOIP.asr-llm-driven-asr-error-detection"]
dirs = ["~/projects/asr-eval"]

[project."VOIP"]                       # team-level fallback
dirs = ["~/projects/voip"]

[task."VOIP-5914"]                     # per-issue dirs, in addition to project's
dirs = ["~/projects/data-sampling"]
```

Resolution per task, most specific first: a `workdir` UDA set on the task (`task 12 modify workdir:~/x`) → `[task.IDENT]` → `[project.TEAM.slug]` → `[project.TEAM]`. Subtasks inherit through their parent issue's project. A directory matches recursively — anything under a mapped dir counts.

Then:

```
taskwarrior_linear here            # tasks relevant to $PWD
taskwarrior_linear here --notes    # existing note paths only (agent context)
taskwarrior_linear here --json     # machine-readable, includes note paths
taskwarrior_linear map <ref> <dir> [--remove]
```

`map` edits the config for you. The ref can be an issue identifier (`VOIP-5914`), a taskwarrior task id/uuid (routed by the task's UDAs — issue, milestone, or project umbrella), a milestone 8-hex prefix, or a TW project key (`VOIP` / `VOIP.slug`). Milestone dirs apply recursively to the milestone's issue-tasks and their local subtasks; project dirs to everything under the project. The file is regenerated on each `map` — inline comments don't survive, which the file's header notes.

In Neovim: `:TWHere` (or `<leader>th`) — the `:TWTasks` picker pre-filtered to the current directory; `<CR>` opens the note, `<C-o>` opens Linear.

For AI agents: `here --json` + `here --notes` are the stable interface — a skill or CLAUDE.md line pointing at them gives any Bash-capable agent your task context.

### Taskwarrior contexts

```
taskwarrior_linear context VOIP-5914                    # issue + its subtasks
taskwarrior_linear context 12                           # milestone + its issues + subtasks
taskwarrior_linear context VOIP.asr-some-project-slug   # project (prefix-matches children)
taskwarrior_linear context none                         # clear
taskwarrior_linear context list
```

Sets a native taskwarrior context (read-only — new tasks are not auto-tagged), so `task`, `taskwarrior-tui`, and reports all narrow to that scope. Subtasks inherit their parent's project on creation, which is what lets project contexts cover them.

### Taskwarrior filters

The UDAs are plain Taskwarrior filters:

```
task linear:ENG-123          # everything tied to one issue
task linearproject:e5f...    # one project's umbrellas
task +LATEST project:VOIP.*  # normal taskwarrior, now Linear-aware
```

## Notes & gotchas

- The Linear key is a **personal** key with your full account permissions (Linear doesn't offer scoped read-only personal keys). Keychain + rotation is the practical mitigation; revoke it at linear.app → Settings → API when you stop using this.
- Taskwarrior prints `Configuration override ...` to stderr for any `rc.xxx=...` override. If you shell out to `task` and parse stdout+stderr merged (e.g. Lua's `vim.fn.system`), the JSON breaks — use plain `task status:pending export`.
- Taskwarrior 3.4 rejects the documented `depends:+N` modify syntax; this tool merges dependency lists explicitly.
- Linear's GraphQL query complexity cap (10000) forbids fetching all projects × their issues in one query — listings use scalar `scope`/`progress` fields instead.

## License

MIT — see [LICENSE](LICENSE).
