HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=200000
SAVEHIST=200000
[[ -d ${HISTFILE:h} ]] || mkdir -p "${HISTFILE:h}"

setopt SHARE_HISTORY EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY

# AUTO_CD is what makes a bare `..` work, replacing the fish abbreviation
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt INTERACTIVE_COMMENTS NO_BEEP NO_FLOW_CONTROL LONG_LIST_JOBS

# EXTENDED_GLOB is deliberately NOT set globally: it turns `^` into a pattern
# operator, which breaks `git show HEAD^`. The one place that needs it
# (40-completion.zsh) enables it with `setopt local_options`.
