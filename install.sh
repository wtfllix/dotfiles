#!/usr/bin/env bash
# Install dotfiles by creating symlinks and backing up existing files.
# The script reports missing optional packages but does not install anything.

set -u

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
BACKUP_DIR=$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)
LINKED_COUNT=0
UNCHANGED_COUNT=0
BACKUP_COUNT=0
RECOMMENDED_OK=
MISSING_RECOMMENDED=
MISSING_OPTIONAL=
PROXY_RESULT="not configured"

info() {
  printf '  [OK]   %s\n' "$*"
}

warn() {
  printf '  [WARN] %s\n' "$*" >&2
}

note() {
  printf '  [..]   %s\n' "$*"
}

section() {
  printf '\n==> %s\n' "$*"
}

detect_os() {
  if [ -r /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    OS_ID=${ID:-unknown}
    OS_LIKE=${ID_LIKE:-}
  else
    OS_ID=$(uname -s 2>/dev/null || printf unknown)
    OS_LIKE=
  fi
}

backup_path() {
  _src=$1
  [ -e "$_src" ] || [ -L "$_src" ] || return 0

  mkdir -p -- "$BACKUP_DIR"
  mv -- "$_src" "$BACKUP_DIR/"
  BACKUP_COUNT=$((BACKUP_COUNT + 1))
  note "backed up $_src"
}

backup_copy_path() {
  _src=$1
  [ -e "$_src" ] || [ -L "$_src" ] || return 0

  mkdir -p -- "$BACKUP_DIR"
  cp -p -- "$_src" "$BACKUP_DIR/"
  BACKUP_COUNT=$((BACKUP_COUNT + 1))
  note "backed up $_src"
}

link_file() {
  _target=$1
  _link=$2

  if [ -L "$_link" ]; then
    _current=$(readlink -- "$_link" 2>/dev/null || true)
    if [ "$_current" = "$_target" ]; then
      UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
      note "unchanged $_link"
      return 0
    fi
  fi

  backup_path "$_link"
  ln -s -- "$_target" "$_link"
  LINKED_COUNT=$((LINKED_COUNT + 1))
  info "linked $_link -> $_target"
}

link_dotfiles_dir() {
  _link=$HOME/.dotfiles

  if [ -e "$_link" ] || [ -L "$_link" ]; then
    if [ "$DOTFILES_DIR" = "$_link" ] || [ "$_link" -ef "$DOTFILES_DIR" ] 2>/dev/null; then
      UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
      note "using existing repository $_link"
      return 0
    fi

    if [ -L "$_link" ]; then
      _current=$(readlink -- "$_link" 2>/dev/null || true)
      if [ "$_current" = "$DOTFILES_DIR" ]; then
        UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
        note "unchanged $_link"
        return 0
      fi
    fi

    backup_path "$_link"
  fi

  ln -s -- "$DOTFILES_DIR" "$_link"
  LINKED_COUNT=$((LINKED_COUNT + 1))
  info "linked $_link -> $DOTFILES_DIR"
}

shell_quote() {
  _value=$1
  printf "'"
  printf '%s' "$_value" | sed "s/'/'\\\\''/g"
  printf "'"
}

has_managed_proxy_block() {
  [ -r "$HOME/.bashrc.local" ] || return 1
  grep -q '^# >>> dotfiles proxy >>>$' "$HOME/.bashrc.local"
}

write_proxy_config() {
  _proxy_mode=$1
  _proxy_scheme=${2:-http}
  _proxy_host=${3:-127.0.0.1}
  _proxy_port=${4:-7892}
  _proxy_no_proxy=${5:-localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12}
  _local_rc=$HOME/.bashrc.local
  _tmp_rc=$(mktemp "${TMPDIR:-/tmp}/bashrc.local.XXXXXX") || return 1

  if [ -e "$_local_rc" ] || [ -L "$_local_rc" ]; then
    backup_copy_path "$_local_rc"
    if ! sed '/^# >>> dotfiles proxy >>>$/,/^# <<< dotfiles proxy <<<$/d' "$_local_rc" > "$_tmp_rc"; then
      rm -f -- "$_tmp_rc"
      warn "failed to update $_local_rc"
      return 1
    fi
  else
    : > "$_tmp_rc"
  fi

  if [ "$_proxy_mode" = "auto" ] || [ "$_proxy_mode" = "prompt" ]; then
    {
      printf '\n# >>> dotfiles proxy >>>\n'
      printf '# Managed by dotfiles/install.sh. Edit by rerunning install.sh.\n'
      printf 'export DOTFILES_PROXY_MODE=%s\n' "$(shell_quote "$_proxy_mode")"
      printf 'export DOTFILES_PROXY_SCHEME=%s\n' "$(shell_quote "$_proxy_scheme")"
      printf 'export DOTFILES_PROXY_HOST=%s\n' "$(shell_quote "$_proxy_host")"
      printf 'export DOTFILES_PROXY_PORT=%s\n' "$(shell_quote "$_proxy_port")"
      printf 'export DOTFILES_PROXY_NO_PROXY=%s\n' "$(shell_quote "$_proxy_no_proxy")"
      if [ "$_proxy_mode" = "auto" ]; then
        printf 'proxy_on >/dev/null\n'
      else
        printf 'proxy_prompt\n'
      fi
      printf '# <<< dotfiles proxy <<<\n'
    } >> "$_tmp_rc"
    PROXY_RESULT="$_proxy_mode: $_proxy_scheme://$_proxy_host:$_proxy_port"
  else
    PROXY_RESULT="off"
  fi

  mv -- "$_tmp_rc" "$_local_rc"
  chmod 600 "$_local_rc" 2>/dev/null || true
}

prompt_proxy_config() {
  section "Proxy"

  if [ ! -t 0 ]; then
    note "skipped proxy prompt because stdin is not interactive"
    return 0
  fi

  printf 'Proxy mode for new interactive shells: auto, prompt, off [auto]: '
  read -r _proxy_mode
  [ -z "$_proxy_mode" ] && _proxy_mode=auto

  case $_proxy_mode in
    auto|AUTO) _proxy_mode=auto ;;
    prompt|PROMPT|ask|ASK) _proxy_mode=prompt ;;
    off|OFF|n|N|no|NO) _proxy_mode=off ;;
    *)
      warn "unsupported proxy mode: $_proxy_mode"
      warn "allowed values: auto, prompt, off"
      return 1
      ;;
  esac

  case $_proxy_mode in
    auto|prompt)
      _proxy_scheme=${DOTFILES_PROXY_SCHEME:-http}
      _proxy_host=${DOTFILES_PROXY_HOST:-127.0.0.1}
      _proxy_port=${DOTFILES_PROXY_PORT:-7892}
      _proxy_no_proxy=${DOTFILES_PROXY_NO_PROXY:-localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12}

      note "proxy examples:"
      note "  HTTP local proxy:  scheme=http,   host=127.0.0.1, port=7892"
      note "  SOCKS5 proxy:      scheme=socks5, host=127.0.0.1, port=7892"
      note "press Enter to keep the default shown in brackets"

      printf 'Proxy scheme: http, https, socks5, socks5h [%s]: ' "$_proxy_scheme"
      read -r _input
      [ -n "$_input" ] && _proxy_scheme=$_input

      case $_proxy_scheme in
        http|https|socks5|socks5h) ;;
        *)
          warn "unsupported proxy scheme: $_proxy_scheme"
          warn "allowed values: http, https, socks5, socks5h"
          return 1
          ;;
      esac

      printf 'Proxy host [%s]: ' "$_proxy_host"
      read -r _input
      [ -n "$_input" ] && _proxy_host=$_input

      printf 'Proxy port [%s]: ' "$_proxy_port"
      read -r _input
      [ -n "$_input" ] && _proxy_port=$_input

      case $_proxy_port in
        ''|*[!0-9]*)
          warn "proxy port must be numeric"
          return 1
          ;;
      esac

      printf 'NO_PROXY [%s]: ' "$_proxy_no_proxy"
      read -r _input
      [ -n "$_input" ] && _proxy_no_proxy=$_input

      if write_proxy_config "$_proxy_mode" "$_proxy_scheme" "$_proxy_host" "$_proxy_port" "$_proxy_no_proxy"; then
        if [ "$_proxy_mode" = "auto" ]; then
          info "proxy will be enabled automatically for new shells"
        else
          info "proxy prompt configured for new shells"
        fi
      else
        warn "proxy configuration was not changed"
      fi
      ;;
    *)
      if has_managed_proxy_block; then
        if write_proxy_config off; then
          info "proxy auto handling disabled"
        else
          warn "proxy configuration was not changed"
        fi
      else
        PROXY_RESULT="off"
        note "proxy auto handling not enabled"
      fi
      ;;
  esac
}

