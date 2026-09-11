# Ensure brew is in PATH for this subshell
test -x /opt/homebrew/bin/brew && eval "$(/opt/homebrew/bin/brew shellenv)"
test -x /home/linuxbrew/.linuxbrew/bin/brew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
test -x /usr/local/bin/brew && eval "$(/usr/local/bin/brew shellenv)"
