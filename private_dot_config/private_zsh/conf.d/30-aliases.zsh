alias dum1='du --max-depth=1'
alias dum2='du --max-depth=2'

(( $+commands[kubectl] )) && alias k='kubectl'

# ls and cat are deliberately not shadowed -- eza and bat differ enough in
# flag handling that aliasing them makes pasted commands behave oddly
if (( $+commands[eza] )); then
    alias l='eza --icons'
    alias la='eza -a --icons'
    alias ll='eza -la --icons --git'
    alias lt='eza -T --icons --level=2'
fi

alias fr='exec zsh'
alias ff='exec fish'