has_bash_completion() {
  for _completion in \
    "/usr/share/bash-completion/bash_completion" \
    "/etc/bash_completion" \
    "/usr/local/etc/profile.d/bash_completion.sh" \
    "/opt/homebrew/etc/profile.d/bash_completion.sh"
  do
    [ -r "$_completion" ] && return 0
  done
  return 1
}

missing_tools() {
  _missing_recommended=
  _missing_optional=
  _recommended_ok=

  for _cmd in bash git fzf tmux; do
    if ! command -v "$_cmd" >/dev/null 2>&1; then
      _missing_recommended=${_missing_recommended:+$_missing_recommended }$_cmd
    else
      _recommended_ok=${_recommended_ok:+$_recommended_ok }$_cmd
    fi
  done

  if ! command -v vim >/dev/null 2>&1 && ! command -v nvim >/dev/null 2>&1; then
    _missing_recommended=${_missing_recommended:+$_missing_recommended }vim-or-nvim
  elif command -v nvim >/dev/null 2>&1; then
    _recommended_ok=${_recommended_ok:+$_recommended_ok }nvim
  else
    _recommended_ok=${_recommended_ok:+$_recommended_ok }vim
  fi

  if ! has_bash_completion; then
    _missing_recommended=${_missing_recommended:+$_missing_recommended }bash-completion
  else
    _recommended_ok=${_recommended_ok:+$_recommended_ok }bash-completion
  fi

  for _cmd in nvim docker podman; do
    if ! command -v "$_cmd" >/dev/null 2>&1; then
      _missing_optional=${_missing_optional:+$_missing_optional }$_cmd
    fi
  done

  RECOMMENDED_OK=$_recommended_ok
  MISSING_RECOMMENDED=$_missing_recommended
  MISSING_OPTIONAL=$_missing_optional

  if [ -n "$_missing_recommended" ]; then
    warn "missing recommended tools: $_missing_recommended"
    case " $OS_ID $OS_LIKE " in
      *debian*|*ubuntu*)
        warn "suggested packages: sudo apt install bash-completion fzf git vim tmux"
        ;;
      *fedora*)
        warn "suggested packages: sudo dnf install bash-completion fzf git vim-enhanced tmux"
        ;;
      *rhel*|*centos*|*rocky*|*almalinux*)
        warn "suggested packages: sudo dnf install bash-completion git vim-enhanced tmux"
        warn "fzf and ble.sh may require EPEL or manual installation"
        ;;
      *)
        warn "install bash-completion, fzf, git, vim or nvim, and tmux with your system package manager"
        ;;
    esac
  fi

  if [ -n "$_missing_optional" ]; then
    note "optional integrations not found: $_missing_optional"
  fi
}

