# jev-ultrafast (plugin)

Drives a real Chrome browser from a single natural-language goal.

[Jev Ultrafast](https://github.com/browser-use/jev-ultrafast) is a browser agent with a dynamic,
indexed action space: per decision cycle TypeSafe's Jev returns an operation
(`CLICK`, `TYPE_TEXT`, `SELECT`, `SCROLL_UP`, `SCROLL_DOWN`, `WAIT`, `DONE`, `BLOCKED`) and an
operation-specific target element, in one request. A small OpenAI-compatible model writes text only
when the operation is `TYPE_TEXT`.

## What this plugin adds

- `skills/jev-ultrafast/` — setup and run guidance for the agent (prerequisites, commands, caveats).
- `commands/jev.md` — `/jev-ultrafast:jev <goal> [starting url]` to run one task.
- `scripts/start-automation-chrome.sh` / `.cmd` — start (or reuse) a dedicated automation Chrome
  with a separate profile, so the agent never needs remote debugging enabled on your daily browser.

## Install

Nothing to clone by hand. Add this repository as a marketplace, install the plugin, and the first
run sets the project up for you.

**Claude Code** — inside a session:

```text
/plugin marketplace add huhao121/jev-ultrafast
/plugin install jev-ultrafast@jev-ultrafast
```

The same two steps from your shell:

```bash
claude plugin marketplace add huhao121/jev-ultrafast
claude plugin install jev-ultrafast@jev-ultrafast
```

Adding the marketplace only registers it; nothing is installed until the second command.

**ZCode**

**Settings → Plugin Management → Discover → `+`**, add `huhao121/jev-ultrafast` (a local checkout
path works too), then install **jev-ultrafast**.

Then restart the session — in Claude Code, `/reload-plugins` applies the change without a restart —
and run the command, giving it a goal and optionally a starting URL:

```text
/jev-ultrafast:jev Find one-way flights from Zurich to London on September 20, 2026
```

The first run clones the project into `~/jev-ultrafast` (override with `JEV_ULTRAFAST_HOME`), runs
`uv sync`, and creates `.env` from `.env.example`. It also points that `.env` at the dedicated
automation Chrome the command starts for you (`BU_CDP_URL=http://127.0.0.1:9222`), so you never have
to enable remote debugging on your own browser. If `OPENROUTER_API_KEY` is already exported it
reuses that key for both providers; otherwise it stops and names the variables still missing, which
you then add to the project's `.env` (see **Keys are never stored here** below).

Working on the plugin itself? `claude plugin marketplace add ./path/to/your/checkout` installs from a
local directory instead. Remove the GitHub marketplace first if you already added it — both
register under the same name, and Claude Code refuses a second source for a name it knows.

## Keys are never stored here

The plugin holds no credentials. `TYPESAFE_API_KEY` and `TEXT_MODEL_API_KEY` live in the
`jev-ultrafast` project's own `.env`, which upstream already gitignores. Do not add keys to this
plugin directory, to `plugin.json`, or to any file that is committed.

## Requirements

- Python ≥ 3.12 and [uv](https://docs.astral.sh/uv/) — the first run installs the project
  dependencies with `uv sync`
- Google Chrome (or Chromium); the project checkout itself is created on the first run
- API credentials: TypeSafe Jev (`https://docs.typesafe.ai`), or an OpenRouter key for both the
  decisions model (`~typesafe/jev-latest` via `/api/alpha/decisions`) and the text model

See the skill for the full command list, browser options, and caveats.
