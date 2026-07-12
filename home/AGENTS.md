# global agent instructions

<!-- v0 — grows one rule at a time, only when a correction proves worth remembering. -->

- Prefer quality, simplicity, robustness, and long-term maintainability over
  development cost. Agents build fast — implementation cost is near zero, so never
  pick the cheap option because it seems quicker to build.
- Bug fixes start by reproducing the bug end-to-end, as close to how a real user
  hits it as possible. Only then fix it.
- Fix broken windows: failing lint, flaky tests, obviously-off UI — get them fixed
  even when unrelated to the current task.
- Spec before code for non-trivial features. Verify (types, lint, tests) before
  declaring anything done.
- Env files: `.env.schema` committed (structure + comments, no values), `.env`
  gitignored. Never `.env.example`.
- Never add agent names as commit co-authors or in commit messages.
