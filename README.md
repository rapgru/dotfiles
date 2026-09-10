# rapgru's dotfiles

Nothing special, just my config ...

For linux machines, this works best on Ubuntu >= 26.04

## New machine setup

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply rapgru
```

## Shells

Both the fish and zsh configs are deployed on every machine. The `shell` value in
`~/.config/chezmoi/chezmoi.toml` decides only which one `chsh` points at, so switching is cheap and
reversible.

- **Pick a shell:** set `shell = "zsh"` or `shell = "fish"`, then `chezmoi apply`.
- **Try the other one right now:** `exec zsh` / `exec fish` (aliased to `fr` and `ff` in zsh).
- **Existing machines** were initialized before `shell` existed, so they are not re-prompted. Run
  `chezmoi update --init` once to be asked. Until then they fall back to `fish` and nothing changes.
- Note `chezmoi init --promptString shell=fish` will *not* override a value that is already stored —
  `promptStringOnce` short-circuits. Edit the config file instead.

The zsh config lives in `~/.config/zsh` (`ZDOTDIR`), with `~/.zshenv` as the only file in `$HOME`.
It mirrors the fish layout: numbered fragments in `conf.d/` and one file per function in
`functions/`. Plugins are managed by zinit, which is itself cloned by `.chezmoiexternal.toml` — but
the plugins zinit installs under `~/.local/share/zinit/plugins` are *not* tracked, same arrangement
as lazy.nvim below.

Debug a slow startup with `ZSH_PROFILE=1 ZSH_NO_TMUX=1 zsh -i -c exit`. `ZSH_NO_TMUX=1` skips the
tmux auto-attach.

### Retiring fish

Once zsh has proven itself: delete `private_dot_config/private_zsh`'s counterpart
`private_dot_config/private_fish`, drop `brew "fish"` from the common install script, and hardcode
`zsh` in `run_onchange_after_20-setup-shell.sh.tmpl`. chezmoi does not delete files it stops
managing, so also remove `~/.config/fish` by hand or via a temporary `.chezmoiremove`.

## Neovim / LazyVim
Only the config files in ~/.config/nvim are managed by chezmoi. Plugins are not tracked — lazy.nvim installs them automatically on first launch.

### Rule of thumb

Any time you do changes in `nvim` like adding extras or touch a file in `~/.config/nvim/, run chezmoi add on it. On other machines, `chezmoi update` + opening nvim is all you need — lazy.nvim picks up the new spec and installs plugins etc.

### Updating
- Plugins / LazyVim: `:Lazy update` inside Neovim
- Config changes: Edit, then `chezmoi add ~/.config/nvim/…`
- Lockfile sync: `chezmoi add ~/.config/nvim/lazy-lock.json`
- Pull on other machines `chezmoi update && nvim`

### Ayu theme
The Ghostty, Neovim, and tmux configurations share the `ayu_variant` value in
`~/.config/chezmoi/chezmoi.toml`. Set it to `dark`, `mirage`, or `light`, then
run `chezmoi apply` to update all three applications.

### What chezmoi does not manage
- `~/.local/share/nvim/` — plugin code (auto-installed by lazy.nvim)
- `~/.local/state/nvim/` — runtime state
- `~/.cache/nvim/` — cache
