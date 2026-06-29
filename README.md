# synthetic-desktop-activity

A lightweight PowerShell-based synthetic desktop workload generator for Windows testing environments.

## Purpose

This repository provides an endpoint-only runtime for generating non-PII, non-PHI synthetic user-like activity on Windows 10/11 test machines. It is designed for lab validation, workload simulation, and endpoint behavior testing.

## Disclaimer

This project is intended for test and simulation environments only. It does not perform real user impersonation, access private data, or generate telemetry to a backend service. No PII/PHI is used.

## Architecture Overview

- `scripts/workload.ps1` runs the primary endpoint loop.
- `modules/` contains modular activity stubs for browser, application, file, AI, input, mouse, keyboard, and logging actions.
- `config/` contains JSON-driven behavior definitions.
- `ops/` contains lightweight install/uninstall helpers.

## Folder Structure

- `scripts/` — endpoint runtime and orchestration.
- `modules/` — activity hooks and logic stubs.
- `config/` — JSON config files for profile, applications, websites, AI prompts, and file operations.
- `seeddata/` — future synthetic payload or seed datasets.
- `logs/` — runtime logs.
- `temp/` — local temporary file operations.
- `ops/` — optional setup and cleanup helpers.
- `docs/` — architecture and usage guidance.

## Quick Start

1. Clone the repository:

```powershell
git clone <repo-url> synthetic-desktop-activity
cd synthetic-desktop-activity
```

2. Run the install helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\ops\install.ps1
```

3. Run the workload manually:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\workload.ps1
```

## Configuration

Behavior is driven by JSON files in `config/`:

- `device.json` — device profile, business hours, enabled feature flags, and polling intervals.
- `device.json` also supports keyboard burst tuning with `keyboardBurst.minBursts`, `keyboardBurst.maxBursts`, `keyboardBurst.minPressesPerBurst`, `keyboardBurst.maxPressesPerBurst`, `keyboardBurst.cooldownSecondsMin`, and `keyboardBurst.cooldownSecondsMax`.
- `device.json` also supports an optional `keyboardBurst.app` definition for starting a specific app during the burst cycle.
- `device.json` also supports mouse jiggle tuning with `mouseJiggle.moveMin`, `mouseJiggle.moveMax`, and `mouseJiggle.sleepMilliseconds`.
- Keyboard bursts use navigation-only keys (`Tab`, `Page Up/Down`, `Home`, `End`, and arrow keys).
- `websites.json` — a list of predefined websites to browse.
- `applications.json` — applications to launch with safe defaults.
- `ai-prompts.json` — optional synthetic AI-related prompts.
- `files.json` — file activity definitions scoped to local temp operations.

## Extensibility

This scaffold is modular by design. Add or enhance activity modules in `modules/`, then update `scripts/workload.ps1` to wire new hooks into the runtime loop.

## To-do

- Add hook options for EventLogger
- Add task scheduler and on startup entries for `workload.ps1` automatic runs

## Safety Boundaries

- Not for production telemetry or fleet coordination.
- Not for real user interaction or credential harvesting.
- Not for accessing sensitive or private endpoint data.
- Intended for isolated Windows test endpoints only.
