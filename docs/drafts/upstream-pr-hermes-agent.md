# Draft PR — NousResearch/hermes-agent

**Title:** docs: list Hermes Desktop in Community section

**Branch:** `community-hermes-desktop`

**Diff (single line addition to README's Community section):**

```diff
 ## Community

 - 💬 [Discord](https://discord.gg/NousResearch)
 - 📚 [Skills Hub](https://agentskills.io)
 - 🐛 [Issues](https://github.com/NousResearch/hermes-agent/issues)
 - 🔌 [computer-use-linux](https://github.com/avifenesh/computer-use-linux) — Linux desktop-control MCP server for Hermes and other MCP hosts, with AT-SPI accessibility trees, Wayland/X11 input, screenshots, and compositor window targeting.
 - 🔌 [HermesClaw](https://github.com/AaronWong1999/hermesclaw) — Community WeChat bridge: Run Hermes Agent and OpenClaw on the same WeChat account.
+- 📦 [Hermes Desktop](https://github.com/sir1st/hermes-desktop) — Cross-platform desktop installer (.dmg / .exe / .AppImage / .deb) that bundles `hermes-agent` and `hermes-web-ui` into a single download — no Python or Node setup required.
```

## PR description

> Adds [Hermes Desktop](https://github.com/sir1st/hermes-desktop) to the Community section.
>
> Hermes Desktop is an MIT-licensed Electron shell that ships `hermes-agent` (vendored verbatim from PyPI 0.14.0) plus `hermes-web-ui` (vendored as a git submodule) inside a single 200MB installer for macOS arm64/x64, Windows x64, and Linux x64/arm64. The goal is to lower the bar for non-developers — no `pip install`, no `npm install`, no venv, no `.env` editing — so people can try Hermes Agent with a one-click download.
>
> Slots into the same pattern as the existing community entries (`computer-use-linux`, `HermesClaw`).
>
> v0.1.0 release: https://github.com/sir1st/hermes-desktop/releases/tag/v0.1.0
> Repo: https://github.com/sir1st/hermes-desktop
>
> Happy to revise the wording or skip the listing if it doesn't fit your bar for the Community section.

## 操作步骤(我执行)

```sh
gh repo fork NousResearch/hermes-agent --clone --remote=false
# edit README in fork: add the line above
# commit, push, gh pr create
```
