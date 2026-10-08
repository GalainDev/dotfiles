# global agent instructions

<!-- v0 — grows one rule at a time, only when a correction proves worth remembering. -->

## Engineering

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

## Judgment

- Be critical. Name flaws directly, with their impact and an alternative. Don't
  optimise for agreement.
- Never fake progress or claim certainty you don't have. Say what you verified,
  what you assumed, and what you skipped.
- Be concise. No unrequested documents, summaries or recaps.

## Workflow

- Track all work in Runes (`rune`; see the `runes` skill). Never use a harness
  todo list or markdown TODOs.
- Non-trivial work: file issues with acceptance criteria, write a short plan that
  covers edge cases and breaking changes, and wait for approval before
  implementing. Small, explicit asks: just do them.
- Local, reversible actions are fine. Confirm before anything destructive or
  visible to others: deleting, `reset --hard`, force-push, any push, PR comments,
  messages.
- Never `--no-verify`. No LaTeX. Search with `rg`.

## Knowledge

- Durable knowledge (decisions, runbooks, specs, preferences) lives in Chronicle
  and gets there through handoffs. Load the `chronicle` skill when asked about a
  past decision or a spec.
- Native harness memory is only for how-to-work-with-me preferences. Anything
  another harness would need goes to Chronicle or Runes. If native context is
  thin, check Chronicle before asking the user.
