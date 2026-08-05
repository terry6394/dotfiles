# dotfiles

Watch the walkthrough: https://youtu.be/5N-okeDdIuI

My personal Mac setup, managed with nix-darwin and home-manager.
One repo, one command, and a fresh Mac ends up configured the same way every time.

## Contributing / Using This Repo

These are my personal dotfiles, shared publicly so people can read them, learn from them, and fork them freely.
Feature requests and pull requests are not accepted here, and PRs are auto-closed.
If you find a bug, please open a GitHub Issue using the bug report template.

## What you get

Running the switch builds:

- System settings (dark mode, key repeat, dock, Finder, trackpad)
- Homebrew apps (casks and CLI tools)
- Nix user packages (ripgrep, fd, fzf, jq, lazygit, Neovim, Hack Nerd Font)
- Shell (zsh, aliases, starship prompt)
- Editor (Neovim config with the rose-pine moon theme)
- Terminal (WezTerm config with the rose-pine moon theme and dimmed unfocused windows)
- Agent configs (Claude, Codex share one AGENTS.md)
- Optional Pi theme and local extensions, generic UI settings and model overrides, plus two deliberately pinned third-party Pi packages

## Prerequisites

- Apple Silicon Mac, by default.
- Intel Mac: change one line.
  In `configuration.nix`, set `nixpkgs.hostPlatform = "x86_64-darwin";` (the comment right there tells you the same thing).

## Fresh-machine setup

On a brand new Mac, from a bare clone of this repo:

```sh
git clone https://github.com/kunchenguid/dotfiles.git
cd dotfiles
```

Before you run it: review "Make it yours" below.
Change the host label or CPU architecture if needed, and read the Homebrew cleanup warning.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Installs Determinate Nix, if it isn't already installed.
2. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `home.nix` points at config files through `~/.dotfiles`.
3. Checks the `user` configured in `flake.nix` against your actual macOS username, and offers to fix it for you if they differ.
4. Runs the first `darwin-rebuild switch`.
   It fetches the `darwin-rebuild` tool from the nix-darwin 26.05 release branch, then applies this repo's locked flake config.

After that, `darwin-rebuild` exists and you're on the normal workflow below.

### Validate without applying

Once Nix is installed (`bootstrap.sh` step 1 handles that), you can check that the config builds without touching your system - handy when you have edited something:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

If you renamed the host label in "Make it yours", substitute your label for `mac` in these commands.

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

That's it.
No separate build-and-copy step.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh` (it detects your macOS username and offers to set it) OR change the single `user = "kunchen"` line in `flake.nix`.
  Everything else (`configuration.nix`, `home.nix`, home directory paths) is threaded from that one variable.
- **Host label** `"mac"`, in three places: `flake.nix` (the `darwinConfigurations."mac"` name), `rebuild.sh:5` (the `#mac` at the end of the flake reference), and `bootstrap.sh`'s first-switch command (also `#mac`).
  All three have to match.
- **CPU architecture**, `hostPlatform` in `configuration.nix` (see Prerequisites above).
- **Machine label** `"laptop"` in `flake.nix` (the `machine = "laptop"` line): selects the per-machine software tier in `configuration.nix`. Common lists install on every machine; `machineBrews`/`machineCasks`/`machineTaps` only install on the named machine. Add a machine by extending those attrsets and setting `machine` in `flake.nix` on that machine. `bootstrap.sh` detects the host name and asks to confirm or change the label on first setup; `rebuild.sh` refuses to run without a label; the pre-commit hook blocks committing a machine-local label change to `origin/main`.
- **nvm / Node version**: `home.nix` hardcodes `~/.nvm/versions/node/v24.13.1/bin` onto PATH (it carries pi, node, npm). Install nvm and **Node v24.13.1** on every machine so that path exists - a different version silently drops pi/node/npm from PATH.

**Multi-machine sync (different usernames):** `bootstrap.sh` rewrites the `user =` line in `flake.nix` to match each machine's macOS username, so on a machine whose username differs from the shared baseline, `flake.nix` stays **locally modified and uncommitted**. That local personalization is expected - it is the only per-machine difference. Rules:

- Never commit it. `git add -A` stages it too, but the bundled pre-commit hook blocks committing a `flake.nix` whose username differs from `origin/main` (unstage with `git restore --staged flake.nix`; deliberate canonical renames use `git commit --no-verify`).
- Daily `git pull` keeps the local personalization intact - upstream changes rarely touch `flake.nix`. If a pull is refused because it would overwrite the local `flake.nix`: `git stash`, `git pull`, `git stash pop`, then `./bootstrap.sh` to re-personalize if needed.
- `rebuild.sh` aborts before switching if the configured username doesn't match `whoami`, so a lost personalization (e.g. after `git checkout -- flake.nix`) can't silently build for the wrong account.
- Hooks activate automatically on new machines via `bootstrap.sh` (`git config core.hooksPath .githooks`). On an existing machine run that once - then the check is enforced, not remembered. Use the absolute path (`.githooks` relative to the repo root): `git config core.hooksPath "$PWD/.githooks"`.

