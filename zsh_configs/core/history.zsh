# History: big, shared across tabs, de-duplicated.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000

setopt share_history          # every tab sees every other tab's commands
setopt inc_append_history     # write immediately, not on shell exit
setopt hist_ignore_all_dups   # keep only the latest copy of a command
setopt hist_ignore_space      # a leading space keeps a command out of history
setopt hist_reduce_blanks
