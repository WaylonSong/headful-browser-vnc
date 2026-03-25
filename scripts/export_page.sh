#!/usr/bin/env bash
set -euo pipefail
# load env if present
source "$(dirname "$0")/_env_loader.sh"

SESSION=${1:-debug}
URL=${2:-}
if [ -z "$URL" ]; then echo "Usage: $0 <session> <url> [devtools-port]"; exit 2; fi
OUTDIR=${OUT_DIR:-out}
mkdir -p "$OUTDIR"
WS_PORT=${3:-${REMOTE_DEBUG_PORT:-9222}}
# Use playwright via node if available else use wget as fallback (best-effort)
if command -v node >/dev/null 2>&1 && [ -f /home/azureuser/.openclaw/node_modules/playwright/index.js ]; then
  NODE_PATH=/home/azureuser/.openclaw/node_modules node -e "(async()=>{const {chromium}=require('playwright');const browser=await chromium.connectOverCDP('http://127.0.0.1:$WS_PORT');const contexts=browser.contexts();const context=contexts.length?contexts[0]:await browser.newContext({viewport:{width:1366,height:768}});const page=await context.newPage();await page.goto('$URL',{waitUntil:'networkidle',timeout:60000});await page.waitForTimeout(1000);await page.screenshot({path:'$OUTDIR/devtools_page.png',fullPage:true}).catch(()=>{});require('fs').writeFileSync('$OUTDIR/devtools_page.html',await page.content());require('fs').writeFileSync('$OUTDIR/devtools_cookies.json',JSON.stringify(await context.cookies(),null,2));await browser.close();console.log('saved to $OUTDIR');process.exit(0);})()" || true
else
  echo "Playwright not available; saving via wget as fallback"
  wget -q -O "$OUTDIR/backup.html" --proxy=on --execute="http_proxy=${PROXY_URL:-http://127.0.0.1:3128}" "$URL" || true
fi
