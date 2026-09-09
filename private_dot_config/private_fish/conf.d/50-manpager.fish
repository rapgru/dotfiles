if status is-interactive; and type -q bat
  set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
  set -x MANROFFOPT "-c"
end