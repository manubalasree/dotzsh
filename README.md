# zsh-lab: a fast, modular, pinned zsh setup

Two-phase startup: the prompt appears after only cheap work (options, history,
aliases, prompt). Completion, autosuggestions and syntax highlighting are
deferred with [zsh-defer](https://github.com/romkatv/zsh-defer) and load while
the prompt is already on screen.

## Install

    ./install.sh        # copies zsh_configs/ to ~/.zsh_configs, installs ~/.zshrc
    exec zsh

`install.sh` moves an existing `~/.zshrc` (even a symlink) to `~/.zshrc.bak.<time>`, never
overwriting it, and fetches the plugins from GitHub,
checked out at the exact commits in `plugins.lock`.

## Uninstall

    ./uninstall.sh      # asks before each step; -y to accept the main steps

Restores your original `~/.zshrc` (the OLDEST `~/.zshrc.bak.*`, since re-running
`install.sh` backs up the previous install too), then removes `~/.zsh_configs`
and the completion cache. History and backups are kept unless you answer yes or
pass `--purge`.

## Layout

    zshrc                       -> ~/.zshrc (two phases, nothing else)
    zsh_configs/core/           instant phase: options, history
    zsh_configs/deferred/       deferred phase: completion (cached, kubectl too)
    zsh_configs/themes/         prompt: path, git branch, kube context
    zsh_configs/aliases.zsh     aliases (ls, git, kubectl)
    plugins.lock                plugin repo + pinned commit
    uninstall.sh                restore original ~/.zshrc, remove what install added
    bench/ptybench.py           time-to-first-prompt harness

## Everyday use

- Profile startup:        `ZSH_PROFILE=1 zsh -i -c exit`
- Turn off kube context:  `export PROMPT_KUBE=0`
- Short path (`~/workspace/learning/ai/ai-infra` -> `~/w/l/a/ai-infra`): parent folders
  become their first letter, the last folder is cut to `PROMPT_PATH_MAX` characters
  (default 8). `PROMPT_PATH_SHORT=0` restores the full path, `PROMPT_PATH_MAX=0` never cuts
  the last folder.
- Machine-local settings and secrets: `~/.zshrc.local` (never commit it)
- Update a plugin: change its SHA in `plugins.lock` after reviewing the upstream
  diff, then re-run `./install.sh`
- Force a fresh completion dump: `rm ~/.cache/zsh/zcompdump`

## Troubleshooting

- **"Ignore insecure directories and files?" appears in a new shell:** `compinit` found
  group-writable completion directories. Run `compaudit` and `chmod g-w` what it lists
  (on macOS usually Homebrew's `share/zsh`), rather than answering the prompt blindly.
- **A tool you just installed doesn't tab-complete:** the completion cache refreshes fully
  once a day. Force it with `rm ~/.cache/zsh/zcompdump`, then open a new shell.
- **`bench/ptybench.py` gives up waiting for a prompt:** it looks for the minimal theme's
  `❯`. For any other prompt pass `--glyph ''`.

## Not tested

kubectl completion caching (no kubectl in the test environment), the macOS
branch of the `ls` alias, and `uninstall.sh` on macOS (tested on Linux only)
were not run end to end.
