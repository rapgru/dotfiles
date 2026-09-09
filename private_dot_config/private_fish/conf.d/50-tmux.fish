if status is-interactive; and type -q tmux; and not set -q TMUX
    tmux new-session -A -s main
end