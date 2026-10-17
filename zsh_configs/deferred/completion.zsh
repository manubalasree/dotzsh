# Completion: the single most expensive thing in a typical zsh startup.
# We run it deferred, and cache aggressively.

local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$cache" ]] || mkdir -p "$cache"

# zsh-completions must be on fpath BEFORE compinit
fpath=("$ZSH_CONFIGS/plugins/zsh-completions/src" $fpath)

autoload -Uz compinit
local dump="$cache/zcompdump"

# Full compinit (with the slow security audit) at most once every 24h;
# otherwise -C trusts the existing dump and skips it.
setopt local_options extended_glob
if [[ -n $dump(#qN.mh+24) || ! -s $dump ]]; then
  compinit -d "$dump"
else
  compinit -C -d "$dump"
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$cache/zcompcache"

# kubectl: `kubectl completion zsh` takes a noticeable moment to run, so
# generate it once and re-generate only when the kubectl binary changes.
if (( $+commands[kubectl] )); then
  local kc="$cache/kubectl-completion.zsh"
  if [[ ! -s $kc || $kc -ot ${commands[kubectl]} ]]; then
    kubectl completion zsh > "$kc" 2>/dev/null
  fi
  source "$kc"
  compdef k=kubectl
fi
