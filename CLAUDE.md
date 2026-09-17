# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A bridge that mirrors Linear (issues, projects, milestones) into Taskwarrior, with Obsidian notes per task and a Neovim picker layer. Python 3.8+ **stdlib only** — no dependencies, no build, no test suite. Run/verify changes with:

```sh
python3 -m py_compile taskwarrior_linear          # syntax check
./taskwarrior_linear issues                       # live smoke test (needs API key)
./taskwarrior_linear here --json >/dev/null       # no network needed
./install.sh                                      # idempotent: symlink CLI, skills, timew hook
```

The executable is the file `taskwarrior_linear` at the repo root (symlinked to `~/.local/bin` by `install.sh`). Run it from the repo as `./taskwarrior_linear` when testing edits. The Neovim module is **not** installed anywhere — init.lua appends this repo to `runtimepath` (`TWL_REPO`, default `~/projects/taskwarrior-linear`) and requires it from here; editing `lua/taskwarrior_linear.lua` takes effect directly.

## Architecture

Everything lives in **one Python file** (`taskwarrior_linear`, ~1700 lines), organized top-to-bottom in labeled sections. Read section headers before navigating:

1. **Linear layer** — `api_key()` (env `LINEAR_API_KEY` → `~/.config/taskwarrior_linear/key` → macOS Keychain) and `gql()` (urllib POST to `https://api.linear.app/graphql`). All Linear queries go through `gql`.
2. **Taskwarrior helpers** — `task()` (shell out), `tw_json()` (JSON export), `resolve(ref)` (accepts issue ident, task id/uuid, milestone prefix, or project key — routing is via the UDAs). New commands that take a task reference should go through `resolve`.
3. **Import/linking model** (see the module docstring for the authoritative statement):
   - UDA `linear` = issue identifier on issue-tasks **and** their local subtasks; subtasks are never pushed to Linear.
   - Issue-task `depends:` on its subtasks; project/milestone umbrellas (`[project]`/`[milestone] name`, UDAs `linearproject`/`linearmilestone`) `depends:` on their issues.
   - Only `done` on an issue-task writes back to Linear; umbrella completions never do.
4. **Notes** — `<vault>/Tasks/<IDENT or short-uuid> <title>.md`; vault defaults to `~/obsidian/Tasks`, override with `TWL_VAULT`. Journals at `<vault root>/journals/EOD-<date>.md` (`TWL_JOURNALS_DIR`).
5. **Sync** — the notes dir *is* a git repo (`TWL_SYNC_REPO`); `sync push/pull` round-trips `task export` → `tasks.json` (one task per line for clean merges) → `task import` (uuid upsert, tombstones included).
6. **Workdirs / context / here** — `~/.config/taskwarrior_linear/workdirs.toml` maps projects/issues to directories; `map` regenerates the file, so inline comments don't survive (by design).
7. **sod / eod / journal** — deterministic daily-review commands. The Claude Code skills in `skills/` (`/tw`, `/tw-start`, `/tw-eod`) are thin conversational wrappers over these; keep business logic in the CLI, not the skills.
8. **Timewarrior** — time tracking, hook-driven. `hooks/on-modify.timewarrior-linear` (symlinked into `~/.task/hooks` by `install.sh`) is a protocol-only shim: it detects `task start`/`stop` transitions and shells out to the hidden `_hook` subcommand, which does all the work (`timew start <tags>` + `ensure_note`, or `timew stop` + `write_time_frontmatter`). Timew is the source of truth (local per machine, never synced); note frontmatter `time_*` keys are a derived, machine-owned projection. Interval tags: `uuid` (exact lookup), Linear ident (issue rollup), project, description.

`lua/taskwarrior_linear.lua` is the Neovim layer — it only shells out to the CLI and parses JSON; it holds no logic of its own. `docs/task-workspaces.md` is shelved design notes, not implemented behavior.

## Gotchas

- Taskwarrior prints `Configuration override ...` to **stderr** for any `rc.xxx=` override, which corrupts JSON when stdout+stderr are merged (e.g. `vim.fn.system`). Always use plain `task <filter> export` with no overrides when parsing.
- Taskwarrior 3.4 rejects `depends:+N` modify syntax — merge dependency lists explicitly (see `add_deps`).
- Linear GraphQL complexity cap (10000): never fetch all projects × issues in one query; listings use scalar `scope`/`progress` fields.
- Linear priority maps 0/1/2/3/4 → none/H/H/none/L (`PRIORITY_MAP`); only H and L are defined.
- `eod` uses a rolling 24h window (`DAILY_CUTOFF_HOURS`), not calendar days — timezone-safe on purpose.
- The on-modify hook must emit the new task JSON on stdout and always exit 0 — a broken hook breaks every `task` command. It also runs **pre-save**: `task export` inside `_hook` sees the old DB state, which is why the hook passes the new start timestamp explicitly.
- Timewarrior parses tz-less timestamps as **local** time and rejects `+00:00` ISO offsets — always pass UTC as `...Z`. The hook ignores start attrs older than 5 minutes (sync/import artifacts must not open phantom intervals).
- The `+active` taskwarrior tag (sod/eod convention) is manual and unrelated to timew's active interval — `status` consults timew only.

## Env vars

`LINEAR_API_KEY`, `TWL_VAULT` (notes dir, default `~/obsidian/Tasks`), `TWL_JOURNALS_DIR`, `TWL_SYNC_REPO`, `TWL_REPO` (this repo's clone path, used by the nvim runtimepath loader).

## Commits

Commit messages are lowercase, short, imperative (see `git log`: "use obsidian.nvim and obsidian journals", "add python gitignore").
