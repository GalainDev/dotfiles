#!/bin/bash
# SessionStart hook: give this Claude session its own Runes actor and print
# `rune prime` (in progress / ready / waiting on people) into its context.
#
# Contract: never fail or stall session start. No `set -e`; every path exits 0.
#  - actor: appended to $CLAUDE_ENV_FILE (SessionStart-only mechanism, see
#    https://code.claude.com/docs/en/hooks) so later Bash commands see it.
#  - output: cached 60 s; `rune prime` is killed after 2 s (settings.json
#    sets the hook's own 3 s timeout as the outer bound).

export PATH="$HOME/go/bin:$PATH"   # rune lives in ~/go/bin; hooks get no shell rc

input=$(cat 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
sid=${sid//[^A-Za-z0-9]/}

actor=""
if [ -n "$sid" ]; then
  actor="claude-${sid:0:8}"
  if [ -n "$CLAUDE_ENV_FILE" ]; then
    printf 'export RUNES_ACTOR=%s\n' "$actor" >>"$CLAUDE_ENV_FILE" 2>/dev/null
  fi
fi

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-runes"
cache="$cache_dir/prime.md"

fresh() { [ -s "$cache" ] && [ -n "$(find "$cache" -mmin -1 2>/dev/null)" ]; }

prime=""
if fresh; then
  prime=$(cat "$cache" 2>/dev/null)
else
  rm -f "$cache" 2>/dev/null          # never serve output older than 60 s
  tmp=$(mktemp "${TMPDIR:-/tmp}/rune-prime.XXXXXX" 2>/dev/null)
  if [ -n "$tmp" ]; then
    rune prime >"$tmp" 2>/dev/null &
    pid=$!
    ( sleep 2; kill "$pid" 2>/dev/null ) >/dev/null 2>&1 &
    watchdog=$!
    wait "$pid" 2>/dev/null
    rc=$?
    { kill "$watchdog" && wait "$watchdog"; } 2>/dev/null   # reap quietly: no "Terminated" noise
    if [ "$rc" -eq 0 ] && [ -s "$tmp" ]; then
      prime=$(cat "$tmp" 2>/dev/null)
      # best effort: the cache only saves time, output never depends on it
      mkdir -p "$cache_dir" 2>/dev/null && cp "$tmp" "$cache.$$" 2>/dev/null \
        && mv -f "$cache.$$" "$cache" 2>/dev/null
    fi
    rm -f "$tmp" "$cache.$$" 2>/dev/null
  fi
fi

[ -n "$prime" ] && printf '%s\n' "$prime"
if [ -n "$actor" ]; then
  printf 'Your Runes actor for this session: %s (exported as RUNES_ACTOR; if unset, pass --actor %s on every write).\n' "$actor" "$actor"
fi
exit 0
