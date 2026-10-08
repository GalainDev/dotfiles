#!/bin/bash
# Tests for ../session-start.sh. Run: bash test-session-start.sh
# Uses a throwaway HOME with a fake `rune`, so it never touches the real tracker.

hook="$(cd "$(dirname "$0")/.." && pwd)/session-start.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/session-start-test.XXXXXX") || exit 1
trap 'rm -rf "$work"' EXIT
pass=0
fail=0

check() { # description, condition-exit-code
  if [ "$2" -eq 0 ]; then pass=$((pass + 1)); echo "ok   $1"; else fail=$((fail + 1)); echo "FAIL $1"; fi
}

fake_rune() { # body of the fake rune script; empty argument removes it
  mkdir -p "$work/home/go/bin"
  rm -f "$work/home/go/bin/rune"
  if [ -n "$1" ]; then
    printf '#!/bin/bash\necho x >>"%s/calls"\n%s\n' "$work" "$1" >"$work/home/go/bin/rune"
    chmod +x "$work/home/go/bin/rune"
  fi
}

run_hook() { # json on stdin -> stdout in $out, exit code in $rc
  out=$(HOME="$work/home" CLAUDE_ENV_FILE="$work/env" XDG_CACHE_HOME="$work/cache" bash "$hook" 2>"$work/err")
  rc=$?
}

reset() { rm -rf "$work/cache" "$work/env" "$work/calls"; : >"$work/calls"; : >"$work/env"; }
calls() { wc -l <"$work/calls" | tr -d ' '; }

SID1='{"session_id":"abcdef12-3456-7890-abcd-ef1234567890","hook_event_name":"SessionStart","source":"startup"}'
SID2='{"session_id":"99999999-aaaa-bbbb-cccc-dddddddddddd","hook_event_name":"SessionStart","source":"resume"}'

# 1. normal: prints prime, exports actor
reset; fake_rune 'printf "# Runes\n## In progress\n- rn-1 P1 thing\n"'
run_hook <<<"$SID1"
check "exit 0" "$rc"
check "silent on stderr (no job-control noise)" "$([ ! -s "$work/err" ]; echo $?)"
check "prints rune prime" "$([[ $out == *"- rn-1 P1 thing"* ]]; echo $?)"
check "mentions its actor" "$([[ $out == *"claude-abcdef12"* ]]; echo $?)"
check "exports RUNES_ACTOR to CLAUDE_ENV_FILE" "$(grep -qx 'export RUNES_ACTOR=claude-abcdef12' "$work/env"; echo $?)"

# 2. cached for 60 s: second call doesn't run rune again
run_hook <<<"$SID1"
check "second call served from cache (1 rune call)" "$([ "$(calls)" = 1 ]; echo $?)"

# 3. another session gets a distinct actor
run_hook <<<"$SID2"
check "second session gets its own actor" "$(grep -qx 'export RUNES_ACTOR=claude-99999999' "$work/env"; echo $?)"
check "two sessions -> two distinct actors" "$([ "$(sort -u "$work/env" | wc -l | tr -d ' ')" = 2 ]; echo $?)"

# 4. stale cache is refreshed
touch -t 200001010000 "$work/cache/claude-runes/prime.md"
run_hook <<<"$SID1"
check "stale cache triggers a new rune call (2 calls)" "$([ "$(calls)" = 2 ]; echo $?)"

# 5. rune hangs: bounded, exit 0, no prime text, actor line still printed
reset; fake_rune 'exec sleep 30'
now_ms() { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }   # $SECONDS is whole-second only
start=$(now_ms)
run_hook <<<"$SID1"
elapsed=$(($(now_ms) - start))
check "hanging rune: exit 0" "$rc"
check "hanging rune: returns before the 3 s hook timeout (took ${elapsed} ms)" "$([ "$elapsed" -lt 2800 ]; echo $?)"
check "hanging rune: still prints actor line" "$([[ $out == *"claude-abcdef12"* ]]; echo $?)"

# 6. rune fails with partial output: nothing stale or partial is shown
reset; fake_rune 'echo partial; exit 1'
run_hook <<<"$SID1"
check "failing rune: exit 0" "$rc"
check "failing rune: no partial output" "$([[ $out != *partial* ]]; echo $?)"

# 7. rune missing entirely
reset; fake_rune ''
run_hook <<<"$SID1"
check "missing rune: exit 0" "$rc"
check "missing rune: still exports actor" "$(grep -qx 'export RUNES_ACTOR=claude-abcdef12' "$work/env"; echo $?)"

# 8. garbage / empty stdin: exit 0, no actor, nothing exported
reset; fake_rune 'echo "# Runes"'
run_hook <<<"not json"
check "garbage stdin: exit 0" "$rc"
check "garbage stdin: no actor exported" "$([ ! -s "$work/env" ]; echo $?)"
reset
run_hook </dev/null
check "empty stdin: exit 0" "$rc"

# 9. CLAUDE_ENV_FILE unset
reset
out=$(HOME="$work/home" XDG_CACHE_HOME="$work/cache" env -u CLAUDE_ENV_FILE bash "$hook" <<<"$SID1")
check "no CLAUDE_ENV_FILE: exit 0" "$?"

# 10. unwritable cache dir
reset; fake_rune 'echo "# Runes"'
out=$(HOME="$work/home" CLAUDE_ENV_FILE="$work/env" XDG_CACHE_HOME=/dev/null/nope bash "$hook" <<<"$SID1")
check "unwritable cache dir: exit 0" "$?"
check "unwritable cache dir: still prints prime" "$([[ $out == *"# Runes"* ]]; echo $?)"

echo "---- $pass passed, $fail failed"
[ "$fail" -eq 0 ]
