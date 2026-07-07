# Compact server-friendly prompt with user, host, path, and optional Git branch.

__df_git_branch() {
  command -v git >/dev/null 2>&1 || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  _df_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) ||
    _df_branch=$(git rev-parse --short HEAD 2>/dev/null) || return 0

  [ -n "$_df_branch" ] && printf ' (%s)' "$_df_branch"
}

__df_set_prompt() {
  # Color escape sequences must be wrapped in \[...\] so readline counts columns.
  _df_reset='\[\e[0m\]'
  _df_path='\[\e[34m\]'
  _df_git='\[\e[33m\]'

  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    _df_user='\[\e[1;31m\]'
    _df_symbol='#'
  else
    _df_user='\[\e[32m\]'
    _df_symbol='$'
  fi

  PS1="${_df_user}\u@\h${_df_reset}:${_df_path}\w${_df_reset}${_df_git}"'$(__df_git_branch)'"${_df_reset} ${_df_symbol} "
  unset _df_reset _df_path _df_git _df_user _df_symbol
}

__df_set_prompt
unset -f __df_set_prompt

