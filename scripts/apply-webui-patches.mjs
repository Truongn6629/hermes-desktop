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

if (src !== before) writeFileSync(SERVER_JS, src)
console.log(`Done. Applied ${applied}, skipped ${skipped}.`)
