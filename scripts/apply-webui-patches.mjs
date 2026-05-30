#!/usr/bin/env node
// Apply targeted patches to vendor/hermes-web-ui's built server bundle.
// All edits are idempotent (a marker comment is searched for first).
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(__dirname, '..')
const SERVER_JS = resolve(ROOT, 'vendor/hermes-web-ui/dist/server/index.js')

if (!existsSync(SERVER_JS)) {
  console.error(`server bundle not found at ${SERVER_JS}`)
  process.exit(1)
}

let src = readFileSync(SERVER_JS, 'utf-8')
const before = src
let applied = 0
let skipped = 0

function patch(id, marker, find, replace) {
  if (typeof find === 'string' ? src.includes(marker) : marker.test(src)) {
    console.log(`  · ${id}  (already applied)`)
    skipped++
    return
  }
  if (typeof find === 'string') {
    if (!src.includes(find)) {
      console.log(`  ✗ ${id}  (anchor not found)`)
      return
    }
    src = src.replace(find, replace)
  } else {
    if (!find.test(src)) {
      console.log(`  ✗ ${id}  (regex anchor not matched)`)
      return
    }
    src = src.replace(find, replace)
  }
  console.log(`  ✓ ${id}`)
  applied++
}

console.log(`Patching ${SERVER_JS}`)

// Suppress the "请修改默认账户和密码" prompt — `currentUser` always returns
// requiresCredentialChange:false on desktop. The minified expression looks
// like `requiresCredentialChange:X.username===Y&&Fn(Z,X.password_hash)` —
// match the && verifyPassword(...) call including the inner comma so we
// don't truncate mid-expression and break the bundle.
patch(
  'webui-no-credential-change-prompt',
  /requiresCredentialChange:!1\b/,
  /requiresCredentialChange:[A-Za-z0-9_.$]+===[A-Za-z0-9_.$]+&&[A-Za-z0-9_.$]+\([^)]+\)/,
  'requiresCredentialChange:!1',
)

// Provider OAuth (Codex/xAI/Nous) login fails on Windows with
// `ENOENT: no such file or directory, mkdir ''`. The auth controllers derive
// the credential dir via `authPath.substring(0, authPath.lastIndexOf('/'))`;
// on Windows (backslash paths) lastIndexOf('/') is -1 → empty string → mkdir ''.
// Replace with a separator-agnostic parent-dir computation. There are several
// call sites (codex saveAuthJson + codex CLI tokens, xai, nous), all matched by
// the backreferenced regex below.
// Upstreamed in EKKOLearnAI/hermes-web-ui#1148 — drop this patch once the
// vendored submodule includes it.
patch(
  'webui-auth-dir-windows-path',
  /Math\.max\([A-Za-z0-9_$]+\.lastIndexOf\("\/"\),[A-Za-z0-9_$]+\.lastIndexOf\("\\\\"\)\)/,
  /([A-Za-z0-9_$]+)\.substring\(0,\1\.lastIndexOf\("\/"\)\)/g,
  '$1.substring(0,Math.max($1.lastIndexOf("/"),$1.lastIndexOf("\\\\")))',
)

// Custom avatar upload fails with HTTP 413. Avatars are posted as base64
// image data URLs in a JSON body; the handler allows 1MB of raw image
// (~1.37MB base64), but the body parser is registered with the default 1mb
// jsonLimit, so it 413s before the handler runs. Inject larger json/text
// limits into the bodyParser() call (anchored on the bootstrap log string).
// Upstreamed in EKKOLearnAI/hermes-web-ui#1149 — drop once the submodule has it.
patch(
  'webui-avatar-bodyparser-limit',
  /jsonLimit:"4mb"/,
  /\.use\(([A-Za-z0-9_$]+)\(\)\),console\.log\("\[bootstrap\] cors \+ bodyParser registered/,
  '.use($1({encoding:"utf-8",jsonLimit:"4mb",textLimit:"4mb"})),console.log("[bootstrap] cors + bodyParser registered',
)

if (src !== before) writeFileSync(SERVER_JS, src)

// NOTE: a previous `worker-tcp-everywhere` patch on hermes_bridge.py was
// retired upstream in EKKOLearnAI/hermes-web-ui#1106. The new env vars
//   HERMES_AGENT_BRIDGE_WORKER_TRANSPORT=tcp
//   HERMES_WEB_UI_PREVIEW_AGENT_BRIDGE_TRANSPORT=tcp
// are now set in src/main/webui-server.ts and achieve the same outcome
// without modifying vendored code. PR #1105 also added
//   HERMES_WEB_UI_DISABLE_UPDATE_CHECK=true
// which we set the same way to suppress the bottom-left update prompt.

console.log(`Done. Applied ${applied}, skipped ${skipped}.`)
