# ~/.zshrc  --  tiny on purpose. Real config lives in $ZSH_CONFIGS.
#
# Two phases:
#   1. INSTANT  - things the first prompt needs (options, history, aliases, prompt)
#   2. DEFERRED - things only needed once you start typing (completion, plugins)
#
# Profile startup:   ZSH_PROFILE=1 zsh -i -c exit

export ZSH_CONFIGS="${ZSH_CONFIGS:-$HOME/.zsh_configs}"
export ZSH_THEME="${ZSH_THEME:-minimal}"

[[ -n "$ZSH_PROFILE" ]] && zmodload zsh/zprof

# zsh-defer is the one plugin we load eagerly: it's what makes the rest lazy.
# Fail safe: if it's missing (fresh machine, failed clone), degrade to eager
# loading instead of spraying "command not found" on every new shell.
if [[ -r "$ZSH_CONFIGS/plugins/zsh-defer/zsh-defer.plugin.zsh" ]]; then
  source "$ZSH_CONFIGS/plugins/zsh-defer/zsh-defer.plugin.zsh"
else
  print -u2 "zshrc: zsh-defer not found in \$ZSH_CONFIGS/plugins, loading eagerly (run install.sh)"
  zsh-defer() { "$@" }
fi

# ---- Phase 1: instant ------------------------------------------------------
for f in "$ZSH_CONFIGS"/core/*.zsh; do
  source "$f"
done
source "$ZSH_CONFIGS/aliases.zsh"
source "$ZSH_CONFIGS/themes/$ZSH_THEME.zsh-theme"

# ---- Phase 2: deferred (runs once the prompt is up and zsh is idle) --------
# Order matters: completion first, syntax-highlighting LAST (it wraps widgets).
zsh-defer source "$ZSH_CONFIGS/deferred/completion.zsh"
zsh-defer source "$ZSH_CONFIGS/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
zsh-defer source "$ZSH_CONFIGS/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Machine-local overrides (not committed)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

[[ -n "$ZSH_PROFILE" ]] && zsh-defer zprof
