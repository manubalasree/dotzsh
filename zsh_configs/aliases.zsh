# Aliases. One file, easy to diff, easy to trim.

# ls
if ls --color=auto >/dev/null 2>&1; then
  alias ls='ls --color=auto'      # GNU
else
  alias ls='ls -G'                # BSD / macOS
fi
alias ll='ls -lah'
alias la='ls -A'

# navigation
alias ..='cd ..'
alias ...='cd ../..'

# git
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gco='git checkout'

# kubernetes
alias k='kubectl'
alias kx='kubectx'
alias kn='kubens'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes -o wide'
alias kdp='kubectl describe pod'
alias klf='kubectl logs -f'
alias kaf='kubectl apply -f'
