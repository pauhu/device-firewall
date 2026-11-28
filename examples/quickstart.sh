#!/usr/bin/env bash
# Pauhu quickstart: lists the tools the Pauhu demo backend offers you. Needs PAUHU_DEV_KEY.
set -euo pipefail
if [ -z "${PAUHU_DEV_KEY:-}" ]; then echo "Set PAUHU_DEV_KEY first. Get a free Pauhu developer key by signing in with GitHub at https://api.pauhu.ai/v1/dev/github/start (terms: https://pauhu.dev/developer-terms/)"; exit 2; fi
U=https://mcp.pauhu.ai/mcp
H=(-sS --fail-with-body -H "Authorization: Bearer $PAUHU_DEV_KEY" -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream')
S=$(curl "${H[@]}" -D - -o /dev/null "$U" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"pauhu-quickstart","version":"0.1.0"}}}' | tr -d '\r' | sed -n 's/^[Mm]cp-[Ss]ession-[Ii]d: //p')
SH=()
if [ -n "$S" ]; then
  [[ "$S" =~ ^[[:graph:]]{1,256}$ ]] || { echo "Unexpected session id from the server; stopping."; exit 1; }
  SH=(-H "Mcp-Session-Id: $S")
fi
curl "${H[@]}" "${SH[@]}" "$U" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' >/dev/null
OUT=$(curl "${H[@]}" "${SH[@]}" "$U" -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}')
printf '%s\n' "$OUT"
# Check the reply structurally when Python 3 is available (it reads JSON and server-sent events properly).
if command -v python3 >/dev/null 2>&1; then
  printf '%s' "$OUT" | python3 -I -c '
import json, sys
t = sys.stdin.read().replace("\r", "")
evs = ["\n".join(l[5:].lstrip(" ") for l in e.split("\n") if l.startswith("data:")) for e in t.split("\n\n")] if "data:" in t else [t]
for m in filter(None, (e.strip() for e in evs)):
    msg = json.loads(m)
    for x in msg if isinstance(msg, list) else [msg]:
        if isinstance(x, dict) and x.get("error"): sys.exit(1)
' || { echo "The backend returned an error." >&2; exit 1; }
fi
