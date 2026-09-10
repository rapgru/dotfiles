# .zshenv already ran `brew shellenv`, but on macOS /etc/zprofile runs
# path_helper *after* .zshenv for login shells and shoves /usr/bin back in
# front of Homebrew. Re-assert the order here -- `typeset -U path` in .zshrc
# keeps the first occurrence, so this costs no forks and creates no duplicates.
if [[ -n ${HOMEBREW_PREFIX-} ]]; then
    path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
fi
