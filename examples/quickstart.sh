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
LAST=$(printf '%s\n' "$OUT" | sed -n 's/^data: *//p' | tail -n 1); [ -n "$LAST" ] || LAST=$OUT
case "$LAST" in '{"jsonrpc":"2.0","error"'*|'{"error"'*) exit 1;; esac
