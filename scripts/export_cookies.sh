#!/usr/bin/env bash
set -euo pipefail
# load env if present
source "$(dirname "$0")/_env_loader.sh"

SESSION=${1:-debug}
OUTDIR=${OUT_DIR:-out}
mkdir -p "$OUTDIR"
WS_PORT=${2:-${REMOTE_DEBUG_PORT:-9222}}
# Simple node snippet to get cookies via CDP
if command -v node >/dev/null 2>&1 && [ -f /home/azureuser/.openclaw/node_modules/playwright/index.js ]; then
  NODE_PATH=/home/azureuser/.openclaw/node_modules node -e "(async()=>{const {chromium}=require('playwright');const browser=await chromium.connectOverCDP('http://127.0.0.1:$WS_PORT');const contexts=browser.contexts();const context=contexts.length?contexts[0]:await browser.newContext();const cookies=await context.cookies();require('fs').writeFileSync('$OUTDIR/devtools_cookies.json',JSON.stringify(cookies,null,2));console.log('cookies saved');await browser.close();process.exit(0);})()" || true
else
  echo "Playwright not found. Cannot export cookies via CDP."
  exit 1
fi
