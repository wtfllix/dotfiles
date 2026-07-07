#!/usr/bin/env bash
# Install dotfiles by creating symlinks and backing up existing files.
# The script reports missing optional packages but does not install anything.

set -u

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
BACKUP_DIR=$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)

info() {
  printf '[info] %s\n' "$*"
}

warn() {
  printf '[warn] %s\n' "$*" >&2
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
  info "backed up $_src to $BACKUP_DIR/"
}

link_file() {
  _target=$1
  _link=$2

  if [ -L "$_link" ]; then
    _current=$(readlink -- "$_link" 2>/dev/null || true)
    if [ "$_current" = "$_target" ]; then
      info "already linked $_link"
      return 0
    fi
  fi

  backup_path "$_link"
  ln -s -- "$_target" "$_link"
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

  for _cmd in bash git fzf tmux; do
    if ! command -v "$_cmd" >/dev/null 2>&1; then
      _missing_recommended=${_missing_recommended:+$_missing_recommended }$_cmd
    fi
  done

  if ! command -v vim >/dev/null 2>&1 && ! command -v nvim >/dev/null 2>&1; then
    _missing_recommended=${_missing_recommended:+$_missing_recommended }vim-or-nvim
  fi

  if ! has_bash_completion; then
    _missing_recommended=${_missing_recommended:+$_missing_recommended }bash-completion
  fi

  for _cmd in nvim docker podman; do
    if ! command -v "$_cmd" >/dev/null 2>&1; then
      _missing_optional=${_missing_optional:+$_missing_optional }$_cmd
    fi
  done

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
    info "optional integrations not found: $_missing_optional"
  fi
}

main() {
  detect_os
  info "detected system: $OS_ID ${OS_LIKE:+($OS_LIKE)}"
  info "dotfiles directory: $DOTFILES_DIR"

  if [ -e "$HOME/.dotfiles" ] || [ -L "$HOME/.dotfiles" ]; then
    if [ "$(readlink -- "$HOME/.dotfiles" 2>/dev/null || true)" != "$DOTFILES_DIR" ]; then
      backup_path "$HOME/.dotfiles"
      ln -s -- "$DOTFILES_DIR" "$HOME/.dotfiles"
      info "linked $HOME/.dotfiles -> $DOTFILES_DIR"
    else
      info "already linked $HOME/.dotfiles"
    fi
  else
    ln -s -- "$DOTFILES_DIR" "$HOME/.dotfiles"
    info "linked $HOME/.dotfiles -> $DOTFILES_DIR"
  fi

  link_file "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"
  link_file "$DOTFILES_DIR/vimrc" "$HOME/.vimrc"
  link_file "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

  missing_tools

  info "done. Open a new shell or run: source ~/.bashrc"
  info "existing files were backed up under $BACKUP_DIR when needed"
}

main "$@"
