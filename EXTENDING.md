# Extending This Repository

Copyright © 2026 Pauhu Ltd. Licensed under the Apache License, Version 2.0.

This repository is a base pack. Fork it and build your own expansion pack on top.

## What A Fork Keeps

When you redistribute a fork, the Apache License 2.0 (section 4) requires you to:

- include a copy of the `LICENSE` file;
- keep the copyright, patent, trademark and attribution notices from the source, including the copyright line at the top of each source file;
- add a prominent notice to each file you changed, saying that you changed it;
- include the attribution notices from the `NOTICE` file. You may add your own notices to it.

We also ask, as a courtesy, that your README says what your fork changes.

## What An Expansion Pack Adds

- Your own tools, prompts, data and workflows, in your own folders.
- Your own client code that calls the Pauhu backend over MCP with your own developer key.
- Your own tests. Run the examples in `examples/` first to check your key and connection.

## What Stays On The Server

Answers are made on the Pauhu backend. This repository holds only the client side: it sends a question and shows the reply. A fork cannot change how answers are made, and it does not need to.

## Keys

Each developer uses their own key, from signing in with GitHub at https://api.pauhu.ai/v1/dev/github/start. Never commit a key; keep it in an environment variable. Terms: https://pauhu.dev/developer-terms/

## Names

Name your fork after what it does. Do not present it as an official Pauhu repository.
