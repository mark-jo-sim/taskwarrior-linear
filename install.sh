#!/usr/bin/env sh
# taskwarrior-linear installer: symlinks the CLI, the Claude Code skills, and
# the taskwarrior hook into place. Re-running is safe (idempotent); existing
# files are replaced only if they are symlinks or copies of this repo's files.
# The Neovim module is NOT installed — load it from this repo via runtimepath
# (see the epilogue).

set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "$BIN_DIR"

link() {
  src="$1" dst="$2"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    echo "refusing to overwrite existing file: $dst" >&2
    echo "move it aside and re-run, or link manually:" >&2
    echo "  ln -s $src $dst" >&2
    exit 1
  fi
  ln -s "$src" "$dst"
  echo "linked $dst -> $src"
}

link "$REPO/taskwarrior_linear" "$BIN_DIR/taskwarrior_linear"
chmod +x "$REPO/taskwarrior_linear"

SKILLS_DIR="${HOME}/.claude/skills"
mkdir -p "$SKILLS_DIR"
for skill in "$REPO"/skills/*; do
  [ -d "$skill" ] || continue
  link "$skill" "$SKILLS_DIR/$(basename "$skill")"
done

HOOKS_DIR="${HOME}/.task/hooks"
mkdir -p "$HOOKS_DIR"
chmod +x "$REPO/hooks/on-modify.timewarrior-linear"
link "$REPO/hooks/on-modify.timewarrior-linear" "$HOOKS_DIR/on-modify.timewarrior-linear"

cat <<'EOF'

Done. Remaining manual steps:

1. Taskwarrior UDAs (~/.taskrc) — required once:

    uda.linear.type = string
    uda.linear.label = Linear
    uda.linearproject.type = string
    uda.linearproject.label = LinearProject
    uda.linearmilestone.type = string
    uda.linearmilestone.label = LinearMilestone

2. Linear API key (one of):

    security add-generic-password -a "$USER" -s taskwarrior_linear -w "<key>"
    echo "<key>" > ~/.config/taskwarrior_linear/key && chmod 600 ~/.config/taskwarrior_linear/key
    export LINEAR_API_KEY=...   # in shell profile

3. Neovim (init.lua, after your plugin manager) — load the module from this
   repo via runtimepath, no copy to keep in sync (TWL_REPO overrides the
   default path):

    local twl_repo = vim.fn.expand(os.getenv("TWL_REPO") or "~/projects/taskwarrior-linear")
    if vim.fn.isdirectory(twl_repo .. "/lua") == 1 then
      vim.opt.runtimepath:append(twl_repo)
      require("taskwarrior_linear").setup()
    end

4. Optional: Obsidian vault location (default ~/obsidian/Tasks):

    export TWL_VAULT=/path/to/notes-dir

5. Optional: time tracking needs timewarrior (brew install timewarrior).
   The on-modify hook is installed at ~/.task/hooks/on-modify.timewarrior-linear
   — verify taskwarrior sees it with: task diagnostics
   For a tmux status line:
     set -g status-interval 30
     set -g status-right '#(taskwarrior_linear status)'

6. Installed agent skills (~/.claude/skills, invocable as /tw, /tw-start,
   /tw-eod in Claude Code):
   - tw — task + note context for a directory or project scope
   - tw-start — morning briefing: open issues, active tasks, Next steps;
     drafts EOD goals with the user
   - tw-eod — rolling-24h review of task/note changes; progress against
     the EOD goals

Verify with:

    taskwarrior_linear issues
EOF
