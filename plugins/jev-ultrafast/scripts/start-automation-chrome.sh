#!/usr/bin/env sh
# Start (or reuse) the dedicated automation Chrome that jev-ultrafast drives.
# Keep PORT and PROFILE in sync with BU_CDP_URL in the project .env.
# The anti-throttling flags keep background/occluded windows rendering, which
# Page.captureScreenshot needs (the inspector UI captures screenshots).
set -eu

PORT="${JEV_CHROME_PORT:-9222}"
PROFILE="${JEV_CHROME_PROFILE:-$HOME/.config/browser-harness/chrome-automation}"

# Reuse whatever already listens on PORT. Probe the socket, not /json/version: a
# Chrome started from chrome://inspect's remote-debugging toggle answers 404 on
# every /json/* endpoint, so a curl-only probe reads that as "nothing is
# listening" and this script then launches a second Chrome against an occupied
# port — which is exactly the setup the "reuse" branch exists to avoid.
port_in_use() {
  if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    return 0
  fi
  # -sS without -f: any HTTP answer, a 404 included, proves something is there.
  if command -v curl >/dev/null 2>&1 && curl -sS -o /dev/null --max-time 3 "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

if port_in_use; then
  echo "Port $PORT is already in use — reusing that browser instead of starting another."
  exit 0
fi

case "$(uname -s)" in
  Darwin) CHROME="${JEV_CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}" ;;
  *)      CHROME="${JEV_CHROME:-$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)}" ;;
esac

if [ -z "${CHROME:-}" ] || [ ! -x "$CHROME" ]; then
  echo "ERROR: Chrome not found. Set JEV_CHROME=/path/to/chrome and retry." >&2
  exit 1
fi

mkdir -p "$PROFILE"
"$CHROME" --remote-debugging-port="$PORT" --user-data-dir="$PROFILE" \
  --no-first-run --no-default-browser-check \
  --disable-backgrounding-occluded-windows --disable-renderer-backgrounding \
  --disable-background-timer-throttling --disable-features=CalculateNativeWinOcclusion \
  about:blank >/dev/null 2>&1 &

echo "Started automation Chrome on port $PORT (profile: $PROFILE)."
echo "Set BU_CDP_URL=http://127.0.0.1:$PORT in the project .env, and close that window to stop it."
