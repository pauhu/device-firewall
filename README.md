# Pauhu Device Firewall

Firewall and network setup for devices that call the Pauhu AI API.

**Reading this repository is free. Using the Pauhu demo backend needs a free Pauhu developer key.** Get a free Pauhu developer key at https://pauhu.dev/developer-terms/ (valid 90 days, 50 requests a day reset 00:00 UTC, at most 5 a minute). Requests go to the Pauhu demo backend; without a key it returns no result.

- AI agents: read [AGENTS.md](AGENTS.md).
- MCP clients: [server.json](server.json) (remote, header `Authorization: Bearer <key>`).

Status: proposed. Licence: Apache-2.0.

Copyright © 2026 Pauhu Ltd. Written and maintained by Pauhu Ltd.

## Quickstart

1. Get a free Pauhu developer key at https://pauhu.dev/developer-terms/
2. Set it in your own shell: `export PAUHU_DEV_KEY=...` (never commit it).
3. Run one of `bash examples/quickstart.sh`, `node examples/quickstart.mjs` or `python3 examples/quickstart.py`. Each lists the tools the backend offers you.
4. Connect your AI coding tool with [examples/mcp-config.json](examples/mcp-config.json) or [server.json](server.json).

Without a key the examples stop with a message and the backend returns no answers.
