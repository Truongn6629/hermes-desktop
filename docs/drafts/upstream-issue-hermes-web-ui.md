# Draft Issue — EKKOLearnAI/hermes-web-ui

**Title:** 项目推荐 / Project showcase: Hermes Desktop —— 把 hermes-web-ui 打成桌面应用

**Body:**

> 你好 👋
>
> 最近做了一个项目 [Hermes Desktop](https://github.com/sir1st/hermes-desktop),把 hermes-web-ui + hermes-agent 打包成跨平台的一体化桌面应用,目标是让不想装 Python / Node 的用户也能用上 Hermes。
>
> ## 关于 hermes-web-ui 的使用方式
>
> - 通过 **git submodule** 引入(锁版本到 v0.6.3),所有代码权属保留
> - 在 Electron 主进程内嵌运行 `dist/server/index.js`(走 `ELECTRON_RUN_AS_NODE`)
> - BSL-1.1 许可证条款全部保留,我的 README 顶部和 License 段都明确指出哪些代码来自贵库
> - 我提了 2 个本地补丁,来自单机桌面场景的需求(都是 idempotent、有 marker comment 的 string replacement,在打包时 apply,**不修改你们仓库**):
>   - `webui-no-credential-change-prompt`:桌面单用户场景下隐藏「请修改默认密码」弹窗
>   - `worker-tcp-everywhere`:`hermes_bridge.py` 在 macOS 桌面环境用 ipc:// 会被 EDR/Gatekeeper SIGKILL,改 TCP loopback 后稳定
>
> 完整改动列表在 [`patches/README.md`](https://github.com/sir1st/hermes-desktop/blob/main/patches/README.md) 和 [`scripts/apply-webui-patches.mjs`](https://github.com/sir1st/hermes-desktop/blob/main/scripts/apply-webui-patches.mjs)。如果上游觉得这两个 patch 中有合理的(尤其 worker-tcp-everywhere,我感觉跨平台都受益),欢迎你们直接 cherry-pick,我也可以另开 PR。
>
> ## 想征询两件事
>
> 1. **使用方式有没有问题?** — submodule + dist 打包 + idempotent patch 这个 pattern,在 BSL-1.1 下我理解没问题,但想确认一下。如果你们更希望用别的形式(比如直接从 npm 装 hermes-web-ui),我可以调整。
> 2. **能否在 README 加一行链接?** — 想到将来如果有人想用 hermes-web-ui 但又怕配 Node 环境,在 README 看到「→ Hermes Desktop」就能直接下载,会不会对你们项目本身的传播也是好事?可以放在「相关项目」或者 README 任何你们觉得合适的位置。
>
> v0.1.0 release: https://github.com/sir1st/hermes-desktop/releases/tag/v0.1.0
>
> 仓库:https://github.com/sir1st/hermes-desktop
>
> 中文 README:https://github.com/sir1st/hermes-desktop/blob/main/README.zh-CN.md
>
> 谢谢!这个项目本身很好,我用得很顺手 🙏

**Labels (suggest):** `documentation`, `discussion`

## 操作步骤(我执行)

```sh
gh issue create --repo EKKOLearnAI/hermes-web-ui \
  --title "..." --body-file <draft>
```
