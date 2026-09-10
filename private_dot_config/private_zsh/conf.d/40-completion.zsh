# Homebrew already ships completions for kubectl, helm, git, fzf and friends,
# so putting site-functions on fpath beats eval-ing `<tool> completion zsh`
if [[ -n ${HOMEBREW_PREFIX-} && -d $HOMEBREW_PREFIX/share/zsh/site-functions ]]; then
    fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

_zsh_compinit() {
    # extended_glob is scoped here so it does not leak out and break `HEAD^`
    setopt local_options extended_glob

    local dump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
    [[ -d ${dump:h} ]] || mkdir -p "${dump:h}"

    autoload -Uz compinit
    if [[ -n ${dump}(#qN.mh-24) ]]; then
        # dump is under a day old: -C skips the fpath rescan and the security
        # audit, which is where compinit actually spends its time
        compinit -C -d "$dump"
    else
        compinit -d "$dump"
        zcompile -R -- "$dump.zwc" "$dump" 2>/dev/null
    fi
}

zstyle ':completion:*' matcher-list \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{blue}%B%d%b%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'
zstyle ':completion:*' verbose true
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:*:kill:*:processes' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# fzf-tab replaces the built-in menu and fights with `menu select`
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' fzf-flags --height=45% --layout=reverse
zstyle ':fzf-tab:*' switch-group '<' '>'
if (( $+commands[eza] )); then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons --color=always $realpath'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --icons --color=always $realpath'
fi
