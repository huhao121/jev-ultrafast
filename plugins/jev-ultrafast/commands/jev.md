---
description: Run one Jev Ultrafast browser task from a natural-language goal against the local automation Chrome
argument-hint: <goal> [starting url]
---

Run the [jev-ultrafast](https://github.com/huhao121/jev-ultrafast) browser agent for this goal:

> $ARGUMENTS

Steps:

1. Prepare the project automatically. If `$JEV_ULTRAFAST_HOME/plugins/jev-ultrafast/scripts/setup.sh`
   exists, run it. Otherwise clone `https://github.com/huhao121/jev-ultrafast.git` to
   `${JEV_ULTRAFAST_HOME:-$HOME/jev-ultrafast}` and run its setup script. Do not stop merely because
   the project is absent. Report only whether credentials are set, never their contents.
2. Start the browser (idempotent): `./scripts/start-automation-chrome.sh` (or `.cmd` on Windows).
   Skip this if the project `.env` sets `BU_CDP_URL` to a browser the user already runs.
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
