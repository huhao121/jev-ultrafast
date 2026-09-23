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
echo "Installing Jev dependencies..."
uv sync
[ -e .env ] || cp .env.example .env

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
