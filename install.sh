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
  if [ -e "$HOME/.dotfiles" ] || [ -L "$HOME/.dotfiles" ]; then
    if [ "$(readlink -- "$HOME/.dotfiles" 2>/dev/null || true)" != "$DOTFILES_DIR" ]; then
      backup_path "$HOME/.dotfiles"
      ln -s -- "$DOTFILES_DIR" "$HOME/.dotfiles"
      LINKED_COUNT=$((LINKED_COUNT + 1))
      info "linked $HOME/.dotfiles -> $DOTFILES_DIR"
    else
      UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
      note "unchanged $HOME/.dotfiles"
    fi
  else
    ln -s -- "$DOTFILES_DIR" "$HOME/.dotfiles"
    LINKED_COUNT=$((LINKED_COUNT + 1))
    info "linked $HOME/.dotfiles -> $DOTFILES_DIR"
  fi

  link_file "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"
  link_file "$DOTFILES_DIR/vimrc" "$HOME/.vimrc"
  link_file "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

  section "Tools"
  missing_tools
  [ -n "$RECOMMENDED_OK" ] && info "recommended tools ready: $RECOMMENDED_OK"

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
  info "next step: open a new shell or run: source ~/.bashrc"
}

main "$@"
