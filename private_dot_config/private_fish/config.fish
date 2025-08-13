if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source

    alias dum1="du --max-depth=1"
    alias dum2="du --max-depth=2"

    alias .. "cd .."
    alias cd.. "cd .."
    alias ll "ls -la"
    alias cat bat

    export LESSOPEN="|/opt/homebrew/bin/lesspipe.sh %s"
    set -x LESS_ADVANCED_PREPROCESSOR 1

    fzf --fish | source
end

# Mise
mise activate fish | source

# Homebrew
/opt/homebrew/bin/brew shellenv | source

# Elan (Lean)
if test -e $HOME/.elan/env
    source $HOME/.elan/env
end

# GPG Stuff
set -x GPG_TTY (tty)
set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

