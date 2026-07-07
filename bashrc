# ~/.bashrc - portable interactive Bash configuration entrypoint.
# Keep this file small; feature-specific logic lives in bash/*.sh.

# Non-interactive shells should not load interactive customizations.
case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

# Locate the dotfiles directory. install.sh creates ~/.dotfiles for stable lookup.
if [ -z "${DOTFILES_DIR:-}" ]; then
  if [ -d "$HOME/.dotfiles/bash" ]; then
    DOTFILES_DIR=$HOME/.dotfiles
  else
    # Fallback for direct sourcing from the repository.
    _df_source=${BASH_SOURCE[0]:-$0}
    _df_dir=$(cd -- "$(dirname -- "$_df_source")" 2>/dev/null && pwd -P)
    DOTFILES_DIR=${_df_dir:-$HOME/dotfiles}
    unset _df_source _df_dir
  fi
fi
export DOTFILES_DIR

# Avoid duplicate PATH entries while keeping the user's existing order.
_df_path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH=$1${PATH:+":$PATH"} ;;
  esac
}

[ -d "$HOME/.local/bin" ] && _df_path_prepend "$HOME/.local/bin"
[ -d "$HOME/bin" ] && _df_path_prepend "$HOME/bin"
unset -f _df_path_prepend
export PATH

# Load modules. Each module must tolerate missing external tools.
for _df_module in \
  "$DOTFILES_DIR/bash/functions.sh" \
  "$DOTFILES_DIR/bash/aliases.sh" \
  "$DOTFILES_DIR/bash/completion.sh" \
  "$DOTFILES_DIR/bash/tools.sh" \
  "$DOTFILES_DIR/bash/prompt.sh"
do
  [ -r "$_df_module" ] && . "$_df_module"
done
unset _df_module

# Host-specific settings are intentionally kept out of Git.
[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"

# ble.sh is intentionally loaded last because it wraps readline behavior.
if [ -z "${BLE_VERSION:-}" ]; then
  for _df_blesh in \
    "$HOME/.local/share/blesh/ble.sh" \
    "$HOME/.local/share/ble.sh/ble.sh" \
    "/usr/local/share/blesh/ble.sh" \
    "/usr/share/blesh/ble.sh"
  do
    if [ -r "$_df_blesh" ]; then
      # shellcheck source=/dev/null
      . "$_df_blesh" --noattach
      ble-attach
      break
    fi
  done
  unset _df_blesh
fi
