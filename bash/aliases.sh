# Common aliases for interactive work.
# Avoid replacing destructive commands such as rm/cp/mv unless safe mode is enabled.

# Prefer color where supported. BSD tools ignore GNU-specific options, so test first.
if ls --color=auto >/dev/null 2>&1; then
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias egrep='egrep --color=auto'
  alias fgrep='fgrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mkdir='mkdir -p'
alias path='printf "%s\n" "${PATH//:/\\n}"'

# Enable opt-in safer file operations by exporting DOTFILES_SAFE_ALIASES=1.
if [ "${DOTFILES_SAFE_ALIASES:-0}" = "1" ]; then
  alias rm='rm -I'
  alias cp='cp -i'
  alias mv='mv -i'
fi

if command -v git >/dev/null 2>&1; then
  alias g='git'
  alias gs='git status --short --branch'
  alias ga='git add'
  alias gc='git commit'
  alias gcm='git commit -m'
  alias gco='git checkout'
  alias gb='git branch'
  alias gd='git diff'
  alias gl='git log --oneline --decorate --graph -20'
  alias gp='git pull --ff-only'
  alias gps='git push'
fi

if command -v docker >/dev/null 2>&1; then
  alias dps='docker ps'
  alias dimg='docker images'
  alias dlog='docker logs'
fi

if command -v podman >/dev/null 2>&1; then
  alias pps='podman ps'
  alias pimg='podman images'
  alias plog='podman logs'
fi