**Git identity:** this config deliberately does not set your git name or email.
Git will stop your first commit and tell you to set them (`git config --global user.name "Your Name"` and `git config --global user.email you@example.com`).
If you'd rather manage that declaratively, add this back to `home.nix` with your own identity:

```nix
programs.git = {
  enable = true;
  settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
};
```

**Homebrew cleanup warning:** `configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`.
That means every time you switch, Homebrew removes any package or cask on your machine that isn't listed in the `brews` and `casks` arrays in `configuration.nix`.
If you already have Homebrew stuff installed that isn't in that list, the first switch will uninstall it.
Read through `brews` and `casks` before you run `bootstrap.sh` or `rebuild.sh` for the first time, and add anything you want to keep.

**About `herdr`:** it's in the `brews` list.
It's a real public Homebrew formula (`brew info herdr` finds it in homebrew-core, no tap needed), so it will install fine.
If you don't use it, just remove it from `brews` in your copy.

**Heads-up:**

- `home/AGENTS.md` is my personal agent policy, and `home.nix` installs it for Claude and Codex.
  If you clone this repo, you'd silently inherit my agent instructions - edit or delete `home/AGENTS.md` if you don't want that.
- The `cc` and `co` shell aliases in `home.nix` are high-agency shortcuts: `claude --dangerously-skip-permissions` and `codex --full-auto`.
  They're convenient for me, but know what they do before you use them.

## Multi-machine operation

Each machine's config identity is two variables in `flake.nix`: `user` (the macOS account) and `machine` (the software-tier label). Neither is tied to the macOS host name - the host name is only read once during bootstrap to guide confirming the `machine` label.

**Software tiers** (in `configuration.nix`): `common*` lists install on every machine; `machine*` lists install only on the machine whose label matches. Add a machine by extending `machineBrews`/`machineCasks`/`machineTaps` with e.g. `laptop = [...];` and setting `machine = "laptop"` in `flake.nix` on that machine.

**First deploy on a new Mac:**

```sh
git clone --branch v1.1.0 https://github.com/terry6394/dotfiles.git
cd dotfiles
./bootstrap.sh   # installs Nix, links ~/.dotfiles, confirms user + machine label, first switch
```

**Sync an existing machine after this repo changes:**

```sh
cd ~/dotfiles
git pull
# if this machine's machine label differs from the repo default, edit flake.nix locally
./rebuild.sh
```

**Automatic guards:** the pre-commit hook blocks committing a machine-local `user` or `machine` change to `origin/main` (use `git commit --no-verify` only for a deliberate canonical rename); `rebuild.sh` refuses to run without a machine label; `bootstrap.sh` sets both interactively on first setup.

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs, nix-darwin, home-manager, and nix-homebrew, and declares the `mac` machine.
- `configuration.nix` - system-level config: macOS defaults, Homebrew.
- `home.nix` - user-level config: shell, packages, prompt, and the symlinks described below.
- `rebuild.sh` - re-applies the config after the first switch.
  Run this every time you make a change.
- `home/` - the actual config files that get symlinked into place; the sections below explain the shared symlink model and Pi's narrower selective setup.

## How the symlinks work

The files under `home/` are the real files - editing them here is editing your live config, no rebuild needed to see the change in your editor.
`home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/nvim` straight at `home/.config/nvim` in this repo, so the two never drift out of sync.
You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list or a system default.

## Optional Pi configuration

