# Completion and readline behavior.

# Bash history: large, timestamped, deduplicated, and shared across terminals.
HISTFILE=${HISTFILE:-$HOME/.bash_history}
HISTSIZE=${HISTSIZE:-100000}
HISTFILESIZE=${HISTFILESIZE:-200000}
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE='ls:ll:la:l:cd:cd -:pwd:exit:history'
HISTTIMEFORMAT='%F %T '
export HISTFILE HISTSIZE HISTFILESIZE HISTCONTROL HISTIGNORE HISTTIMEFORMAT

shopt -s histappend
shopt -s cmdhist
shopt -s checkwinsize
shopt -s cdspell 2>/dev/null || true
shopt -s direxpand 2>/dev/null || true

# Merge commands from concurrent terminals at each prompt.
__df_history_sync() {
  builtin history -a
  builtin history -n
}
__df_prompt_command_add __df_history_sync

# Readline: zsh-like history prefix search and friendlier completion.
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[5~": history-search-backward'
bind '"\e[6~": history-search-forward'
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set show-all-if-unmodified on'
bind 'set colored-stats on' 2>/dev/null || true
bind 'set menu-complete-display-prefix on' 2>/dev/null || true
bind '"\t": menu-complete'
bind '"\e[Z": menu-complete-backward'

# bash-completion paths vary by distribution.
if ! shopt -oq posix; then
  for _df_completion in \
    "/usr/share/bash-completion/bash_completion" \
    "/etc/bash_completion" \
    "/usr/local/etc/profile.d/bash_completion.sh" \
    "/opt/homebrew/etc/profile.d/bash_completion.sh"
  do
    if [ -r "$_df_completion" ]; then
      # shellcheck source=/dev/null
      . "$_df_completion"
      break
    fi
  done
  unset _df_completion
fi

