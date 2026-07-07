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

# Append a command to PROMPT_COMMAND without clobbering existing hooks.
__df_prompt_command_add() {
  case ";${PROMPT_COMMAND:-};" in
    *";$1;"*) ;;
    "") PROMPT_COMMAND=$1 ;;
    *) PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }$1 ;;
  esac
}

