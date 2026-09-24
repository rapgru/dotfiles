# Plan 02 — `server` profile: cloud VMs

**Goal:** `chezmoi init --apply` on a fresh Linux VM gives the same shell muscle memory
as the laptop — zsh, zinit, starship, keybindings, aliases, fzf, zoxide, neovim, tmux —
without dragging in GUI, GPG, LaTeX, media, or macOS-only machinery.

Read `plans/README.md` first, and do its Task 0.

This is the easiest of the three plans. It is mostly subtraction, and the existing
provisioning scripts are already guarded by `if not .gpg` / `if not .latex` style
conditionals, so you are following a pattern that is already in the repo rather than
inventing one.

## Task 1 — decide the package manager question, and write down the answer

The repo currently provisions everything through Homebrew
(`run_onchange_before_00-install-brew.sh.tmpl` plus the `1x-install-packages-*` scripts).
Homebrew on Linux works, but on a cloud VM it means:

- a ~500 MB install of `/home/linuxbrew` before you get a single tool
- 10+ minutes on first boot, mostly compiling
- a second package universe alongside `apt`/`dnf`, diverging from the distro

Recommended: **keep Homebrew for `server`.** The whole point of this profile is the
laptop's shell on a remote box, and the versions that make that work — `starship`,
`sesh`, `zoxide`, `fzf`, `neovim` — are routinely too old in distro repos. Paying the
install cost once per VM buys actual parity. Use `mise` (already in the common package
list) for language runtimes as on the laptop.

If the user says these VMs are short-lived or tiny, the alternative is a
`run_onchange_` script that uses the distro package manager for the handful of tools
that exist there and skips the rest. Do not do both. Ask before switching.

## Task 2 — `.chezmoiignore`

Append a `server` block (do not replace — README Rule 2). Ignore:

- anything macOS-specific
- GUI/terminal-emulator config (Ghostty/WezTerm/Alacritty and the like — check what is
  actually in `private_dot_config/`)
- `.gnupg` unless the user wants signed commits from servers; default to ignoring it,
  and note that forwarding the agent over SSH (`30-gpg-agent.zsh` already has a
  forwarded-agent guard) is the better answer than a keyring on a cloud box
- media, LaTeX

Keep: zsh in full, tmux, sesh, neovim, starship, git.

The existing `conf.d/.chezmoiignore` gating `30-gpg-agent.zsh` on `{{- if not .gpg }}`
is the exact pattern to copy.

## Task 3 — trim the provisioning scripts

`run_onchange_10-install-packages-common.sh.tmpl` installs ~40 formulae. Wrap the
desktop-only ones in a profile conditional rather than deleting them.

Also check each of these for things that cannot work on a headless Linux VM:

| script                                     | action                                             |
| ------------------------------------------ | -------------------------------------------------- |
| `run_onchange_14-install-packages-macos.*` | already gated by OS; confirm it no-ops              |
| `run_onchange_15-...media`                 | gate on profile as well as `.media`                 |
| `run_onchange_13-...latex`                 | gate on profile as well as `.latex`                 |
| `run_onchange_11-...k8s`                   | leave as-is — `k8s` is already its own prompt       |
| `run_onchange_after_26-tmux-plugins`       | keep; tmux is wanted                                |
| `run_onchange_after_25-mise-install`       | keep                                                |

## Task 4 — the login shell

`run_onchange_after_20-setup-shell.sh.tmpl` runs `sudo chsh`. On a cloud VM this is
usually fine (you normally have sudo), but two things differ from the laptop:

1. **Cloud-init may reset the shell** on some images. Verify after a reboot, not just
   after the first apply.
2. **Do not let a broken shell lock you out.** The script must confirm the target shell
   exists and is listed in `/etc/shells` *before* calling `chsh`. If it is not, add it.
   A `chsh` to a nonexistent path makes SSH logins fail immediately, and on a cloud VM
   with no console that is a rebuild.

Add that guard if it is not already there. This is the one genuinely dangerous step in
this plan.

## Task 5 — the tmux auto-attach

`private_dot_config/private_zsh/conf.d/95-tmux.zsh` auto-attaches on interactive start.
On a server reached over SSH this is usually *desirable* — it is what makes a dropped
connection survivable.

But check its guards carefully against the server case: it must not fire inside
`scp`/`rsync`/non-interactive sessions, or file transfers break in confusing ways. The
existing guards already check several env vars; verify they cover `SSH_ORIGINAL_COMMAND`
and a non-tty stdin. Test with:

```sh
ssh vm 'echo hi'        # must print hi and exit, no tmux
scp file vm:/tmp/       # must succeed
ssh vm                  # must land in tmux
```

## Task 6 — bootstrap docs

Add a short section to `README.md` with the one-liner for a fresh VM:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply rapgru
```

and note that the profile prompt must be answered `server`.

Consider `--promptString profile=server` to make it non-interactive for automation; check
the flag name against the installed chezmoi version before writing it down.

## Acceptance

- Fresh VM, one command, reboot, SSH in → zsh with starship, fzf, zoxide, aliases, tmux
  auto-attach.
- `ssh vm 'echo hi'` prints `hi` and exits.
- `chezmoi apply --dry-run` on the laptop (no `profile` key in its config) still
  succeeds — this is Rule 1 and it is the failure mode that costs the user real time.
