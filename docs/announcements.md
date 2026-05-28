# Hermes Desktop 推广物料

适合 v0.1.0 首发使用。每段尽量自包含,直接复制粘贴。

---

## 1. Twitter / X (英文,~280 字符)

> Just shipped Hermes Desktop v0.1.0 — an all-in-one cross-platform packaging of @NousResearch's hermes-agent + EKKO Learn AI's hermes-web-ui.
>
> Bundles Python + agent + web UI into one dmg/exe/AppImage. No `pip install`, no `npm install`. Download → run → chat.
>
> 5 platforms · MIT · github.com/sir1st/hermes-desktop

带图建议:`docs/screenshot-chat.png`

---

## 2. Twitter / X (中文)

> 把 Hermes Agent + hermes-web-ui 打包成了一个跨平台桌面应用,下载即用 —
>
> 不用装 Python、不用装 Node、不用配 venv。
>
> ✅ macOS / Windows / Linux 全平台 dmg/exe/AppImage
> ✅ 钉钉、Slack、Telegram 等消息平台开箱即用
> ✅ 自动更新
>
> github.com/sir1st/hermes-desktop

---

## 3. Show HN 草稿

**标题:** Show HN: Hermes Desktop – one-click installer for the Nous Research Hermes Agent

**正文:**

> Hi HN — I built Hermes Desktop, a thin Electron shell that packages NousResearch/hermes-agent (a self-improving AI agent in Python) plus EKKO Learn AI's Vue 3 dashboard for it into a single download. The goal: lower the bar so non-developers can use Hermes without `pip install` or running a Node server.
>
> What's inside the dmg/exe/AppImage:
>
> - python-build-standalone (CPython 3.12, relocatable)
> - `pip install hermes-agent` baked in at build time
> - The web UI's pre-built Koa server, run inside Electron via `ELECTRON_RUN_AS_NODE`
> - `electron-updater` so future versions push automatically
>
> Things that turned out non-obvious while shipping this:
>
> 1. macOS EDR/sandbox kills unix-socket children of unsigned Electron apps within ms — had to flip the agent bridge to TCP loopback for both broker and worker.
> 2. pip's resolver hangs for minutes on some corporate mirrors when expanding hermes-agent's deps; uv finishes the same in seconds. Switched our installer step to uv with pip fallback.
> 3. electron-builder + GitHub Releases + matrix CI = race condition: each matrix job creates its own draft. Fixed by letting matrix jobs only emit workflow artifacts and having one final job run `gh release create`.
> 4. The pip-installed `hermes` script bakes in an absolute Python shebang — useless inside a relocatable .app payload. Replaced with a relative `#!/bin/sh` wrapper.
>
> Repo + 6-platform release: https://github.com/sir1st/hermes-desktop
>
> Almost all the user-visible surface comes from the two upstream projects — this is mostly packaging, signing-free first-run hints, and idempotent patches against bundled artifacts. Credit where it's due:
>
> - hermes-agent (Nous Research): https://github.com/NousResearch/hermes-agent
> - hermes-web-ui (EKKO Learn AI): https://github.com/EKKOLearnAI/hermes-web-ui
>
> Happy to answer questions about the bundling pipeline.

---

## 4. Reddit 草稿

**Subreddits 候选:**

- r/LocalLLaMA — focus on running locally, chatbots
- r/selfhosted — appeals to "no Docker, no compose" crowd
- r/electronjs — packaging story
- r/MachineLearning (Show only — needs more substance)

**标题:** Hermes Desktop — packaged Nous Research Hermes Agent into a 200MB dmg/exe/AppImage so non-devs can use it

**正文:**

> Hermes Agent (NousResearch/hermes-agent) is a great self-improving Python agent but the install path is scary for non-developers (Python 3.11+, pip, optional uv, configure providers, run a separate web UI server). I packaged the whole thing as Electron + bundled Python + bundled web UI so it's a single download.
>
> Works on macOS arm64/x64, Windows x64, Linux x64/arm64. ~200MB per platform. MIT.
>
> Connects to OpenAI/DeepSeek/Anthropic/local models through hermes-agent's existing provider system. DingTalk, Slack, Telegram bots work out of the box (no env file editing).
>
> Repo: https://github.com/sir1st/hermes-desktop
> Release: https://github.com/sir1st/hermes-desktop/releases/latest
>
> No code signing yet, so first run on macOS needs `xattr -cr` and Windows needs SmartScreen click-through — README has the one-liners.

---

## 5. 中文发布稿(掘金 / V2EX / 即刻)

**标题:** 把 Hermes Agent 打包成了一个 dmg/exe,下载就能用

**正文:**

