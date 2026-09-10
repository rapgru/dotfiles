if (( $+commands[gpgconf] )); then
    export GPG_TTY=${TTY:-$(tty)}     # $TTY is a zsh builtin, no fork
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    gpgconf --launch gpg-agent
fi
