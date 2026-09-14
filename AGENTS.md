# AGENTS.md

Notes for AI agents working in this repository.

## The one rule that matters most

**This is a chezmoi _source_ directory, not a live dotfiles tree.** Nothing here is on
`$PATH` or read by any running shell. Filenames are encoded, and most interesting files are
Go templates that do not parse as the language they claim to be.

- To change `~/.config/zsh/.zshrc`, edit `private_dot_config/private_zsh/dot_zshrc`.
- Never edit files under `~` to "fix" something — `chezmoi apply` will overwrite them.
- Never `chmod` files here. Permissions come from the filename attributes below.

## Source-name grammar

Attributes are filename prefixes/suffixes, applied left to right, and they stack.

| In the source tree | Becomes | Meaning |
| --- | --- | --- |
| `dot_zshenv` | `~/.zshenv` | `dot_` → leading `.` |
| `private_dot_config/` | `~/.config/` | `private_` → strip group/other perms |
| `readonly_gpg.conf` | `gpg.conf`, mode `0444` | `readonly_` → drop write bit |
| `executable_cg.fish` | `cg.fish`, mode `0755` | `executable_` → set `+x` |
| `config.tmpl` | `config` | `.tmpl` → rendered as a Go template |
| `run_onchange_*.sh.tmpl` | (not a file) | script, re-run when its rendered text changes |

Attributes apply to the entry that carries them, not to what is nested below. So
`private_dot_config/private_zsh/conf.d/10-env.zsh.tmpl` → `~/.config/zsh/conf.d/10-env.zsh`
with the *directories* `~/.config` and `~/.config/zsh` at `0700` (from `private_`) and the
file itself at the default `0644`, rendered as a template.

Special files: `.chezmoiignore` (don't deploy), `.chezmoiremove` (actively delete from the
target), `.chezmoiexternal.toml` (git repos to clone), `.chezmoitemplates/` (shared template
partials), `.chezmoi.toml.tmpl` (the first-run prompts; its `[data]` keys become top-level
template variables, so `email = ...` is read as `.email`, not `.data.email`).

## Templates

`.tmpl` files are Go templates. **They do not parse as shell/lua/toml until rendered** — a
raw `zsh -n` on one will fail with a syntax error near `{{`. Render first (see Verifying).

Available data, from `[data]` in `.chezmoi.toml.tmpl`:

| Variable | Type | Used for |
| --- | --- | --- |
| `.email` | string | git `user.email` |
| `.gpg` | bool | gates `.gnupg/` and the `30-gpg-agent.*` fragments |
| `.latex`, `.media`, `.k8s` | bool | gate the matching `run_onchange_1x-install-packages-*` scripts |
| `.ayu_variant` | string | `dark` \| `mirage` \| `light`, shared by ghostty/nvim/tmux |
| `.shell` | string | `zsh` \| `fish`; only decides what `chsh` points at |

Plus chezmoi's own `.chezmoi.os`, `.chezmoi.arch`, `.chezmoi.kernel.osrelease` (the WSL
check greps this for `microsoft`).

Shared partials live in `.chezmoitemplates/`:
`{{ template "brew-shellenv.sh" . }}` and `{{ includeTemplate "ayu-variant" . }}`.

All prompts use `promptStringOnce`/`promptBoolOnce`, so **existing machines are never
re-prompted** and `chezmoi init --promptString shell=fish` will _not_ override a stored
value. Editing `~/.config/chezmoi/chezmoi.toml` is the only way to change one.

## Layout

```
dot_zshenv                         → ~/.zshenv          every zsh, incl. non-interactive
private_dot_config/private_zsh/
  dot_zprofile                     → login shells, after /etc/zprofile
  dot_zshrc                        → loader only; sources conf.d/*.zsh in name order
  conf.d/NN-*.zsh[.tmpl]           → interactive-only fragments
  functions/<name>                 → one autoloaded function per file (no shebang, no +x)
private_dot_config/private_fish/   → mirror of the above, fish syntax
private_dot_config/nvim/           → LazyVim; plugins are NOT tracked
private_dot_config/{ghostty,tmux,sesh,tealdeer,mise,git}/
run_onchange_*                     → provisioning scripts (see below)
```

## Where zsh config belongs

This split is deliberate and was a real bug once. Respect it.

- **`dot_zshenv`** — read by *every* zsh: `ssh host 'cmd'`, cron, systemd user units,
  GUI/IDE-spawned processes. `PATH` (Homebrew, mise shims, `~/.local/bin`, elan) and
  `EDITOR` live here, because none of those contexts ever read `.zshrc`. It defines
  `_zsh_base_path`, which is written to be safely re-runnable.
- **`private_zsh/dot_zprofile`** — login shells only, read *after* `/etc/zprofile`. Its
  sole job is re-running `_zsh_base_path` to undo macOS's `path_helper`, which otherwise
  demotes everything `.zshenv` set up to behind `/usr/bin`.
- **`private_zsh/conf.d/`** — interactive-only: aliases, keybindings, history, options,
  completion, prompt, plugins, gpg-agent, tmux auto-attach.

