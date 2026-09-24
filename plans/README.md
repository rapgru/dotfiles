# Stripped-down profiles — shared contract

Read this file **before** `01-`, `02-`, or `03-`. It defines the one mechanism all
three plans share, and the four rules that break the repo if you ignore them.

Also read `AGENTS.md` at the repo root first. It is short and it is authoritative.

## The idea

There is one repo and one branch. A single template variable, `profile`, selects how
much of it gets applied:

| profile       | where                          | what it gets                        |
| ------------- | ------------------------------ | ----------------------------------- |
| `workstation` | laptop/desktop (today's setup) | everything — this is the default    |
| `server`      | cloud VMs                      | shell + editor, no GUI/GPG/media    |
| `nas`         | Synology DSM                   | shell only, no Homebrew, no `chsh`  |
| `container`   | cdebug debug image             | shell only, built into an OCI image |

Nothing is deleted or forked. Each profile is expressed as ignore rules, so the
workstation experience is untouched by any of this work.

**Why one repo and not three:** three copies drift. Every fix to `conf.d/30-aliases.zsh`
would need porting three times, and the copies would silently diverge until the server
shell stopped resembling the laptop shell. One repo with ignore rules has exactly one
source of truth per file.

## Task 0 — add the `profile` variable (do this once, before any of the three plans)

Edit `.chezmoi.toml.tmpl`. Add a prompt alongside the existing ones:

```
{{- $profile := promptStringOnce . "profile" "Profile (workstation/server/nas/container)" "workstation" -}}
```

and expose it in the `[data]` block the same way the existing variables are exposed:

```
    profile = {{ $profile | quote }}
```

Match the surrounding style exactly — look at how `shell` and `k8s` are already done
and copy that shape.

Verify:

```sh
chezmoi execute-template '{{ default "workstation" (index . "profile") }}'
```

## Rule 1 — never write `{{ .profile }}`

This is the single most likely way to break the user's working machine.

Existing machines have a `~/.config/chezmoi/chezmoi.toml` that was generated **before**
`profile` existed. `promptStringOnce` will not re-prompt them, so on those machines the
key is missing — and chezmoi treats a missing key as a hard error, not as empty:

```
$ chezmoi execute-template '{{ .profile }}'
chezmoi: template: stdin:1:3: executing "stdin" at <.profile>: map has no entry for key "profile"
```

Every read of the variable, in every file, must use the defensive form:

```
{{ if eq (default "workstation" (index . "profile")) "server" }}
```

or bind it once at the top of the file:

```
{{- $profile := default "workstation" (index . "profile") }}
```

The repo already does exactly this for `shell` in
`run_onchange_after_20-setup-shell.sh.tmpl` — copy that line's shape. A bare
`{{ .profile }}` anywhere makes `chezmoi apply` fail outright on the user's laptop.

## Rule 2 — add to `.chezmoiignore`, never replace it

`.chezmoiignore` already contains rules that matter, including a `.gnupg` gate. Append
your profile block; do not rewrite the file. (A dry run of this work replaced the file
and silently leaked `.gnupg` into a build that was supposed to have no secrets in it.)

Ignore rules are evaluated per target path. The pattern is:

```
{{ if ne (default "workstation" (index . "profile")) "workstation" }}
.config/some-gui-thing
{{ end }}
```

## Rule 3 — edit the source, never `~`

Change files under the repo. Never edit `~/.zshrc` or anything else in the home
directory directly — `chezmoi apply` overwrites it and the change is lost. See
`AGENTS.md`.

## Rule 4 — any new top-level file must be ignored

This `plans/` directory is managed-looking but must not deploy to `~/plans`. It is
already added to `.chezmoiignore` as part of this work. If you add another top-level
doc, add it there too.

## How to verify anything, without touching the real home directory

Apply to a scratch directory instead of `$HOME`:

```sh
mkdir -p /tmp/t && cat > /tmp/t/cfg.toml <<'EOF'
[data]
    profile = "server"
    shell = "zsh"
    email = "x@example.com"
    gpg = false
    latex = false
    media = false
    k8s = false
    ayu_variant = "dark"
EOF

chezmoi apply -S . -D /tmp/t/root --config /tmp/t/cfg.toml --exclude scripts,externals --force
find /tmp/t/root -type f | sort
```

`--exclude scripts,externals` is not optional in a test or a container build. Without
it chezmoi runs the Homebrew installer and clones tpm and zinit over the network.

Syntax-check any zsh you touch:

```sh
zsh -n private_dot_config/private_zsh/dot_zshrc
```

## Definition of done (all three plans)

- `chezmoi apply` still succeeds on a `workstation` config that has **no** `profile` key.
- `chezmoi apply --dry-run` succeeds for each of the four profiles.
- The file list produced for each profile matches the one in that plan.
- No file under `~` was edited by hand.
- Nothing is committed unless the user asks: `.chezmoi.toml.tmpl` sets
  `autoPush = true`, so a commit goes straight to GitHub.
