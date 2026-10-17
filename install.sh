#!/usr/bin/env bash
# Install this zsh setup into ~/.zsh_configs and link ~/.zshrc.
# Plugins are fetched from GitHub and PINNED to the commits in plugins.lock,
# so a compromised upstream branch can't silently land in your shell startup.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${ZSH_CONFIGS:-$HOME/.zsh_configs}"

mkdir -p "$DEST"
cp -R "$SRC/zsh_configs/." "$DEST/"
mkdir -p "$DEST/plugins"

while read -r name repo sha; do
  [[ -z "${name:-}" || "$name" == \#* ]] && continue
  dir="$DEST/plugins/$name"
  if [[ ! -d "$dir/.git" ]]; then
    git clone --quiet "https://github.com/$repo.git" "$dir"
  fi
  git -C "$dir" fetch --quiet origin "$sha" 2>/dev/null || git -C "$dir" fetch --quiet --all
  git -C "$dir" checkout --quiet "$sha"
  echo "  $name @ ${sha:0:9}"
done < "$SRC/plugins.lock"

# Move (not copy) any existing ~/.zshrc aside. Moving matters when it is a symlink
# (dotfiles managers): the link itself goes to the backup and its target is never
# touched, whereas copying a new file "over" it would write through the link.
if [[ -e "$HOME/.zshrc" || -L "$HOME/.zshrc" ]]; then
  ts=$(date +%s)
  while [[ -e "$HOME/.zshrc.bak.$ts" || -L "$HOME/.zshrc.bak.$ts" ]]; do ts=$((ts + 1)); done
  mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$ts"
  echo "  existing ~/.zshrc moved to ~/.zshrc.bak.$ts"
fi
cp "$SRC/zshrc" "$HOME/.zshrc"
echo "Done. Open a new terminal, or run: exec zsh"
