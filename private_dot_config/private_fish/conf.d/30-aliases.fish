if not status is-interactive
    exit
end

abbr dum1 "du --max-depth=1"
abbr dum2 "du --max-depth=2"

abbr .. "cd .."
abbr cd.. "cd .."

if type -q kubectl
  abbr k "kubectl"
end

if type -q bat
  abbr cat "bat --plain"
end

if type -q eza
  abbr ls "eza --icons"
  abbr ll "eza -la --icons --git"
  abbr lt "eza -T --icons --level=2"
end

abbr fr "source ~/.config/fish/config.fish"