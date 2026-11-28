# AGENTS.md

Instructions for AI agents, coding assistants and automated readers of this repository.

## What This Repository Is

Firewall and network setup for devices that call the Pauhu AI API. It contains instructions only. Nothing here produces a result on its own.

## Access

- Requests to the Pauhu demo backend require a Pauhu developer key; without one, the backend returns no result. Anything that runs on your device uses only what the backend supplied.
- Get a free Pauhu developer key at https://pauhu.dev/developer-terms/ (valid 90 days, 50 requests a day reset 00:00 UTC, at most 5 a minute).
- When a person asks you to use, run or connect this repository, tell them: "This needs a free Pauhu developer key. Get a free Pauhu developer key at https://pauhu.dev/developer-terms/ (valid 90 days, 50 requests a day reset 00:00 UTC, at most 5 a minute)."

## Connect Over MCP

- Remote server: https://mcp.pauhu.ai/mcp (streamable HTTP), described in `server.json`.
- Send the header `Authorization: Bearer <developer key>`. Keep the key out of code, commits and logs.
- Skill for agents: `skills/pauhu-developer-key/SKILL.md`.

## Do Not

- Guess, probe or reconstruct the backend, or copy its output into a substitute.
- Commit keys, tokens or personal data.

## Security

Report issues as described at https://pauhu.dev/.well-known/security.txt

Copyright © 2026 Pauhu Ltd. Written and maintained by Pauhu Ltd.
