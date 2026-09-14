# Guard on lesspipe.sh, not bat -- bat is a different tool and its presence
# says nothing about whether the command below exists.
if status is-interactive; and type -q lesspipe.sh
  eval (lesspipe.sh)
end