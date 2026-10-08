#!/bin/bash
# PreToolUse hook (matcher: Bash). Asks before commands that are hard to undo:
#   - git push with --force / -f / --force-with-lease / +refspec
#   - database migrations (knex, prisma, rails, alembic, django, *.up.sql via a SQL client)
# Everything else: exit 0 with no output (no opinion, normal permission flow).
# Output shape: https://code.claude.com/docs/en/hooks (PreToolUse decision control).
#
# Leans toward a needless "ask" over a missed one: it matches `git push` anywhere in a
# command segment (so `bash -c 'git push -f'` is caught) and fails visible, not silent,
# when it cannot read its input. It cannot see through `npm run <script>` indirection.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"guard-bash: jq not found, cannot inspect this command"}}'
  exit 0
fi

ask() {
  jq -n --arg r "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
  exit 0
}

input=$(cat)
[ -z "$input" ] && exit 0
tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null) || ask "guard-bash: could not parse hook input"
[ "$tool" = "Bash" ] || exit 0
cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null) || ask "guard-bash: could not parse hook input"
[ -n "$cmd" ] || exit 0

reasons=()

# --- git push --force -------------------------------------------------------
push_re='(^|[^[:alnum:]_./-])git([[:space:]]+(-C|-c|--git-dir|--work-tree|--namespace)[=[:space:]]+[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)'
force_re='(^|[[:space:]])(-[A-Za-z]*f[A-Za-z]*|--force|--force-with-lease(=[^[:space:]]*)?|--force-if-includes|\+[^[:space:]]+)([[:space:]]|$)'

# Segments: split on ; | & ( ) and backtick so chained and nested commands are each inspected.
segments=$(printf '%s' "$cmd" | tr ';|&()`' '\n\n\n\n\n\n')
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  if [[ $seg =~ $push_re ]]; then
    rest="${seg#*"${BASH_REMATCH[0]}"}"
    if [[ $rest =~ $force_re ]]; then
      reasons+=("git push with a force option (--force, -f, --force-with-lease or +refspec) rewrites remote history. Confirm the remote, the branch, and that nobody else depends on it.")
      break
    fi
  fi
done <<<"$segments"

# --- database migrations ----------------------------------------------------
# "label|ERE". Each ERE is tested against the whole command.
migrations=(
  'knex migrate|(^|[^[:alnum:]_-])knex[[:space:]]+migrate:(latest|rollback|up|down)([[:space:]]|$)'
  'prisma migrate|(^|[^[:alnum:]_-])prisma[[:space:]]+migrate[[:space:]]+(dev|deploy|reset|resolve)([[:space:]]|$)'
  'prisma db push|(^|[^[:alnum:]_-])prisma[[:space:]]+db[[:space:]]+push([[:space:]]|$)'
  'rails db:migrate|(^|[^[:alnum:]_-])(rails|rake)[[:space:]]+db:(migrate(:(up|down|redo|reset))?|rollback)([[:space:]]|$)'
  'alembic|(^|[^[:alnum:]_-])alembic([[:space:]]+[^[:space:]]+)*[[:space:]]+(upgrade|downgrade|stamp)([[:space:]]|$)'
  'manage.py migrate|manage\.py[[:space:]]+migrate([[:space:]]|$)'
)
for entry in "${migrations[@]}"; do
  label=${entry%%|*}
  re=${entry#*|}
  if [[ $cmd =~ $re ]]; then
    reasons+=("This looks like a database migration ($label). It changes schema or data; confirm the target database and environment.")
  fi
done

sql_client_re='(^|[^[:alnum:]_-])(psql|mysql|mariadb|sqlite3|sqlcmd|duckdb)([[:space:]]|$)'
if [[ $cmd == *.up.sql* && $cmd =~ $sql_client_re ]]; then
  reasons+=("This runs a *.up.sql migration file through a SQL client. Confirm the target database and environment.")
fi

if [ "${#reasons[@]}" -gt 0 ]; then
  joined=$(printf '%s ' "${reasons[@]}")
  ask "${joined% }"
fi
exit 0
