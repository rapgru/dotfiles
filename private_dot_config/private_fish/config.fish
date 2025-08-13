if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
end

pyenv init - fish | source
/home/rgruber/.local/bin/mise activate fish | source

alias dum1="du --max-depth=1"
alias dum2="du --max-depth=2"
