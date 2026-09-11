#!/bin/bash

selected=$(
  sesh list --hide-duplicates --icons | fzf \
    --no-sort --ansi \
    --border-label ' sesh ' \
    --prompt '⚡  ' \
    --header '  ^a all ^t tmux ^x zoxide ^d kill ^f find' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --hide-duplicates --icons)' \
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
    --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --hide-duplicates --icons)'
) || true

[ -n "$selected" ] && sesh connect "$selected"
