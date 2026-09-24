# Plan 01 — `container` profile: a cdebug toolkit image, built on GitHub

**Goal:** an image at `ghcr.io/rapgru/dotfiles-debug` that can be picked from the
Toolkit image dropdown in `.config/k9s/plugins/cdebug.yaml`, so that a debug shell in a
Kubernetes pod comes with the usual zsh, keybindings, aliases and completion.

Read `plans/README.md` first, and do its Task 0.

## The constraint that decides this plan's shape

cdebug has **two** modes, and it picks between them for you. From
`cmd/exec/exec_kubernetes.go`:

```go
useChroot := isRootUser(opts.user) && !isReadOnlyRootFS(pod, targetName) && !runsAsNonRoot(pod, targetName)
```

**Non-chroot mode** (target runs as non-root, *or* has a read-only rootfs): your shell
runs in the toolkit image's own filesystem. `CDEBUG_ROOTFS=/`, `$HOME` is whatever the
image says, the target's filesystem is symlinked at `$HOME/target-rootfs`. Ordinary
dynamically-linked binaries work fine.

**chroot mode** (target runs as root with a writable rootfs): cdebug `chroot`s into the
*target's* rootfs and puts the toolkit on `PATH` via `/.cdebug-<id>`. Your binaries are
loaded from the toolkit but executed with the **target's `/`**. So a dynamically linked
binary looks for `/lib/ld-musl-x86_64.so.1` inside the *target* image — where it does
not exist — and dies with "no such file or directory" before `main()`.

That is why cdebug's own default toolkit is `busybox:musl`, which is statically
compiled, and why it special-cases `nixery` image names by symlinking `/nix` into the
target. A custom image gets neither.

**Therefore: every binary in this image must be statically linked.** This is the single
requirement that makes the image work in both modes. Do not skip it and do not assume
the Alpine `zsh` package is enough — it is dynamically linked and will fail in chroot
mode against exactly the kind of pod you most want to debug.

## Task 1 — gate the zinit warning

`private_dot_config/private_zsh/dot_zshrc` prints this to stderr on every start when
zinit is absent:

```
zinit missing at $ZINIT_HOME -- run 'chezmoi apply' to clone it
```

zinit is deliberately absent on `container` and `nas`, so the warning is wrong there.
Make the `else` branch conditional so the message is only emitted for profiles that
actually expect zinit — `workstation` and `server`.

Use the defensive read (README Rule 1).

## Task 2 — add the `container` block to `.chezmoiignore`

Append (do not replace — README Rule 2) a block that, when `profile` is `container`,
ignores everything except:

```
.zshenv
.config/zsh/.zshrc
.config/zsh/.zprofile
.config/zsh/conf.d/20-options.zsh
.config/zsh/conf.d/25-keybindings.zsh
.config/zsh/conf.d/30-aliases.zsh
.config/zsh/conf.d/40-completion.zsh
.config/zsh/conf.d/50-manpager.zsh
```

Everything else is either useless in a debug container (tmux, sesh, nvim plugins,
starship, k9s, GPG) or actively harmful (anything that shells out to Homebrew).

Note `40-completion.zsh` ends with `(( $+functions[zinit] )) || _zsh_compinit`, so with
zinit absent it runs compinit eagerly. That is what you want here — a verified 1725
completions were available in a stripped test build.

Verify with the scratch-directory recipe in `plans/README.md`, using
`profile = "container"`. The `find` output must match the list above exactly.

## Task 3 — build config

Create `containers/debug/chezmoi-config.toml`:

```toml
[data]
    profile = "container"
    shell = "zsh"
    email = "build@localhost"
    gpg = false
    latex = false
    media = false
    k8s = false
    ayu_variant = "dark"
```

Every key the templates read must be present — the build has no prompt to fall back on.
Grep the repo for `index . "` and `.gpg`/`.k8s`/etc. to confirm you have them all.

## Task 4 — `containers/debug/Dockerfile`

Three stages.

**Stage `zsh`** — build zsh statically on Alpine:

```
apk add build-base ncurses-dev ncurses-static autoconf
./configure --disable-dynamic --disable-gdbm --without-tcsetpgrp LDFLAGS=-static
make
```

`--disable-dynamic` disables zsh's own `dlopen` module loading (separate concern from
`LDFLAGS=-static`); you need both. Do **not** put `-static` in `CFLAGS` during
`configure` — it breaks feature detection.

Verification gate, which must run inside the build so a regression fails CI:

```sh
file /out/bin/zsh | grep -q 'statically linked' || exit 1
```

