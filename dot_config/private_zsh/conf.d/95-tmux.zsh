# Numbered 95 rather than 50: this command blocks, so anything after it would
# not be loaded until you detach -- including the starship prompt.
if [[ -o interactive ]] &&
    [[ -z ${ZSH_EXECUTION_STRING-} ]] &&     # set by `zsh -c`; keeps `zsh -i -c ...` usable
    [[ -z ${ZSH_NO_TMUX-} ]] &&              # manual escape hatch
    (( $+commands[tmux] )) &&
    [[ -z ${TMUX-} ]] &&
    [[ -z ${NVIM-} ]] &&                     # Exclude Neovim :terminal
    [[ -z ${VIM-} ]] &&                      # Exclude Vim :terminal
    [[ ${TERM_PROGRAM-} != vscode ]] &&      # Exclude VS Code
    [[ -z ${TERMINAL_EMULATOR-} ]] &&        # Exclude JetBrains integrated terminals
    [[ -z ${INSIDE_EMACS-} ]]; then
    tmux new-session -A -s main
fi
