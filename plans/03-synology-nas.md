# Plan 03 — `nas` profile: Synology DSM

**Goal:** SSH into the NAS and get a familiar shell, without fighting DSM and without
anything that a DSM update can brick.

Read `plans/README.md` first, and do its Task 0.

This is the most constrained of the three. DSM is not a general-purpose Linux box and
the usual moves do not apply.

## What is different about DSM, and why

Do not skip this section. Most of the work here is avoiding traps, not writing config.

1. **No Homebrew.** Do not attempt it. Every `run_onchange_*` script in this repo must
   be excluded for this profile.
2. **No `chsh`.** DSM does not ship it. The obvious workaround — editing `/etc/passwd` —
   is both risky and futile: DSM rewrites the file on updates and on user-account
   changes, so the shell silently reverts and you get to debug it again in six months.
3. **DSM updates reset things.** Anything outside the user's home and the package
   manager's own storage should be assumed temporary.
4. **Two ways to get zsh**, and they differ:
   - **SynoCommunity** package (zsh 5.9.2). Two variants exist; pick the **"with
     modules"** one. The plain build fails to load `zsh/stat` and friends, which breaks
     completion in ways that are annoying to diagnose.
   - **Entware/opkg**. More packages available, but it needs a boot-time remount, set up
     as a triggered task in DSM's Task Scheduler. More moving parts, more to lose to an
     update.

   Recommended: **SynoCommunity "with modules"**, for the smaller failure surface. Only
   go to Entware if the user specifically wants tools SynoCommunity lacks.

## Task 1 — the login shell, safely

Since `chsh` is unavailable and `/etc/passwd` is not durable, switch shells from
`~/.profile`, which DSM's default shell reads and which lives in the user's home where
it survives updates.

The guard matters more than the `exec`:

```sh
case $- in
  *i*)
    if [ -x /usr/local/bin/zsh ] && [ -z "$ZSH_VERSION" ]; then
      exec /usr/local/bin/zsh -l
    fi
    ;;
esac
```

Three things this must get right, all of which are ways to lock yourself out or break
file transfers:

- `case $- in *i*)` — **only** for interactive shells. Without it, `scp`, `rsync`,
  `rclone`, and Synology's own internal invocations all get an unexpected zsh and fail.
- `[ -x ... ]` — if the zsh package is uninstalled by an update, fall through to the
  default shell instead of `exec`ing something that no longer exists.
- `[ -z "$ZSH_VERSION" ]` — prevents an infinite exec loop if zsh also reads
  `~/.profile`.

Confirm the actual zsh path on the device before writing it — SynoCommunity and Entware
install to different prefixes.

**Keep a second SSH session open while testing this.** A mistake here locks you out of
SSH, and recovery means the DSM web UI or a factory reset.

## Task 2 — `.chezmoiignore`

Append a `nas` block (do not replace — README Rule 2). This profile is close to
`container` in scope: shell only.

Keep:

- `.zshenv`, `.config/zsh/.zshrc`, `.config/zsh/.zprofile`
- `conf.d/20-options.zsh`, `25-keybindings.zsh`, `30-aliases.zsh`,
  `40-completion.zsh`, `50-manpager.zsh`
- the new `.profile` from Task 1

Ignore everything else: tmux, sesh, neovim, starship, k9s, GPG, git config, and —
critically — **all `run_onchange_*` scripts**. They all assume Homebrew.

Verify the file list with the scratch-directory recipe in `plans/README.md` using
`profile = "nas"`.

## Task 3 — zinit

zinit clones plugins at first interactive start. On a NAS that is slow, competes with
whatever the box is actually for, and adds a network dependency to logging in.

Decide explicitly:

- **Recommended: no zinit on `nas`.** `.chezmoiexternal.toml` must be gated so zinit is
  not cloned, and the warning in `dot_zshrc` must be gated too (same change as Plan 01
  Task 1 — if you did that already, this is free).
  `40-completion.zsh` falls back to eager `_zsh_compinit` when zinit is absent, so
  completion still works. Aliases and keybindings are plain zsh and are unaffected.
- If the user wants plugins anyway, leave `.chezmoiexternal.toml` alone and accept the
  first-login delay.

The visible loss without zinit is syntax highlighting and autosuggestions.

## Task 4 — writable paths

`conf.d/20-options.zsh` puts `HISTFILE` under `$XDG_STATE_HOME` and `mkdir -p`s it, and
completion writes a dump under `$XDG_CACHE_HOME`. Both land in the user's home on DSM,
which is fine — but confirm the home directory is on a volume that is actually writable
and that "User Home" service is enabled in DSM. On some configurations home directories
are disabled entirely and `$HOME` is `/var/services/homes/<user>` pointing nowhere.

Check before assuming:

```sh
touch "$HOME/.write-test" && rm "$HOME/.write-test" && echo ok
```

## Task 5 — installing chezmoi itself

chezmoi ships static binaries, so the simplest path is to drop the right release binary
into `~/bin` rather than trying to package it. Check `uname -m` on the device — Synology
units are variously x86_64, armv7, and aarch64, and picking the wrong one gives an
unhelpful "not found" from the kernel.

Applying with an explicit source and destination avoids any ambiguity:

```sh
~/bin/chezmoi init --apply rapgru
```

Answer `nas` at the profile prompt.

## Acceptance

- SSH in → zsh with aliases, keybindings, and working completion.
- `scp` and `rsync` to the NAS still work — this is the regression Task 1's guard
  exists to prevent, and it is easy to miss because interactive login looks fine.
- `ssh nas 'echo hi'` prints `hi` and exits cleanly.
- No `run_onchange_*` script ran: nothing tried to install Homebrew.
- After a DSM update, SSH still works — worst case it drops back to the default shell,
  never to a broken one.

## Sources

- [Building a statically linked binary in Alpine Linux](https://users.rust-lang.org/t/building-a-statically-linked-binary-in-alpine-linux/47979)
- [Alpine Linux: Effortless static linking and portable applications for C/C++](https://build-your-own.org/blog/20221229_alpine/)
- [Compiling Static Binaries With Alpine](https://moebuta.org/posts/compiling-static-binaries-with-alpine/)

(The static-linking references belong to Plan 01 but are recorded here so the set of
external sources for this work sits in one place.)