`-static` silently degrades to dynamic if a static dependency lib is missing, so assert,
don't assume.

**Stage `dots`** — `chezmoi apply` into a rootfs:

```sh
chezmoi apply -S /src -D /rootfs --config /src/containers/debug/chezmoi-config.toml \
  --exclude scripts,externals --force
```

`--exclude scripts,externals` is mandatory: without it the build runs the Homebrew
installer and clones tpm and zinit.

Then pre-warm the completion dump so the first shell in a live incident is not spent
compiling completions, and so the image works with a read-only filesystem:

```sh
HOME=/rootfs ZDOTDIR=/rootfs/.config/zsh /out/bin/zsh -ic 'exit'
```

This writes `.cache/zsh/zcompdump-5.9` and `.zwc`. Confirm both exist afterwards.

**Final stage** — `FROM scratch` (or `busybox:musl` for a usable `sh` alongside), with
the static binaries in `/bin` and the applied dotfiles at `/root`.

Put the dotfiles at `/root`, not somewhere exotic: in chroot mode the toolkit is at
`$CDEBUG_ROOTFS`, so `/root/.config/zsh` is addressable as
`$CDEBUG_ROOTFS/root/.config/zsh` and the entry command below works in both modes.

Add other static tools as you like — `busybox`, and statically built `jq`, `curl`,
`strace` are the usual suspects. Keep the image small; it is pulled during incidents.

## Task 5 — the entry command

In chroot mode `$HOME` still points at the *target's* `/root`, which is not where the
dotfiles are. So the plugin must set both variables explicitly:

```sh
env HOME=$CDEBUG_ROOTFS/root ZDOTDIR=$CDEBUG_ROOTFS/root/.config/zsh $CDEBUG_ROOTFS/bin/zsh
```

In non-chroot mode `CDEBUG_ROOTFS=/`, so the same string collapses to
`HOME=/root ZDOTDIR=/root/.config/zsh /bin/zsh` and is still correct. One command, both
modes — this is the point of putting the files at `/root`.

Environment variables do survive the chroot (verified), so `$CDEBUG_ROOTFS` is readable
by the command cdebug launches.

## Task 6 — GitHub Actions

Create `.github/workflows/debug-image.yml`:

- triggers: `push` to `main` limited to `paths:` `containers/debug/**`,
  `private_dot_config/private_zsh/**`, `.chezmoiignore`, plus `workflow_dispatch`
- `permissions: { contents: read, packages: write }`
- `docker/setup-qemu-action` + `docker/setup-buildx-action`
- `docker/login-action` against `ghcr.io` with `${{ github.actor }}` and
  `${{ secrets.GITHUB_TOKEN }}` — no new secret needs creating
- `docker/build-push-action` with `platforms: linux/amd64,linux/arm64`,
  `context: .` (the build needs the repo root, not `containers/debug`),
  `file: containers/debug/Dockerfile`,
  `cache-from`/`cache-to: type=gha` — the static zsh build is slow, cache it
- tags: `ghcr.io/rapgru/dotfiles-debug:latest` and `:${{ github.sha }}`

Pin every action to a major version tag at least.

`arm64` matters: nodes are frequently Graviton or Ampere, and a wrong-arch toolkit fails
at exec time with a confusing error.

After the first successful run, make the package public in the GitHub UI (Packages →
package → settings), or every `cdebug` call needs an image pull secret in the cluster.

## Task 7 — wire it into the k9s plugin

In `private_dot_config/k9s/plugins/cdebug.yaml`, add
`ghcr.io/rapgru/dotfiles-debug:latest` to the `options:` list of the `image` dropdown
in **both** the `cdebug` and `cdebug-pod` entries, and make it the `default:`.

Keep the existing nixery/netshoot/busybox options as fallbacks — if the image fails to
pull mid-incident, switching entries in a dropdown is faster than debugging a registry.

The file has a comment explaining the nixery `rm -rf /nix` special case. Leave it; it
still applies to that option.

## Acceptance

- `docker run --rm -it ghcr.io/rapgru/dotfiles-debug env HOME=/root ZDOTDIR=/root/.config/zsh /bin/zsh`
  gives an interactive zsh with the aliases and keybindings present.
- `file` reports `statically linked` for every binary in `/bin`.
- Against a pod running as **root** (chroot mode), Shift-X in k9s lands in a zsh whose
  `ls /` shows the *target's* filesystem.
- Against a pod with `runAsNonRoot: true` (non-chroot mode), Shift-X lands in a zsh
  where the target's filesystem is at `$HOME/target-rootfs`.

Those last two are different code paths. Test both; passing one proves nothing about
the other.
