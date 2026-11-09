(( $+functions[zinit] )) || return

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=80

# Order matters:
#   1. zsh-completions must be on $fpath before compinit runs.
#   2. compinit runs from the atinit below, replaying compdefs that zoxide,
#      mise and fzf queued through zinit's compdef shim (zicdreplay).
#   3. fzf-tab needs compinit done; syntax-highlighting must be sourced last,
#      after every `zle -N`.
# `atload'!_zsh_autosuggest_start'` is required under turbo -- the plugin's own
# precmd hook is missed because precmd already fired; `!` resets the prompt so
# the suggestion actually renders.
zinit wait lucid for \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions \
    atinit'_zsh_compinit; zicdreplay' \
        Aloxaf/fzf-tab \
    atload'!_zsh_autosuggest_start' \
        zsh-users/zsh-autosuggestions \
        zsh-users/zsh-syntax-highlighting
