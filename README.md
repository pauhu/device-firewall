# Pauhu Device Firewall

Firewall and network setup for devices that call the Pauhu AI API.

**Reading this repository is free. Using the Pauhu demo backend needs a free Pauhu developer key.** Get a free Pauhu developer key by signing in with GitHub at https://api.pauhu.ai/v1/dev/github/start (terms: https://pauhu.dev/developer-terms/) (valid 90 days, 50 requests a day reset 00:00 UTC, at most 5 a minute). Requests go to the Pauhu demo backend; without a key it returns no result.

- AI agents: read [AGENTS.md](AGENTS.md).
- MCP clients: [server.json](server.json) (remote, header `Authorization: Bearer <key>`).

Status: proposed. Licence: Apache-2.0.

Copyright © 2026 Pauhu Ltd. Written and maintained by Pauhu Ltd.

## Quickstart

1. Get a free Pauhu developer key by signing in with GitHub at https://api.pauhu.ai/v1/dev/github/start (terms: https://pauhu.dev/developer-terms/)
2. Set it in your own shell: `export PAUHU_DEV_KEY=...` (never commit it).
3. Run one of `bash examples/quickstart.sh`, `node examples/quickstart.mjs` or `python3 examples/quickstart.py`. Each lists the tools the backend offers you.
4. Connect your AI coding tool with [examples/mcp-config.json](examples/mcp-config.json) or [server.json](server.json).

Without a key the examples stop with a message and the backend returns no answers.

## The Pauhu Menu

Every Pauhu repository, in one place. Each one has the same quickstart and works with the same developer key.

| Repository | What it is | What it does |
| --- | --- | --- |
| [ai-assistant](https://github.com/pauhu/ai-assistant) | Pauhu Client | Ask Pauhu sourced questions from your terminal. |
| [data-provenance](https://github.com/pauhu/data-provenance) | Pauhu Measurement Provenance | Client for reading a local measurement record with its origin; checks come from the Pauhu demo backend. |
| [edge-ai](https://github.com/pauhu/edge-ai) | Pauhu Edge AI | Pauhu senses (reading, hearing, speaking, seeing) on your own device; the model pack is served by the Pauhu demo backend. |
| [llm-benchmark](https://github.com/pauhu/llm-benchmark) | Pauhu Bench | Client for Pauhu small-model benchmarks served by the Pauhu demo backend. |
| [llm-security](https://github.com/pauhu/llm-security) (this one) | Pauhu Device Firewall | Firewall and network setup for devices that call the Pauhu AI API. |
| [local-ai](https://github.com/pauhu/local-ai) | Pauhu Folder Assistant | Client for running a Pauhu plan over a folder you granted; the plan comes from the Pauhu demo backend. |
| [mcp-server](https://github.com/pauhu/mcp-server) | Pauhu MCP Server | Connect your AI assistant to Pauhu over MCP. |
| [pauhu-linux](https://github.com/pauhu/pauhu-linux) | Pauhu Linux Client | Pauhu command line for Linux. |
| [post-quantum-cryptography](https://github.com/pauhu/post-quantum-cryptography) | Pauhu Post-Quantum Cryptography | Proposed: post-quantum key encapsulation and signatures through an open library. |
| [systems-at-origin](https://github.com/pauhu/systems-at-origin) | Pauhu Database Client | Client for reading records from a granted local database without modifying it; plans and receipts come from the Pauhu demo backend. |
| [tool-calling](https://github.com/pauhu/tool-calling) | Pauhu Tool Calling | Tool calling for AI models: your model calls tools that run on your device, following tool plans from the Pauhu demo backend. |
| [web-search](https://github.com/pauhu/web-search) | Pauhu Web Search | Web answers that cite the page they came from, with its version date where the publisher gives one and the retrieval time. |

**Developer key:** free, sign in with GitHub at https://api.pauhu.ai/v1/dev/github/start. Valid 90 days, 50 requests a day (reset 00:00 UTC), at most 5 a minute. Reading any repository is free; answers from the Pauhu demo backend need the key.
