# Small, portable helper functions for Bash 4.x+.

# Create a directory and enter it.
mkcd() {
  [ "$#" -eq 1 ] || {
    printf 'usage: mkcd DIRECTORY\n' >&2
    return 2
  }
  mkdir -p -- "$1" && cd -- "$1" || return
}

# Extract common archive formats without memorizing tar flags.
extract() {
  [ "$#" -eq 1 ] || {
    printf 'usage: extract ARCHIVE\n' >&2
    return 2
  }
  [ -f "$1" ] || {
    printf 'extract: not a file: %s\n' "$1" >&2
    return 1
  }

  case $1 in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz) tar xzf "$1" ;;
    *.tar.xz|*.txz) tar xJf "$1" ;;
    *.tar) tar xf "$1" ;;
    *.zip) unzip "$1" ;;
    *.gz) gunzip "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.xz) unxz "$1" ;;
    *) printf 'extract: unsupported archive: %s\n' "$1" >&2; return 1 ;;
  esac
}

# Show the first available editor.
edit() {
  if command -v nvim >/dev/null 2>&1; then
    nvim "$@"
  elif command -v vim >/dev/null 2>&1; then
    vim "$@"
  else
    vi "$@"
  fi
}

# Enable shell proxy variables.
# Usage:
#   proxy_on
#   proxy_on http://127.0.0.1:7892
# Defaults can be customized with DOTFILES_PROXY_* variables.
proxy_on() {
  _proxy_url=${1:-}

  if [ -z "$_proxy_url" ]; then
    _proxy_scheme=${DOTFILES_PROXY_SCHEME:-http}
    _proxy_host=${DOTFILES_PROXY_HOST:-127.0.0.1}
    _proxy_port=${DOTFILES_PROXY_PORT:-7892}
    _proxy_url=$_proxy_scheme://$_proxy_host:$_proxy_port
  fi

  export http_proxy=$_proxy_url
  export https_proxy=$_proxy_url
  export HTTP_PROXY=$_proxy_url
  export HTTPS_PROXY=$_proxy_url
  export all_proxy=$_proxy_url
  export ALL_PROXY=$_proxy_url

  no_proxy=${DOTFILES_PROXY_NO_PROXY:-localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12}
  export no_proxy
  export NO_PROXY=$no_proxy

  printf 'Proxy enabled: %s\n' "$_proxy_url"
  unset _proxy_url _proxy_scheme _proxy_host _proxy_port
}

# Disable shell proxy variables.
proxy_off() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
  unset all_proxy ALL_PROXY
  unset no_proxy NO_PROXY

  printf 'Proxy disabled\n'
}

# Show current shell proxy state.
proxy_status() {
  if [ -n "${http_proxy:-}" ] || [ -n "${https_proxy:-}" ] || [ -n "${all_proxy:-}" ]; then
    printf 'http_proxy=%s\n' "${http_proxy:-}"
    printf 'https_proxy=%s\n' "${https_proxy:-}"
    printf 'all_proxy=%s\n' "${all_proxy:-}"
    printf 'no_proxy=%s\n' "${no_proxy:-}"
  else
    printf 'Proxy disabled\n'
  fi
}

# Append a command to PROMPT_COMMAND without clobbering existing hooks.
__df_prompt_command_add() {
  case ";${PROMPT_COMMAND:-};" in
    *";$1;"*) ;;
    "") PROMPT_COMMAND=$1 ;;
    *) PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }$1 ;;
  esac
}
