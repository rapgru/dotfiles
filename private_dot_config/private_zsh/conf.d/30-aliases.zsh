alias dum1='du --max-depth=1'
alias dum2='du --max-depth=2'

(( $+commands[kubectl] )) && alias k='kubectl'

# ls and cat are deliberately not shadowed -- eza and bat differ enough in
# flag handling that aliasing them makes pasted commands behave oddly
if (( $+commands[eza] )); then
    alias l='eza --icons=auto'
    alias la='eza -a --icons=auto'
    alias ll='eza -la --icons=auto --git'
    alias lt='eza -T --icons=auto --level=2'
fi

alias ff='exec fish'
alias zq='zoxide query'
