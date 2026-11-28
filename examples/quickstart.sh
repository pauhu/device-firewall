#!/usr/bin/env bash
# Pauhu quickstart: lists the tools the Pauhu demo backend offers you. Needs PAUHU_DEV_KEY.
set -euo pipefail
if [ -z "${PAUHU_DEV_KEY:-}" ]; then echo "Set PAUHU_DEV_KEY first. Get a free Pauhu developer key by signing in with GitHub at https://api.pauhu.ai/v1/dev/github/start (terms: https://pauhu.dev/developer-terms/)"; exit 2; fi
U=https://mcp.pauhu.ai/mcp; H=(-H "Authorization: Bearer $PAUHU_DEV_KEY" -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream')
S=$(curl -sS -D - -o /dev/null "${H[@]}" "$U" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"pauhu-quickstart","version":"0.1.0"}}}' | tr -d '\r' | sed -n 's/^[Mm]cp-[Ss]ession-[Ii]d: //p')
curl -sS "${H[@]}" ${S:+-H "Mcp-Session-Id: $S"} "$U" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' >/dev/null
curl -sS "${H[@]}" ${S:+-H "Mcp-Session-Id: $S"} "$U" -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'; echo
