if (( $+commands[gpgconf] )); then
    export GPG_TTY=${TTY:-$(tty)}     # $TTY is a zsh builtin, no fork

    # Taking over SSH_AUTH_SOCK is the point of enable-ssh-support -- it is how
    # gpg-agent displaces the launchd agent on macOS and gnome-keyring on Linux.
    # But inside an *inbound* ssh session an already-set SSH_AUTH_SOCK is the
    # agent `ssh -A` forwarded to us, and overwriting it silently breaks onward
    # `ssh`/`git push` with the forwarded key.
    if [[ -z ${SSH_CONNECTION-} || -z ${SSH_AUTH_SOCK-} ]]; then
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi

    # Still launched even when a forwarded agent won above: gpg-agent is needed
    # for GPG signing regardless of who serves ssh keys.
    gpgconf --launch gpg-agent
fi
