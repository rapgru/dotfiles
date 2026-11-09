zmodload -i zsh/terminfo 2>/dev/null
bindkey -e

# Up/Down search history for the prefix already typed -- exactly what fish's
# arrow keys do, and built into zsh. (zsh-history-substring-search does
# *substring* matching, which is fzf's ^R behaviour, not fish's.)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# terminals disagree on raw vs application mode, so bind both
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
[[ -n ${terminfo[kcuu1]} ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
[[ -n ${terminfo[kcud1]} ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

# Word motion. Ghostty sets macos-option-as-alt, so Alt+arrows send ^[[1;3x.
bindkey '^[[1;3D' backward-word; bindkey '^[[1;3C' forward-word
bindkey '^[[1;5D' backward-word; bindkey '^[[1;5C' forward-word
bindkey '^[b'     backward-word; bindkey '^[f'     forward-word

bindkey '^[[H'  beginning-of-line; bindkey '^[[F'  end-of-line
bindkey '^[[1~' beginning-of-line; bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char

# make ^W and Alt+Backspace stop at path separators, like fish
autoload -Uz select-word-style && select-word-style bash
bindkey '^[^?' backward-kill-word
bindkey '^U'   backward-kill-line

autoload -Uz edit-command-line; zle -N edit-command-line
bindkey '^X^E' edit-command-line
