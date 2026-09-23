---
name: jev-ultrafast
description: Drive a real Chrome browser from one natural-language goal using Jev Ultrafast (Browser Use x TypeSafe's Jev "System One" policy). Use when the user asks to run jev / jev-ultrafast, to automate a browser task such as searching flights, filling a form, or clicking through a page with operation+target decisions, or to set up, configure, or debug the jev-ultrafast project.
---

# Jev Ultrafast

A browser agent with a dynamic, indexed action space. Per decision cycle, TypeSafe's Jev returns an
operation and an operation-specific target element in one request; a small OpenAI-compatible model
writes text only when the operation is `TYPE_TEXT`. No screenshots are consumed by the default loop.

Operations: `CLICK`, `TYPE_TEXT`, `SELECT`, `SCROLL_UP`, `SCROLL_DOWN`, `WAIT`, `DONE`, `BLOCKED`.

## First use: automatic setup

Do not stop because the checkout or virtual environment is missing. Run the bundled setup script;
it clones this fork into `$JEV_ULTRAFAST_HOME` (default `~/jev-ultrafast`), runs `uv sync`, creates
`.env` from `.env.example`, and reuses `OPENROUTER_API_KEY` from the current environment when it
is available:

The Codex GitHub skill installer copies only the skill directory, so clone this fork on first use
and invoke the setup helper from the checkout:

```bash
SETUP_DIR="${TMPDIR:-/tmp}/jev-ultrafast-bootstrap"
if [ ! -x "$SETUP_DIR/plugins/jev-ultrafast/scripts/setup.sh" ]; then
  rm -rf "$SETUP_DIR"
  git clone --depth 1 https://github.com/huhao121/jev-ultrafast.git "$SETUP_DIR"
fi
"$SETUP_DIR/plugins/jev-ultrafast/scripts/setup.sh"
```

The script is idempotent and never overwrites an existing `.env`.

Credentials are the only setup input it cannot invent. If they are missing, report the exact local
`.env` path and the missing variable names; never ask the user to paste secrets into chat.

## Prerequisites

1. Python >= 3.12 and [uv](https://docs.astral.sh/uv/) must be on PATH. The setup script installs
   the project dependencies automatically.
2. Credentials in the project's `.env` (upstream `.gitignore` covers it):
   - `TYPESAFE_API_KEY` — the Jev decision model.
   - `TEXT_MODEL_API_KEY` — an OpenAI-compatible text model, used only by `TYPE_TEXT`.

   Report only whether these are set; never echo, log, or commit their values.
3. A browser, see below.

## Serving Jev without a TypeSafe account

The decision endpoint is configurable, so Jev can be served through OpenRouter with one key:

```dotenv
TYPESAFE_API_KEY=<your OpenRouter key>
TYPESAFE_ENDPOINT=https://openrouter.ai/api/alpha/decisions
TYPESAFE_MODEL=~typesafe/jev-latest
```

The request and response shape is identical to TypeSafe's own `/v1/systemone`, so the same policy
code runs on either. Notes: `~typesafe/...` is an organization-scoped model that does not appear in
`/api/v1/models`; the `/api/alpha/` path is an alpha endpoint that can change; a decisions model
cannot be called through `/chat/completions`. To go back to TypeSafe directly, set
`TYPESAFE_ENDPOINT=https://api.typesafe.ai/v1/systemone` and `TYPESAFE_MODEL=jev-latest` with a key
from `https://console.typesafe.ai/settings/keys`.

## Running tasks

```bash
cd "$JEV_ULTRAFAST_HOME"

# browser: start (or reuse) the dedicated automation Chrome — installed by setup.sh, idempotent
# (it exits without starting anything when a browser already listens on the port)
./scripts/start-automation-chrome.sh        # Windows: scripts\start-automation-chrome.cmd

# one-shot CLI task (repeat --goal for an ordered list)
uv run --env-file .env python examples/run.py \
  --url "https://en.wikipedia.org/wiki/Main_Page" \
  --goal "Find and open the article about Godel's incompleteness theorems."

# local inspector UI on http://127.0.0.1:8766 (reads .env from the current directory)
uv run jev

# offline checks: no paid API calls
uv run pytest -q
uv run browser-harness --doctor
```

If the user asks about flights without giving a URL, use
`https://www.google.com/travel/flights?hl=en`.

Library use:

```python
from jev_ultrafast import Agent

with Agent("https://www.google.com/travel/flights?hl=en",
           "Find one-way flights from Zurich to London on September 20, 2026, "
           "for one adult in economy. Stop when matching flight options are visible.") as agent:
    for state in agent.run():
        print(state["elapsed_ms"], state["status"])
```

## Browser options

- **Dedicated automation Chrome (default).** `scripts/start-automation-chrome.*` launches Chrome
  with `--remote-debugging-port` and its own `--user-data-dir`, so nothing is enabled on the user's
  daily profile. `setup.sh` writes `BU_CDP_URL=http://127.0.0.1:9222` into a new `.env` to point the
  project at it, honouring `JEV_CHROME_PORT` if that was set when the `.env` was created.
- **Your own Chrome profile.** Delete the `BU_CDP_URL` line and enable
  `chrome://inspect/#remote-debugging` in Chrome. Only a human can tick that box, and Chrome shows a
  per-connection "Allow remote debugging?" prompt afterwards. With `BU_CDP_URL` unset, Browser
  Harness auto-discovers a browser, but it only treats the standard Chrome profile directories as "a
  browser is running" — a user with no ordinary Chrome open gets `chrome-not-running` even while the
  automation Chrome is up, which is why the dedicated Chrome is the default.

## Caveats

- Real money per run: each decision is one paid request (roughly $0.0002 with Jev on OpenRouter),
  plus a small text-model call per `TYPE_TEXT`. Say so before launching long tasks.
- `DONE` is the model's judgement, not proof of success — verify the requested outcome on the page.
- Never retry a browser mutation; `examples/flights.py` shows the independent-verification pattern.
- Keep `.env` at LF line endings: a CRLF file leaves a trailing `\r` in values.
- In the observed snapshot the element table lives under `actions`, not `elements`.
- The browser harness allows ~5 s per IPC request, so screenshot capture can time out while the
  automation window is occluded; the default agent loop does not use screenshots.
- Outside the MVP: shadow roots, frames, canvas, uploads, pop-up tabs, nested scrolling.