main() {
  printf 'Dotfiles installer\n'
  printf 'This script creates symlinks only. It will not install packages.\n'

  section "System"
  detect_os
  info "detected system: $OS_ID ${OS_LIKE:+($OS_LIKE)}"
  info "dotfiles directory: $DOTFILES_DIR"

  section "Links"
  link_dotfiles_dir
  link_file "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"
  link_file "$DOTFILES_DIR/vimrc" "$HOME/.vimrc"
  link_file "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

  section "Tools"
  missing_tools
  [ -n "$RECOMMENDED_OK" ] && info "recommended tools ready: $RECOMMENDED_OK"

  prompt_proxy_config

  section "Summary"
  info "completed: $LINKED_COUNT linked, $UNCHANGED_COUNT unchanged, $BACKUP_COUNT backed up"
  if [ -n "$MISSING_RECOMMENDED" ]; then
    warn "recommended tools still missing: $MISSING_RECOMMENDED"
  else
    info "all recommended tools are available"
  fi
  [ -n "$MISSING_OPTIONAL" ] && note "optional tools skipped: $MISSING_OPTIONAL"
  if [ "$BACKUP_COUNT" -gt 0 ]; then
    info "backup directory: $BACKUP_DIR"
  else
    note "no backups were needed"
  fi
  info "proxy: $PROXY_RESULT"
  info "next step: open a new shell or run: source ~/.bashrc"
}

main "$@"
