# rapgru's dotfiles

Nothing special, just my config ...

For linux machines, this works best on Ubuntu >= 26.04

## New machine setup

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply rapgru
```

## Neovim / LazyVim
Only the config files in ~/.config/nvim are managed by chezmoi. Plugins are not tracked — lazy.nvim installs them automatically on first launch.

### Rule of thumb

Any time you do changes in `nvim` like adding extras or touch a file in `~/.config/nvim/, run chezmoi add on it. On other machines, `chezmoi update` + opening nvim is all you need — lazy.nvim picks up the new spec and installs plugins etc.

### Updating
- Plugins / LazyVim: `:Lazy update` inside Neovim
- Config changes: Edit, then `chezmoi add ~/.config/nvim/…`
- Lockfile sync: `chezmoi add ~/.config/nvim/lazy-lock.json`
- Pull on other machines `chezmoi update && nvim`

### What chezmoi does not manage
- `~/.local/share/nvim/` — plugin code (auto-installed by lazy.nvim)
- `~/.local/state/nvim/` — runtime state
- `~/.cache/nvim/` — cache