Rule of thumb: if it must work over `ssh host 'cmd'`, it goes in `.zshenv`. If it only
makes sense with a human at a keyboard, it goes in `conf.d/`.

`conf.d/` numbering is load order, and it is load-bearing: `10` env/tools → `20`
options/plugins → `25` keybindings → `30` aliases/gpg → `40` completion → `50` per-tool
integrations → `90` prompt → `95` tmux. Keep `95-tmux` last: it blocks until you detach, so
anything after it would not load until then — including the prompt.

Plugins are zinit in turbo mode (`wait lucid`). `compinit` is deferred into zinit's
`atinit` hook, with an eager fallback at the end of `40-completion.zsh` for when zinit is
missing — do not "simplify" that away, it is what keeps completion alive on a fresh clone.

## Provisioning scripts

`run_onchange_` scripts re-run whenever their **rendered content** changes. To make a
script also re-run when a *different* file changes, embed that file's hash in a comment —
this repo already does it in two places:

```sh
# Re-run this script whenever the global mise config changes:
# {{ include "private_dot_config/mise/config.toml.tmpl" | sha256sum }}
```

If you add a script that depends on a tracked file, add that line too.

Ordering: `run_onchange_before_*` runs before any file is written, plain `run_onchange_NN-*`
in name order, `run_onchange_after_*` after everything is applied. That is why
`after_26-tmux-plugins` can assume tpm has been cloned.

Every script is `#!/bin/bash` with `set -euo pipefail`, opens with
`{{ template "brew-shellenv.sh" . }}` (scripts do not inherit the interactive shell's PATH),
and gates itself with an early `exit 0` rather than wrapping the body in a conditional:

```sh
{{ if not .k8s }}
echo "Skipping k8s packages"
exit 0
{{ end }}
```

## Verifying changes

`chezmoi apply` on a dev box is the real test, but most mistakes are catchable without it:

```sh
chezmoi diff                     # preview every pending change
chezmoi apply --dry-run -v       # same, plus what scripts would run
chezmoi cat ~/.config/zsh/conf.d/10-env.zsh   # render one managed file
chezmoi execute-template < some.tmpl          # render an arbitrary template
chezmoi verify                   # target matches source?
chezmoi doctor                   # environment sanity
```

Syntax checks (render templates first — `zsh -n` reads stdin):

```sh
zsh -n private_dot_config/private_zsh/conf.d/20-options.zsh
chezmoi cat ~/.config/zsh/conf.d/10-env.zsh | zsh -n
fish --no-execute private_dot_config/private_fish/conf.d/30-aliases.fish
```

Templates with an OS conditional have more than one output — render the WSL and non-WSL
branches of `10-env.zsh.tmpl` separately, not just whichever one this machine produces.

For behavioural changes to shell startup, a throwaway `HOME` is the honest test:

```sh
T=$(mktemp -d); mkdir -p $T/.config/zsh
# copy the rendered files in, then:
HOME=$T ZSH_NO_TMUX=1 zsh -i -c 'print -rl -- $path'
env -i HOME=$T TERM=dumb zsh -c 'print -r -- $PATH'   # the non-interactive case
```

## Gotchas

- **`autoPush = true`** in `.chezmoi.toml.tmpl`. When *chezmoi* writes to this repo
  (`chezmoi add`, `chezmoi edit`) it commits and pushes automatically. Direct edits with
  normal tools do not trigger it — but do not assume a commit here stays local.
- **chezmoi never deletes files it merely stops managing.** Removing a source file leaves a
  stale copy on every machine that already applied it. If the leftover is harmful, add it to
  `.chezmoiremove` (and note that the entry can be dropped once all machines have applied).
- **Neovim plugins are not tracked**, only the config. After editing anything under
  `private_dot_config/nvim/`, `lazy-lock.json` may need `chezmoi add` separately.
- `README.md` and this file are in the root `.chezmoiignore`, so they are documentation only
  and never land in `$HOME`. Any new top-level doc needs the same treatment, or it gets
  applied as `~/<name>`.
- zsh function files in `functions/` are autoloaded: **no shebang, no `function` wrapper,
  no executable bit** — just the body, opening with `emulate -L zsh`.

## Conventions

- Comments explain **why**, and name the concrete failure they prevent. The existing ones
  set the bar ("EXTENDED_GLOB is deliberately NOT set globally: it turns `^` into a pattern
  operator, which breaks `git show HEAD^`"). Match that register; do not add comments that
  restate the code.
- Guard every optional tool: `(( $+commands[foo] ))` in zsh, `type -q foo` in fish. Guard on
  the binary you are about to run, not a related one.
- Prefer zsh builtins over forks in startup paths (`${TTY}` over `$(tty)`, `${var:h}` over
  `dirname`, a literal shims path over `mise activate --shims`).

## Non-goals

- **fish/zsh parity is not maintained.** zsh is the primary shell and fish is on the way out
  (see "Retiring fish" in the README). Do not port zsh changes to fish or flag the
  divergence unless asked — `10-env.fish` being empty is known and fine.
- Do not restructure the `conf.d/` fragment layout, swap the plugin manager, or "modernise"
  the prompt without being asked. This config is tuned and commented for specific reasons.
