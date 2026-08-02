# Project notes for agents

Deliberate decisions in this repo - do NOT silently revert them:

- `homebrew.onActivation.cleanup = "zap"` in `configuration.nix` is intentional. It forces the good habit of declaring every Homebrew package in the Nix config instead of installing things ad-hoc, which keeps the machine reproducible. Do not soften it to `uninstall` or `none`. Users are warned about its effect in README.md; this note is for anyone tempted to change the setting itself.
- Never commit `.no-mistakes/` validation evidence to this public repo. `.no-mistakes/` is gitignored; if a validation pipeline stages evidence into a branch, drop it before merging.
- **Security/privacy pre-flight before EVERY commit.** This repo is public. Before `git commit`, check:
  - `git status` shows no untracked credentials, auth files, backups, or runtime logs (they belong in `.gitignore`; `home/.pi/agent/auth.json`, `home/.config/herdr/*` runtime files are already covered).
  - Staged content has no secrets or personal data: API keys/tokens (`ghp_`, `sk-`, `AKIA`, `BEGIN ... PRIVATE KEY`), real email/phone/address, or machine identifiers (hostname, MAC address, serial).
  - Every new file's contents were reviewed - never `git add -A` blindly.
  - This checklist applies to git history too: a secret committed once stays in history even if removed later.
- **Upstream sync workflow (on user request).** When the user says to sync upstream (`kunchenguid/dotfiles`), do: `git fetch upstream`; list new commits with `git log --oneline main..upstream/main`; summarize each as usable-feature / fix / irrelevant (this repo is heavily personalized - the user's git identity, agent policy, and local tools are fork-only); wait for the user to pick; then `git cherry-pick` the chosen commits. Never merge upstream wholesale or cherry-pick without the user's explicit pick. After syncing, tag a new release point if the user wants one.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
