#!/usr/bin/env sh
# Prepare a local Jev checkout for the skill. Safe to run repeatedly.
set -eu

REPO_URL="${JEV_ULTRAFAST_REPO:-https://github.com/huhao121/jev-ultrafast.git}"
PROJECT="${JEV_ULTRAFAST_HOME:-$HOME/jev-ultrafast}"

if ! command -v uv >/dev/null 2>&1; then
  echo "ERROR: uv is required. Install it from https://docs.astral.sh/uv/ and retry." >&2
  exit 1
fi
if [ -e "$PROJECT" ] && [ ! -d "$PROJECT/.git" ]; then
  echo "ERROR: $PROJECT exists but is not a Jev git checkout." >&2
  exit 1
fi
if [ ! -d "$PROJECT/.git" ]; then
  mkdir -p "$(dirname "$PROJECT")"
  echo "Cloning Jev Ultrafast into $PROJECT..."
  git clone --depth 1 "$REPO_URL" "$PROJECT"
fi

cd "$PROJECT"

# The skill and the /jev-ultrafast:jev command both run ./scripts/start-automation-chrome.sh from
# the project root, so place this plugin's launcher there. It is a plugin artifact,
# not user config: refreshed on every run so it stays in step with the plugin, and
# left untracked in the checkout.
SCRIPT_DIR=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
mkdir -p scripts
for launcher in start-automation-chrome.sh start-automation-chrome.cmd; do
  if [ -f "$SCRIPT_DIR/$launcher" ]; then
    cp "$SCRIPT_DIR/$launcher" "scripts/$launcher"
    chmod +x "scripts/$launcher" 2>/dev/null || true
  fi
done

echo "Installing Jev dependencies..."
uv sync
if [ ! -e .env ]; then
  cp .env.example .env
  # Point the project at the dedicated automation Chrome this plugin installs and the
  # /jev-ultrafast:jev command starts. With BU_CDP_URL unset, Browser Harness auto-discovers a
  # browser instead — but it only counts the standard Chrome profile directories as "a browser is
  # running", so a user whose only Chrome is the automation one gets "chrome-not-running" before
  # the port probe ever runs. An existing .env is never touched: delete this line to drive your own
  # Chrome profile instead, and set JEV_CHROME_PORT before the first run to change the port.
  printf 'BU_CDP_URL=http://127.0.0.1:%s\n' "${JEV_CHROME_PORT:-9222}" >> .env
fi

# If the caller already exported one OpenRouter key, use it for both providers.
if [ -n "${OPENROUTER_API_KEY:-}" ]; then
  grep -q '^TYPESAFE_API_KEY=.' .env || printf '\nTYPESAFE_API_KEY=%s\n' "$OPENROUTER_API_KEY" >> .env
  grep -q '^TEXT_MODEL_API_KEY=.' .env || printf 'TEXT_MODEL_API_KEY=%s\n' "$OPENROUTER_API_KEY" >> .env
  grep -q '^TYPESAFE_ENDPOINT=.' .env || printf 'TYPESAFE_ENDPOINT=https://openrouter.ai/api/alpha/decisions\nTYPESAFE_MODEL=~typesafe/jev-latest\n' >> .env
fi

missing=""
grep -q '^TYPESAFE_API_KEY=.' .env || missing="$missing TYPESAFE_API_KEY"
grep -q '^TEXT_MODEL_API_KEY=.' .env || missing="$missing TEXT_MODEL_API_KEY"
if [ -n "$missing" ]; then
  echo "Jev is installed, but these values are missing in $PROJECT/.env:$missing" >&2
  echo "Add them locally, then ask the agent to run the task again." >&2
  exit 2
fi
echo "Jev is ready at $PROJECT."
