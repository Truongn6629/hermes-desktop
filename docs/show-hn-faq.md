# Show HN — FAQ Preparation

Predicted top comments and prepared replies. Keep tone friendly,
factual, technical-but-not-defensive. Don't over-explain.

---

## "Why Electron and not Tauri?"

> Considered Tauri. Tauri's win on this app would be saving ~80MB of
> bundled Chromium. But the Web UI server is already a Koa Node process,
> so dropping Tauri in means I still ship Node + Chromium-WebView (or
> WebKit). Electron lets the main-process Node = the same Node that runs
> the server, no second runtime. With ~200MB total my install size is
> dominated by bundled Python + node-pty natives + the agent's deps,
> not Chromium. The asymmetry didn't favor Tauri here.
>
> If anyone has shipped a similar bundle in Tauri with both Node and
> Python embedded, I'd love to read the build files.

---

## "Isn't bundling pinned deps a security maintenance burden?"

> Yes — and it's the explicit tradeoff. Two mitigations:
>
> 1. `electron-updater` checks GitHub Releases on every launch. A new
>    Hermes Desktop release covers the agent + UI atomically. Worst-case
>    surface = "user hasn't opened the app in a while."
> 2. Future v2 will let users opt into in-place upgrades of the bundled
>    `hermes-agent` via `pip install -U` against the bundled venv —
>    matches Hermes Agent's "self-improving" vibe and avoids waiting on
>    me to cut a release for an upstream patch.
>
> For zero-trust or air-gapped scenarios this isn't the right tool.

---

## "Why not just publish to Homebrew / Chocolatey / apt?"

> No reason except time. The build pipeline already produces .dmg /
> .exe / .deb / .AppImage; cask + nupkg + apt repo wrappers should be
> straightforward additions. PRs welcome.

---

## "Code signing / notarization?"

> Not yet. v0.x is unsigned because I don't have an Apple Developer ID
> or Windows EV cert. README has the `xattr -cr` and SmartScreen
> click-through one-liners. If the project gets meaningful traction I'll
> set up signing — for a pre-1.0 packaging shell it didn't feel worth
> the cert + setup cost yet.
>
> Already structured `electron-builder.yml` so flipping signing on is
> a config change, not a rewrite.

---

## "What happens if the upstream `hermes-agent` introduces a breaking change?"

> Pinned to `hermes-agent==0.14.0` in `scripts/install-hermes.mjs` and
> `hermes-web-ui` to its current submodule SHA. Bumping is a manual
> step (intentionally — supply-chain attacks via auto-bumped pins are
> exactly what the upstream `hermes-agent` exact-pinning policy is
> designed against; I follow the same).
>
> When I bump, I re-run the patch scripts (idempotent — they no-op if
> already applied or skip if anchor strings have changed). If an anchor
> moves, the script logs a clear "anchor not found" warning and the
> build still succeeds; that's the signal to update the patch.

---

## "Does this run hermes-agent in offline / fully-local mode?"

> hermes-agent supports any OpenAI-compatible API (DeepSeek, Anthropic,
> OpenRouter, ollama, local llama.cpp servers, etc.). The desktop
> bundle doesn't change provider plumbing at all — same `~/.hermes/`
> config, same `hermes auth add` flow. So yes, you can point it at a
> local llama.cpp / ollama and never make an outbound call.

---

## "Why is the macOS dmg 200MB? That's huge for an unsigned binary."

> Breakdown roughly:
>
> - Electron framework (Chromium + Node + V8): ~110MB
> - Bundled CPython 3.12 + hermes-agent's pip install (psutil,
>   pydantic-core, prompt-toolkit, tiktoken, etc., much of it native
>   wheels): ~60MB after pruning `__pycache__` / `tests` / `idle*`
> - hermes-web-ui dist + node-pty prebuilds for the current platform: ~30MB
>
> Differential update via `latest-mac.yml` blockmaps means subsequent
> updates only download deltas (typically 10-30MB), but the first
> install pays the full price.

---

## "macOS sandbox killing unix sockets — say more?"

> The `hermes-agent` web UI's bridge defaults to
> `ipc:///tmp/hermes-agent-bridge.sock`. When Electron (unsigned, with
> default entitlements) spawns Python as a child, and that Python tries
> to bind a unix socket in `/tmp`, on macOS systems with EDR (corporate
> antivirus, Gatekeeper hardening) the child gets SIGKILL'd within
> ~150ms. The kill happens before the Python process emits its
> "ready" event so it looks like a startup hang.
>
> Switching the bridge to `tcp://127.0.0.1:18765` (broker) and
> `tcp://127.0.0.1:18780+hash%1000` (per-profile worker) bypasses
> the issue entirely. The patch is in
> [`scripts/apply-webui-patches.mjs`](https://github.com/sir1st/hermes-desktop/blob/main/scripts/apply-webui-patches.mjs)
> — `worker-tcp-everywhere`. I'm proposing it upstream too since
> tcp loopback isn't slower in any way that matters here.

---

## "Auto-update on a desktop app sounds risky."

> Standard `electron-updater` behavior: it checks the GitHub Releases
> feed (`latest-mac.yml` etc.), downloads the new dmg in the
> background to a staging dir, prompts before install. User can ignore.
> Updates are over HTTPS to github.com.
>
> Not silent install, not background mandatory update. Same model as
> VS Code, Linear, Slack desktop, Cursor.

---

## "Why fork README of hermes-agent for a self-promo PR?"

> Their README's `## Community` section already lists 2 community
> projects (`computer-use-linux`, `HermesClaw`) with the same shape
> as my entry — I followed the established pattern. PR doesn't change
> any code or config, just one bullet point. Expectation is they'll
> accept or close, no opinion either way.

---

## "OK but does the bot actually work?"

> Tested end-to-end on macOS arm64 with DeepSeek + DingTalk:
>
> - Open app → auto-login (no login screen) → chat works in browser pane
> - Configure DingTalk Client ID/Secret in the channel settings
> - @ the bot in DingTalk → bot replies via DeepSeek streaming
>
> Linux + Windows tested at the build level only (CI produces installable
> packages, not yet end-to-end verified by me). If you're on Windows or
> Linux and can spare 5 minutes, I'd love a quick "it ran / it didn't"
> in this thread or a GitHub issue.
