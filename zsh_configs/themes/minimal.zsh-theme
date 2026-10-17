# minimal: path, git branch, kube context, and a prompt char that goes red on failure.
#
#   ~/src/app (main) ⎈ rancher-lab-local ❯
#
# No external prompt framework. git info comes from zsh's built-in vcs_info;
# the kube context is read straight from the kubeconfig in pure zsh (no fork).

autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{magenta}(%b)%f'

# Opt out with: export PROMPT_KUBE=0   (or keep it off outside k8s work)
: ${PROMPT_KUBE:=1}

_prompt_kube_context() {
  _prompt_kube=''
  (( PROMPT_KUBE )) || return
  # first file in $KUBECONFIG, else the default
  local cfg="${KUBECONFIG%%:*}"
  cfg="${cfg:-$HOME/.kube/config}"
  [[ -r $cfg ]] || return
  local line ctx
  while IFS= read -r line; do
    if [[ $line == current-context:* ]]; then
      ctx="${line#current-context:}"
      ctx="${ctx//[\" ]/}"          # strip quotes and spaces
      break
    fi
  done < "$cfg"
  [[ -n $ctx ]] && _prompt_kube=" %F{blue}⎈ ${ctx}%f"
}

# Shortened path:  ~/workspace/learning/ai/ai-infra  ->  ~/w/l/a/ai-infra
#   - every parent folder collapses to its first letter (dot-folders keep the dot: .config -> .c)
#   - the last folder stays whole, but is cut to PROMPT_PATH_MAX characters (default 8)
# Settings:  PROMPT_PATH_SHORT=0  -> normal full path (%~)
#            PROMPT_PATH_MAX=0    -> never cut the last folder
: ${PROMPT_PATH_SHORT:=1}
: ${PROMPT_PATH_MAX:=8}

_prompt_short_path() {
  if (( ! PROMPT_PATH_SHORT )); then _prompt_path='%~'; return; fi
  local p
  if [[ $PWD == $HOME ]]; then p='~'
  elif [[ $PWD == "$HOME"/* ]]; then p="~${PWD#"$HOME"}"
  else p=$PWD
  fi
  if [[ $p == / ]]; then _prompt_path=/; return; fi
  local -a parts=("${(@s:/:)p}") out
  local seg i n=$#parts
  for (( i=1; i<=n; i++ )); do
    seg=$parts[i]
    if (( i == n )); then
      (( PROMPT_PATH_MAX > 0 )) && seg=${seg[1,$PROMPT_PATH_MAX]}
    elif [[ -z $seg || $seg == '~' ]]; then
      :                                   # leading "/" or "~" stays as is
    elif [[ $seg == .* ]]; then
      seg=${seg[1,2]}                     # .config -> .c
    else
      seg=${seg[1]}                       # workspace -> w
    fi
    out+=("$seg")
  done
  _prompt_path=${(j:/:)out}
  _prompt_path=${_prompt_path//\%/%%}     # a literal % in a folder name must not be read as a prompt escape
}

_prompt_precmd() {
  vcs_info
  _prompt_kube_context
  _prompt_short_path
}
add-zsh-hook precmd _prompt_precmd

PROMPT='%F{cyan}${_prompt_path}%f${vcs_info_msg_0_}${_prompt_kube} %(?.%F{green}.%F{red})❯%f '
