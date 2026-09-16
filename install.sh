#!/usr/bin/env sh
# taskwarrior-linear installer: symlinks the CLI and the Neovim module into
# place. Re-running is safe (idempotent); existing files are replaced only if
# they are symlinks or copies of this repo's files.

set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
NVIM_LUA_DIR="${HOME}/.config/nvim/lua"

mkdir -p "$BIN_DIR" "$NVIM_LUA_DIR"

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
link "$REPO/lua/taskwarrior_linear.lua" "$NVIM_LUA_DIR/taskwarrior_linear.lua"

SKILLS_DIR="${HOME}/.claude/skills"
mkdir -p "$SKILLS_DIR"
for skill in "$REPO"/skills/*; do
  [ -d "$skill" ] || continue
  link "$skill" "$SKILLS_DIR/$(basename "$skill")"
done

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

3. Neovim (init.lua, after your plugin manager):

    require("taskwarrior_linear").setup()

4. Optional: Obsidian vault location (default ~/obsidian/Tasks):

    export TWL_VAULT=/path/to/notes-dir

5. Installed agent skills (~/.claude/skills, invocable as /tw, /tw-start,
   /tw-eod in Claude Code):
   - tw — task + note context for a directory or project scope
   - tw-start — morning briefing: open issues, active tasks, Next steps;
     drafts EOD goals with the user
   - tw-eod — rolling-24h review of task/note changes; progress against
     the EOD goals

Verify with:

    taskwarrior_linear issues
EOF
