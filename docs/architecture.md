# Architecture Overview

This repository uses a simple endpoint-only runtime model:

- `scripts/workload.ps1` is the main loop.
- Activity decisions are based on JSON config files in `config/`.
- Modular hooks in `modules/` allow safe expansion for browser, application, file, AI, mouse, keyboard, idle, and logging behavior.
- The endpoint runs locally and does not rely on centralized control or telemetry.

## Runtime Flow

1. Load configuration files.
2. Initialize the local logger.
3. Evaluate business hours.
4. Choose a synthetic activity type.
5. Execute the stubbed activity module.
6. Wait a randomized interval before the next cycle.
