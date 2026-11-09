if status is-interactive
    and type -q tmux
    and not set -q TMUX
    and not set -q NVIM                  # Exclude Neovim :terminal
    and not set -q VIM                   # Exclude Vim :terminal
    and test "$TERM_PROGRAM" != "vscode" # Exclude VS Code
    and not set -q TERMINAL_EMULATOR     # Exclude JetBrains integrated terminals
    tmux new-session -A -s main
end