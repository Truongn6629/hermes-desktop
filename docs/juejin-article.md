# 把 17 万 Star 的 Hermes Agent 打包成桌面应用,我踩了 9 个坑

> TL;DR — 把 [NousResearch 的 hermes-agent](https://github.com/NousResearch/hermes-agent)(17 万 ⭐ 的自我改进 AI Agent)和 [hermes-web-ui](https://github.com/EKKOLearnAI/hermes-web-ui) 打包成跨平台桌面应用 [Hermes Desktop](https://github.com/sir1st/hermes-desktop),让用户**下载即用**。本文是这一路踩坑实录,里头有 macOS EDR 杀 unix socket、pip 在公司镜像下静默挂死、electron-builder 矩阵 publish 竞态、不可重定位的 pip shebang 等 9 个**很可能你下次自己打包时也会撞上的**坑。

![Hermes Desktop 主界面](https://github.com/sir1st/hermes-desktop/raw/main/docs/screenshot-chat.png)

## 为什么有这个项目

Hermes Agent 是 Nous Research 开源的自我改进 AI Agent —— 能写技能、能调工具、能挂钉钉/Slack/Telegram 群。功能强,但**对非开发者门槛太高**:

- 装 Python 3.11+
- pip 装 hermes-agent(deps 巨多,公司镜像还容易 hang)
- 装 Node 22+
- 启 Vue 3 + Koa Web UI
- 配 `~/.hermes/.env` 里十几个 env var
- 配 systemd / launchd 让 gateway 后台跑
- 处理 PyPI 与 npm 各自的供应链问题

我想做的事很简单:**打个一体化 dmg/exe/AppImage,用户下载、双击、能聊**。最终产物 200MB,5 平台,自动更新。

下面是实际开工时撞的坑,按出现顺序排,每个坑都有可复现的根因和解法。

---

## 坑 1:Electron 33 没有 `node:sqlite`

`hermes-web-ui` 的 server bundle 用了 `node:sqlite`(Node 22.5+ 才有的内置模块)。Electron 33 内嵌的 Node 是 20.18,启动直接挂:

```
Error [ERR_UNKNOWN_BUILTIN_MODULE]: No such built-in module: node:sqlite
```

**解法**:升 Electron 到 42(内嵌 Node 22)。

**学到了什么**:打包别人的 server 之前先看人家 `package.json` 里 `engines.node` —— `hermes-web-ui` 写的是 `>=23.0.0`,Electron 33 必挂。

---

## 坑 2:pip 在公司 PyPI 镜像下静默挂死

```sh
$ python3 -m pip install hermes-agent==0.14.0
# ...silence for several minutes...
# Bash tool reports exit 137 SIGKILL
```

`hermes-agent` 的 deps 树深,pip 解析在 alibaba 内镜像上(经过公司 EDR/代理)会**没有任何输出地卡住超时**。

**解法**:换 [`uv`](https://github.com/astral-sh/uv)。同样的 deps 用 uv pip 5 秒搞定。我的 `scripts/install-hermes.mjs` 优先 uv,fallback pip:

```js
function hasUv() {
  return spawnSync('uv', ['--version'], { stdio: 'ignore' }).status === 0
}

if (hasUv()) {
  spawnSync('uv', ['pip', 'install', '--python', pyBin, `hermes-agent==${V}`], { stdio: 'inherit' })
} else {
  spawnSync(pyBin, ['-m', 'pip', 'install', `hermes-agent==${V}`], { stdio: 'inherit' })
}
```

CI 用 `astral-sh/setup-uv@v3` action 装 uv。

**学到了什么**:中国境内的 CI 镜像 + 某些公司网络下,pip 的可靠性远不如它的人气。uv 优先。

---

## 坑 3:Pip 装的 `hermes` 启动器 shebang 是绝对路径,无法 relocate

我用 [python-build-standalone](https://github.com/astral-sh/python-build-standalone) 提供的 relocatable Python。但 pip 装下 hermes-agent 后,`bin/hermes` 是这样的:

```
#!/Users/sir1st/code/hermes-desktop/resources/python/mac-arm64/bin/python3
import re; from hermes_cli.main import main
if __name__ == '__main__': main()
```

**问题**:这个 shebang 是构建机器的绝对路径。打进 .app 后路径是 `/Applications/Hermes Desktop.app/Contents/Resources/python/...`,直接挂:

```
bad interpreter: /Users/sir1st/.../python3: no such file or directory
```

**解法**:install 后用 `sh` wrapper 替换 pip 生成的启动器:

```sh
#!/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/python3" -m hermes_cli.main "$@"
```

可移植,无绝对路径。Windows 上对应做一个 `.cmd` wrapper。

```js
// scripts/install-hermes.mjs
const launcher = `#!/bin/sh\nDIR="$(cd "$(dirname "$0")" && pwd)"\nexec "$DIR/python3" -m hermes_cli.main "$@"\n`
writeFileSync(hermesBin, launcher, { mode: 0o755 })
```

**学到了什么**:relocate Python 是一回事,relocate 它装的所有 console_scripts 是另一回事。

---

## 坑 4:agent-bridge 找不到 `run_agent.py`

Web UI 启动时报:

```
[bootstrap] agent bridge failed to start: agent bridge exited before ready code=2
```

bridge 在多个候选位置找 `<agent_root>/run_agent.py`:

```js
// hermes-web-ui/.../manager.ts
const rootCandidates = [
  resolve(binDir, '..'),                  // <bin>/.. 即 venv 根
  resolve(binDir, '..', '..'),
  resolve(binDir, '..', 'hermes-agent'),
  // ...
]
const root = rootCandidates.find(c => existsSync(join(c, 'run_agent.py')))
```

但 pip 把 `run_agent.py` 放在 `site-packages/run_agent.py`,**不在**任何候选里。

**解法**:install 时在 venv 顶层做个 symlink:

```js
const src = `${PY_DIR}/lib/python3.12/site-packages/run_agent.py`
const dst = `${PY_DIR}/run_agent.py`
symlinkSync(src, dst)  // Windows 用 copyFileSync
```

bridge 的第一个 candidate(`<bin>/..`)就命中了。

---

## 坑 5:bridge 启动器从我的 sh wrapper 解析出 `/bin/sh` 当 Python 用

修了坑 4 后,bridge 还是挂,exit code=2。日志里看到:

```
[agent-bridge] starting: /bin/sh hermes_bridge.py --endpoint ipc:///...
```

它用 `/bin/sh` 跑 Python 脚本?查源码:

```ts
function hermesBinPython(): string | undefined {
  const first = readFileSync(hermesBin, 'utf-8').split(/\r?\n/, 1)[0]
  const match = first.match(/^#!\s*(.+)$/)
  const python = match?.[1]?.trim().split(/\s+/)[0]
  return python && existsSync(python) ? python : undefined
}
```

它读 `HERMES_BIN` 文件第一行 shebang 当作 Python 路径。我的 sh wrapper 第一行是 `#!/bin/sh`,它就当 Python 用了。

**解法**:绕过自动检测,在 Electron 主进程里**显式设置** `HERMES_AGENT_BRIDGE_PYTHON`:

```ts
// src/main/webui-server.ts
const env = {
  ...process.env,
  HERMES_BIN: hermesBin(),
  HERMES_AGENT_BRIDGE_PYTHON: bundledPython,  // ← 关键
  HERMES_AGENT_ROOT: pythonDir(),
  // ...
}
```

**学到了什么**:启动器伪装成什么形式,影响远超启动本身。

---

## 坑 6:macOS 沙箱/EDR 在 ~150ms 内 SIGKILL 用 unix socket 的子进程

修完上面所有,bridge 还是挂,这次是 SIGKILL:

```
[agent-bridge] exited code=null signal=SIGKILL
```

奇怪的是:**直接在终端里跑同样的命令完全 OK**。只有从 Electron(未签名)spawn 的 Python 子进程,在 bind unix socket(`ipc:///tmp/hermes-agent-bridge.sock`)的瞬间就被杀。

定位过程:
1. `xattr -cr` 清掉 quarantine 没用
2. `console.log` 看 env、cwd —— 都正常
3. 把 endpoint 改成 `tcp://127.0.0.1:18765` —— **立刻 work**

根因猜测:macOS 系统 + 公司 EDR(我这台是阿里 EDR)对**未签名应用 spawn 的子进程在 /tmp 创建 unix socket** 这个组合特别敏感,会触发反恶意软件杀进程。改 TCP loopback 完全绕过。

**解法**:在 bridge env 里硬编码 TCP endpoint。Worker 进程也有同样的问题,要 patch `_worker_endpoint` 函数让所有平台都走 TCP:

```python
# patches/worker-tcp-everywhere
def _worker_endpoint(key: str) -> str:
    safe = hashlib.sha256(key.encode()).hexdigest()[:16]
    port_base = int(os.environ.get("HERMES_AGENT_BRIDGE_WORKER_PORT_BASE", "18780"))
    return f"tcp://127.0.0.1:{port_base + int(safe[:4], 16) % 1000}"
```

**学到了什么**:macOS 上,「在终端能跑」不代表「Electron 子进程也能跑」。EDR/Gatekeeper 的策略对 spawn chain 敏感。我已经把这个 patch 提到了 hermes-web-ui 上游。

---

## 坑 7:electron-builder + matrix CI 制造重复 draft release

第一版 release.yml 让每个矩阵 job 都 `electron-builder ... --publish always`。结果:

```
$ gh api repos/sir1st/hermes-desktop/releases
v0.0.3 draft=true assets=6
v0.0.3 draft=true assets=4   ← 重复 draft!
```

各 matrix job 几乎同时完成,each goes "release v0.0.3 doesn't exist yet, let me create it as draft" —— 创建了多个。

**解法**:重构成两阶段:

```yaml
build:                          # matrix
  steps:
    - electron-builder --publish never
    - actions/upload-artifact   # 上传到 workflow artifacts(不是 release)

publish:                        # 单个 job
  needs: build
  steps:
    - actions/download-artifact
    - gh release create vX.Y.Z artifacts/*
```

干净、确定、可重试。

---

## 坑 8:Linux arm64 没有 fpm 二进制,deb 打不出来

```
⨯ cannot execute /home/runner/.cache/electron-builder/fpm/fpm-1.9.3-2.3.1-linux-x86/lib/ruby/bin.real/ruby: cannot execute binary file: Exec format error
```

electron-builder 用 fpm 打 .deb,但 fpm 上游没有发布 arm64 的预构建 ruby 二进制,在 Ubuntu arm64 runner 上直接挂。

**解法**:Linux arm64 只发 AppImage,deb 限定到 x64:

```yaml
linux:
  target:
    - target: AppImage
      arch: [x64, arm64]
    - target: deb
      arch: [x64]   # fpm 没 arm64 二进制
```

Linux arm64 用户拿 AppImage 一样能跑。

---

## 坑 9:macos-13 runner 排队 1 小时,macos-15-intel 立等可取

GitHub Actions 上 macos-13(Intel)队列经常长达 30-60 分钟。改成 `macos-15-intel`:

```yaml
- label: macOS x64
  runner: macos-15-intel  # 之前是 macos-13
  electron_target: "--mac dmg --x64"
```

立刻 in_progress,无队列。

---

## 隐藏 boss:`upload-artifact@v4` 的网络抽风

正常的 5 平台 build 完成后,3 个上传步骤报:

```
##[error]Upload progress stalled.
```

GitHub Actions 自家的 artifact storage 偶尔抖动,跟代码无关。我的应对:matrix job 失败后用 `gh api .../rerun-failed-jobs` 单独重跑(整个 run 完成后才允许)。`needs: build` 严格依赖让 publish job 在所有 build 都绿之后才跑,任何失败都是 fail-closed。

---

## 一些次要的好习惯

把所有这些经验放进项目结构里:

```
hermes-desktop/
├── scripts/
│   ├── fetch-python.mjs            # 下载 PBS,版本固定
│   ├── install-hermes.mjs          # uv pip + relocatable launcher + run_agent symlink
│   ├── prune-python.mjs            # 删 __pycache__/tests 减体积
│   ├── apply-hermes-patches.mjs    # 给 hermes-agent 打 6 个本地补丁(idempotent)
│   └── apply-webui-patches.mjs     # 给 hermes-web-ui 打 2 个本地补丁(idempotent)
├── patches/README.md               # 每个 patch 的描述 + 原因 + 上游修复后该删掉的标识
└── electron-builder.yml
```

**所有 patch 用 marker comment 标记**,重复运行 idempotent:

```js
patch(
  'dt-pre-start',
  'def pre_start(self):  # patch:dt-pre-start',  // marker — 已应用就跳过
  oldString,
  newString,
)
```

上游修复了对应问题后,删掉对应 patch 条目即可。整个 packaging 仓库就是一个**会随上游迭代而越变越薄的可演化打包脚本集**。

---

## 致谢

这个项目几乎所有用户能看见的东西都来自上游。**Hermes Desktop 只是个打包壳**:

- 🦾 [hermes-agent](https://github.com/NousResearch/hermes-agent) by Nous Research
- 🎨 [hermes-web-ui](https://github.com/EKKOLearnAI/hermes-web-ui) by EKKO Learn AI

请优先去给上面两个仓库点 ⭐。觉得我这个打包对你有用,顺手给 [hermes-desktop](https://github.com/sir1st/hermes-desktop) 也来一个就感谢了。

下载:[github.com/sir1st/hermes-desktop/releases/latest](https://github.com/sir1st/hermes-desktop/releases/latest)

---

**讨论欢迎**:

- 你打包过类似的(Electron + Python + Node)桌面应用吗?哪些坑我还没踩到?
- macOS unsigned + EDR 杀 unix socket 这个,有没有更优雅的解(比如 entitlements 配置)?
- Tauri 的等价方案怎么搭?有没有谁尝试过同时嵌 Node 和 Python?

仓库:https://github.com/sir1st/hermes-desktop
