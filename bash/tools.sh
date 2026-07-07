# Optional tool integrations. Every block checks availability before loading.

# Preferred editor.
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  export VISUAL=nvim
elif command -v vim >/dev/null 2>&1; then
  export EDITOR=vim
  export VISUAL=vim
else
  export EDITOR=${EDITOR:-vi}
  export VISUAL=${VISUAL:-$EDITOR}
fi

# fzf key bindings and completion.
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_OPTS=${FZF_DEFAULT_OPTS:-'--height 40% --layout=reverse --border'}

  for _df_fzf in \
    "$HOME/.fzf.bash" \
    "/usr/share/fzf/key-bindings.bash" \
    "/usr/share/doc/fzf/examples/key-bindings.bash" \
    "/usr/local/opt/fzf/shell/key-bindings.bash" \
    "/opt/homebrew/opt/fzf/shell/key-bindings.bash"
  do
    if [ -r "$_df_fzf" ]; then
      # shellcheck source=/dev/null
      . "$_df_fzf"
      break
    fi
  done

  for _df_fzf_completion in \
    "/usr/share/fzf/completion.bash" \
    "/usr/share/doc/fzf/examples/completion.bash" \
    "/usr/local/opt/fzf/shell/completion.bash" \
    "/opt/homebrew/opt/fzf/shell/completion.bash"
  do
    if [ -r "$_df_fzf_completion" ]; then
      # shellcheck source=/dev/null
      . "$_df_fzf_completion"
      break
    fi
  done
  unset _df_fzf _df_fzf_completion
fi

# tmux convenience only when tmux exists and we are not already inside tmux.
if command -v tmux >/dev/null 2>&1 && [ -z "${TMUX:-}" ]; then
  alias ta='tmux attach -t'
  alias tls='tmux ls'
  alias tn='tmux new -s'
fi

# Docker and Podman completion are usually supplied by bash-completion packages.
if command -v docker >/dev/null 2>&1; then
  export DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-1}
fi

if command -v podman >/dev/null 2>&1; then
  export PODMAN_USERNS=${PODMAN_USERNS:-keep-id}
fi

