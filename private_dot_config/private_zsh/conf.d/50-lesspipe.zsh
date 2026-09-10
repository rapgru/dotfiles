# the fish original guards on `bat` here, which is not the binary it runs
if (( $+commands[lesspipe.sh] )); then
    eval "$(lesspipe.sh)"
fi