最近发现 [Nous Research 的 hermes-agent](https://github.com/NousResearch/hermes-agent) 真好用 —— 自我改进、能写技能、能调工具、能挂钉钉/Slack/Telegram 群。但缺点也明显:**对非开发者门槛太高**(装 Python、pip 配 deps、起 Node Web UI、写 .env、装 systemd...)。

于是有了 **Hermes Desktop** —— 把 hermes-agent + [hermes-web-ui](https://github.com/EKKOLearnAI/hermes-web-ui) 打成一个 200MB 的桌面应用。

**用户视角**:下载 dmg → 拖到应用程序 → 点开就是聊天界面。配上自己的 API key(DeepSeek/OpenAI/Anthropic 都行),立刻能聊。想接钉钉机器人?左边「频道」填一下 Client ID 就行,gateway 自动重启。

**技术视角**(踩了一堆坑):

- 用 [python-build-standalone](https://github.com/astral-sh/python-build-standalone) 嵌 Python,uv 装 hermes-agent
- Electron 主进程跑 hermes-web-ui 的 Koa server(`ELECTRON_RUN_AS_NODE`),BrowserWindow 加载 `http://127.0.0.1:8648`
- 自动登录 + 弹窗压制(server bundle 级 patch)
- agent-bridge 全链路改 TCP —— 修了一个 macOS EDR 杀 unix socket 的诡异 bug
- 自动更新走 GitHub Releases + electron-updater
- 5 平台 CI(用一个最终 publish job 解决 electron-builder 矩阵竞态)

**所有用户能看到的东西几乎都是上游做的**,这个仓库主要是打包工程。所以请优先去给:

- ⭐ https://github.com/NousResearch/hermes-agent
- ⭐ https://github.com/EKKOLearnAI/hermes-web-ui

点 Star。觉得我这个打包有用,顺手 https://github.com/sir1st/hermes-desktop 也来一个就感谢了。

下载:https://github.com/sir1st/hermes-desktop/releases/latest

---

## 6. 微博 / 即刻 短版

> 把 Hermes Agent 打包成 dmg/exe/AppImage 了,免装 Python 免装 Node。macOS / Windows / Linux 全平台。配上 API key 就能用,接钉钉机器人也开箱即用。
>
> github.com/sir1st/hermes-desktop

---

## 7. 给上游作者的私信草稿

发给 Nous Research 和 EKKO Learn AI:

**Twitter/X DM 或 GitHub issue (英文):**

> Hi — I built a packaging shell that bundles your project into a single-file desktop installer (macOS/Windows/Linux). It's MIT, vendors your release verbatim, and the README leads with credit + a link to your repo.
>
> Repo: https://github.com/sir1st/hermes-desktop
> v0.1.0 release: https://github.com/sir1st/hermes-desktop/releases/tag/v0.1.0
>
> Goal is to make it 1-click for non-developers to try the agent. Two questions:
> 1. Any concerns with the approach? Happy to adjust if anything bothers you.
> 2. If you're OK with it, would you consider linking it from your README so users who want a GUI installer can find it?
>
> Thanks for the project — it's great to work with.

**EKKO Learn AI(中文):**

> 你好 👋,我做了一个把 hermes-web-ui + hermes-agent 打成一体化桌面应用的项目,跨平台 dmg/exe/AppImage,主要面向想用 Hermes 但不想配 Python/Node 的非开发者用户。README 顶部有完整致谢和指向贵库的链接。
>
> 仓库:https://github.com/sir1st/hermes-desktop
>
> 想征询两件事:
> 1. 这个方式你们这边介意吗?如果有任何想调整的我都可以改
> 2. 如果不介意,能否考虑在 hermes-web-ui 的 README 里加一行链接,让需要 GUI 安装包的用户找到?
>
> 项目本身是 MIT,完全开源,所有打包脚本都在仓库里。

---

## 8. 发布顺序建议

按粘性 / 反弹风险从低到高:

1. **D-day**:Twitter/X 中英文一发(以 `docs/screenshot-chat.png` 为图)
2. **D+1**:私信上游作者(他们觉得 OK 是后续推荐的关键)
3. **D+2**:V2EX「分享创造」节点 + 即刻 + 微博
4. **D+3**:掘金长文(展开技术踩坑细节,容易上首页)
5. **D+5**:Reddit r/selfhosted + r/LocalLLaMA(需要英文截图 + GIF)
6. **D+7**:Show HN(英文,周二周三 UTC-5 9-11am 是甜点时段)

**不要做的事**:同一天往多个 subreddit 投同一篇(会被标 spam);批量加 GitHub stars(易封号);评论里硬塞链接(版主会删)。

## 9. 还需要的物料(我可以做)

- [ ] 一个 30s 的 demo gif/mp4(打开应用 → 配 API key → 聊一句 → 钉钉里 @ 机器人)
- [ ] OpenGraph / social-card 图(发链接时预览图,1200x630)
- [ ] 中文掘金长文版(展开技术踩坑章节)
- [ ] HN 评论里可能会被问的 FAQ 准备答案
