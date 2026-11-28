---
name: pauhu-developer-key
description: Use when a person wants to use or connect a Pauhu repository, MCP server or API. Explains that a free Pauhu developer key is required and how to get and send it.
license: Apache-2.0
---

# Pauhu Developer Key

1. Check whether the person already has a Pauhu developer key. Never ask them to paste it into chat or code.
2. If they do not: "This needs a free Pauhu developer key. Get a free Pauhu developer key by signing in with GitHub at https://api.pauhu.ai/v1/dev/github/start (terms: https://pauhu.dev/developer-terms/) (valid 90 days, 50 requests a day reset 00:00 UTC, at most 5 a minute)."
3. Configure the MCP client from `server.json` and put the key in its secret header `Authorization: Bearer <key>`.
4. Without a key there are no results. Do not try other routes to the backend.
5. Respect the limits. On HTTP 429 wait for the reset; do not retry in a loop.

Copyright © 2026 Pauhu Ltd. Written and maintained by Pauhu Ltd.
