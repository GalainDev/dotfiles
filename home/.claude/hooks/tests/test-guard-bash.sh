#!/bin/bash
# Tests for ../guard-bash.sh. Run: bash test-guard-bash.sh
# Feeds sample PreToolUse JSON on stdin and checks for "ask" (valid JSON shape) or silence.

hook="$(cd "$(dirname "$0")/.." && pwd)/guard-bash.sh"
pass=0
fail=0

report() { # ok(0/1) description detail
  if [ "$1" -eq 0 ]; then pass=$((pass + 1)); echo "ok   $2"; else fail=$((fail + 1)); echo "FAIL $2 $3"; fi
}

bash_json() { jq -n --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}, hook_event_name: "PreToolUse"}'; }

expect_ask() { # command
  local out rc
  out=$(bash_json "$1" | bash "$hook"); rc=$?
  if [ $rc -eq 0 ] && jq -e '.hookSpecificOutput
      | .hookEventName == "PreToolUse" and .permissionDecision == "ask"
        and (.permissionDecisionReason | length > 0)' <<<"$out" >/dev/null 2>&1; then
    report 0 "ask    $1"
  else
    report 1 "ask    $1" "(rc=$rc out=[$out])"
  fi
}

expect_silent() { # command
  local out rc
  out=$(bash_json "$1" | bash "$hook"); rc=$?
  if [ $rc -eq 0 ] && [ -z "$out" ]; then report 0 "silent $1"; else report 1 "silent $1" "(rc=$rc out=[$out])"; fi
}

# --- force pushes -> ask ------------------------------------------------------
expect_ask 'git push --force'
expect_ask 'git push -f origin main'
expect_ask 'git push origin main --force-with-lease'
expect_ask 'git push --force-with-lease=main:abc123 origin main'
expect_ask 'git push origin main --force-if-includes --force-with-lease'
expect_ask 'git -C ~/developer/AI push -f'
expect_ask 'git push -fu origin main'
expect_ask 'git push origin +main'
expect_ask 'git push origin +HEAD:main'
expect_ask 'cd repo && git push --force'
expect_ask 'echo done; git push -f origin main'
expect_ask 'git fetch && git push origin main -f'
expect_ask "bash -c 'git push -f origin main'"
expect_ask 'GIT_SSH_COMMAND=ssh git push --force'
expect_ask 'git push --force && echo ok'
# Known, accepted false positive: quoted text is not parsed out, because stripping quotes
# would also hide `bash -c 'git push -f'`. A needless prompt beats a missed force-push.
expect_ask 'git commit -m "document git push --force policy"'

# --- ordinary pushes and other git -> silent -----------------------------------
expect_silent 'git push'
expect_silent 'git push origin main'
expect_silent 'git push -u origin feature-fix'
expect_silent 'git push --set-upstream origin main'
expect_silent 'git push --follow-tags'
expect_silent 'git push origin HEAD:refs/heads/foo-fix'
expect_silent 'git -C ~/developer/AI push origin main'
expect_silent 'git stash push -m wip'
expect_silent 'git fetch --force origin'
expect_silent 'git status'
expect_silent 'git log --oneline -5'
expect_silent 'git diff --stat'

# --- migrations -> ask ----------------------------------------------------------
expect_ask 'knex migrate:latest'
expect_ask 'npx knex migrate:rollback'
expect_ask 'pnpm exec knex migrate:up --env production'
expect_ask 'npx prisma migrate deploy'
expect_ask 'prisma migrate dev --name init'
expect_ask 'yarn prisma migrate reset'
expect_ask 'npx prisma db push'
expect_ask 'bundle exec rails db:migrate'
expect_ask 'bin/rails db:rollback'
expect_ask 'rake db:migrate:redo'
expect_ask 'alembic upgrade head'
expect_ask 'alembic -c alembic.ini downgrade -1'
expect_ask 'python manage.py migrate'
expect_ask 'python3 manage.py migrate app 0001'
expect_ask 'psql "$DATABASE_URL" -f db/migrations/001_init.up.sql'
expect_ask 'cat db/migrations/001_init.up.sql | psql "$DATABASE_URL"'
expect_ask 'mysql app < migrations/002_users.up.sql'
expect_ask 'cd api && npx knex migrate:latest'

# --- read-only / file-creating migration tooling -> silent ---------------------
expect_silent 'npx knex migrate:make add_users'
expect_silent 'npx knex migrate:list'
expect_silent 'npx prisma migrate status'
expect_silent 'npx prisma migrate diff --from-empty --to-schema-datamodel schema.prisma'
expect_silent 'bundle exec rails db:migrate:status'
expect_silent 'python manage.py makemigrations'
expect_silent 'python manage.py showmigrations'
expect_silent 'alembic revision --autogenerate -m add_users'
expect_silent 'alembic current'
expect_silent 'cat db/migrations/001_init.up.sql'
expect_silent 'git add db/migrations/001_init.up.sql'
expect_silent 'psql "$DATABASE_URL" -c "select 1"'
expect_silent 'ls -la'
expect_silent 'rm -rf node_modules'
expect_silent 'npm test'

# --- non-Bash tools, empty input, malformed input -------------------------------
out=$(jq -n '{tool_name: "Read", tool_input: {file_path: "/etc/hosts"}}' | bash "$hook"); rc=$?
report "$([ $rc -eq 0 ] && [ -z "$out" ]; echo $?)" "silent non-Bash tool (rc=$rc)"

out=$(jq -n '{tool_name: "Write", tool_input: {command: "git push -f"}}' | bash "$hook"); rc=$?
report "$([ $rc -eq 0 ] && [ -z "$out" ]; echo $?)" "silent non-Bash tool even if it carries a 'command' field"

out=$(jq -n '{tool_name: "Bash", tool_input: {}}' | bash "$hook"); rc=$?
report "$([ $rc -eq 0 ] && [ -z "$out" ]; echo $?)" "silent Bash call with no command"

out=$(bash "$hook" </dev/null); rc=$?
report "$([ $rc -eq 0 ] && [ -z "$out" ]; echo $?)" "silent on empty stdin"

out=$(echo 'this is not json' | bash "$hook"); rc=$?
report "$([ $rc -eq 0 ] && jq -e '.hookSpecificOutput.permissionDecision == "ask"' <<<"$out" >/dev/null 2>&1; echo $?)" "ask on unparseable input (fails visible, rc=$rc)"

# --- every path exits 0 ----------------------------------------------------------
bash_json 'git push -f' | bash "$hook" >/dev/null; report $? "exit 0 on ask"
bash_json 'git status' | bash "$hook" >/dev/null; report $? "exit 0 on silent"

echo "---- $pass passed, $fail failed"
[ "$fail" -eq 0 ]
