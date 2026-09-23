---
description: Run one Jev Ultrafast browser task from a natural-language goal against the local automation Chrome
argument-hint: <goal> [starting url]
---

Run the [jev-ultrafast](https://github.com/huhao121/jev-ultrafast) browser agent for this goal:

> $ARGUMENTS

Steps:

1. Prepare the project automatically. Run `${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh` — the plugin's
   own copy of the setup script (in a harness that leaves that placeholder unsubstituted, find the
   installed `jev-ultrafast` plugin folder instead). If it is not there, clone
   `https://github.com/huhao121/jev-ultrafast.git` to `${JEV_ULTRAFAST_HOME:-$HOME/jev-ultrafast}`
   and run `plugins/jev-ultrafast/scripts/setup.sh` from that clone. The script is idempotent and
   installs the launcher below into the project. Do not stop merely because the project is absent.
   Report only whether credentials are set, never their contents.
2. Start the browser (idempotent): `./scripts/start-automation-chrome.sh` (or `.cmd` on Windows)
   from the project directory — step 1 puts it there. Always run it: it exits without starting
   anything when a browser already listens on the port, so it is safe when the user's own Chrome
   has remote debugging on. Do not skip it because the project `.env` sets `BU_CDP_URL` — a fresh
   `.env` points at this port on purpose, and nothing listens there until this script has run once.
3. Run the task from the project directory:

   ```bash
   uv run --env-file .env python examples/run.py --url "<starting url>" --goal "<goal>"
   ```

   For a flight request without a URL, use `https://www.google.com/travel/flights?hl=en`.

4. Report what the run printed (final URL, elapsed time, step count). State plainly that `DONE` is
   the model's judgement, not proof: verify the requested outcome on the page before claiming the
   task succeeded.

Never ask the user to paste a key into the chat, never echo a key, and never write one outside the
project's gitignored `.env`.