Pi is an opt-in CLI, not a dependency this repository vendors. Install it from its owner with the [official Pi instructions](https://pi.dev), for example:

```sh
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

[Pi Launcher](https://github.com/kunchenguid/homebrew-tap) is also optional and installed from its owner, not declared by this config:

```sh
brew install --cask kunchenguid/tap/pi-launcher
```

Home Manager owns exactly two repository-authored Pi directories: `~/.pi/agent/themes` and `~/.pi/agent/extensions`. It also links `models.json` and `settings.json` as individual files. The local extension directory is for public, repository-authored extensions only - third-party package code never belongs there. Run `/reload` after editing a local extension or other Pi resources. The terminal-title extension shows a spinner while Pi is working, then a completion mark with the session name or current directory. The `rose-pine-moon` theme was authored clean-room from the public [Rosé Pine Moon palette](https://rosepinetheme.com/palette) and Pi's [public theme schema](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json), not from a private or live theme file.

### Pi Calm

`home/.pi/agent/extensions/calm` is a standalone local Pi extension. Home Manager's existing global extensions-directory link makes Pi auto-load it without another declaration. `/calm` toggles a conversation-only presentation mode and is off by default. Its choice is stored locally in `~/.pi/agent/calm` (or the directory selected by `PI_CODING_AGENT_DIR`), not in this repository or Home Manager. Adapted from Firstmate under the bundled MIT license, Calm imports no Firstmate modules and has no Firstmate runtime dependency.

When enabled, Calm hides collapsed thinking and the call/result shells for Pi's seven built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, and `ls`) without leaving blank transcript rows. During an active run it replaces Pi's working row with a two-line animated blue-water, yellow-boat widget. `/calm` restores Pi's stock rendering and preserves the existing Ctrl+O tool-expansion choice.

Calm never changes prompts, tool execution, model context, session data, or ordering. `/share` and `/export` use the complete stock transcript. Generic custom tools, images, and unsupported Pi transcript classes deliberately remain visible because Pi has no safe general-purpose transcript filter. If a future Pi release no longer exports the exact collapsed-thinking rendering seam, Calm logs one diagnostic and leaves only that adapter disabled; all other behavior remains available.

Pi's package system declares two third-party sources in the linked global `settings.json`:

- `npm:@ryan_nookpi/pi-extension-codex-fast-mode@0.2.6` - the exact public npm release from `ryan_nookpi`.
- `git:github.com/algal/pi-openai-server-compaction@c6d593087709e9481223dc6c6c2269b371b5e055` - the exact public `algal` commit for experimental OpenAI server-side compaction.

The version and commit are immutable pins, so Pi does not move them during package updates. Deliberate updates require a new source and security audit, followed by an explicit pin change in `home/.pi/agent/settings.json`. On Pi 0.82.0, global settings declarations install missing pinned packages automatically at startup. No one-time install command is required. Pi keeps the downloaded npm and git package trees in its own unmanaged `~/.pi/agent/npm` and `~/.pi/agent/git` runtime directories, outside Home Manager and Git tracking.

Both packages execute with your full user permissions and must be trusted like any other executable code. The compaction package is experimental, sends the relevant OpenAI compaction and continuity data to OpenAI, and upstream declares the stale peer range `>=0.80.9 <0.81.0`; this exact immutable ref was locally proven to load and perform remote compaction on Pi 0.82.0. Do not treat that proof as a guarantee for a different Pi version or a different package ref.

Home Manager deliberately does not manage `~/.pi/agent` itself, or Pi authentication, sessions, trust decisions, caches, npm/git package trees, or any other runtime state. The model overrides contain no credentials or endpoint settings, do not choose a default model, and only take effect after you authenticate Pi yourself. This remains an additive post-video layer: it does not install Pi, a launcher, or package source code into this repository.

## Optional: Lavish Editor

[Lavish Editor](https://github.com/kunchenguid/lavish-axi) is an AXI for turning agent output into rich HTML artifacts you can annotate and send feedback on from the browser. This repo vendors its `lavish` skill (a single MIT-licensed `SKILL.md`, author Kun Chen) at `home/.agents/skills/lavish`; Home Manager links it into both `~/.agents/skills/lavish` (Pi) and `~/.claude/skills/lavish` (Claude Code). No rebuild needed to use it - invoke `/lavish <request>` or just ask for a visual artifact.

The CLI itself stays on demand (`npx -y lavish-axi <file>` per the skill), or install it globally like Pi and opt into ambient session hooks:

```sh
npm install -g lavish-axi
lavish-axi setup hooks   # SessionStart hook for Claude Code, Codex, OpenCode, Copilot CLI
```

To refresh the vendored skill after upstream changes:

```sh
npx skills add kunchenguid/lavish-axi --skill lavish -g -y
cp ~/.agents/skills/lavish/SKILL.md home/.agents/skills/lavish/SKILL.md
```

## Optional: firstmate

[firstmate](https://github.com/kunchenguid/firstmate) is an agent distro - not an installable package, but a self-contained repo of instructions, skills, and scripts. Clone it once; from inside it, launching Pi (or `pi-signed`, Claude Code, Grok) instantiates your "first mate": a supervisor that dispatches a crew of agents across clean git worktrees and hands you finished PRs.

```sh
git clone https://github.com/kunchenguid/firstmate ~/code/firstmate
cd ~/code/firstmate && pi    # launch your first mate
```

`rebuild.sh` detects a missing clone at `~/code/firstmate` and offers to install it (override the location with `FIRSTMATE_DIR`).

Note: this config does not install tmux, so use the **herdr backend** (already installed) - see the firstmate docs for backend selection. The bundled Pi Calm extension is adapted from firstmate.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.
Neovim and WezTerm both use the rose-pine moon theme.
Neovim keeps italics off and uses a transparent background on macOS, Windows, and WSL so it matches the terminal setup.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
