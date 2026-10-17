# Shell behaviour. Cheap: just setopt calls.
setopt auto_cd              # type a directory name to cd into it
setopt extended_glob        # ** , ^pattern, (#q...) qualifiers
setopt interactive_comments # allow # comments at the prompt
setopt no_beep
setopt no_flow_control      # free up Ctrl-S / Ctrl-Q
setopt prompt_subst         # expand $vars inside PROMPT

# Emacs-style line editing; Up/Down search history by what you've typed so far
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
