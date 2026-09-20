# ai-config

AI configuration work for the DMG Engineering Manager exercise.

## Provenance, stated plainly

The configuration I use at work is employer-confidential and isn't shareable, so
per the exercise brief I've used the **Sample CLAUDE.md provided in the package**
as the starting point, and built the improved version from it.

Rather than produce a generic cleanup, I wrote the config I'd actually hand
**Team Aurora** on day one — using the service context from the V2 design
proposal, PR #1842, and the team health snapshot in the same package. The sharp
edges section is drawn entirely from problems visible in those three artifacts.

The fictional service it describes is the exercise's, not a real DMG system.

## Contents

| Path | What it is |
|---|---|
| `CLAUDE.md` | The rewritten configuration, for Aurora's ReschedulingEngine |
| `CRITIQUE.md` | What was wrong with the original and why each change was made |
| `.claude/skills/pr-review/` | Automated first-pass PR review skill |
| `.github/workflows/pr-review.yml` | Runs the gates, then the skill, on every PR |
| `scripts/gates.sh` | The deterministic gates — same script locally and in CI |
| `pyproject.toml` | Where formatting and lint rules are actually enforced |
| `settings.json` | My actual Claude Code settings |
| `mcp/servers.example.json` | MCP server setup, credentials referenced by env var |

## The review pipeline

The piece I'd add as an EM. Three gates, each protecting the next one's
attention:

| | Gate | Owner | Can block merge? |
|---|---|---|---|
| 0 | Format, lint, types, tests, 100% diff coverage | Tools | Yes |
| 1 | SOLID, clean code, test quality, repo sharp edges | `pr-review` skill | No — advisory |
| 2 | Is this the right change? | A human | Yes — sole approver |

**Formatting is a tool's job, not a reviewer's.** A model commenting on style is
nondeterministic and will contradict itself between runs. `ruff format` decides,
`pyproject.toml` is the single source of truth, `scripts/gates.sh` runs the same
checks on a laptop as in CI, and the review skill is explicitly forbidden from
raising anything a formatter owns. That gets one format across the whole team,
which prose in a style guide never does.

**"100% coverage" is scoped to the diff, on purpose.** Every line a PR changes
must be covered. A global 100% target is the most reliably counterproductive
metric in testing — it manufactures tests that execute lines and assert nothing,
and rewards testing getters over testing behaviour. Diff coverage gets the
discipline without the incentive to game it. Overall coverage ratchets upward and
never falls.

**Coverage is a floor; the model judges the ceiling.** A percentage tells you a
line ran. It cannot tell you whether the assertion would fail if the behaviour
broke — so the skill's primary test-quality check is exactly that question.

**The automated reviewer is bounded to 8 findings.** Past that it names the
pattern once rather than enumerating. Thirty comments on a PR isn't a quality
bar, it's a way to make sure none of them get read.

**Nothing automated approves anything.** The skill has no approve capability and
no merge capability, and that's a design decision rather than a limitation.
Automation removes the mechanical load so the human review is spent on judgement:
is this the right change, and what does it cost us in six months.

## The principles behind the rewrite

**Every rule must be falsifiable.** If a reviewer couldn't tell whether the model
followed a line, that line is decoration and it dilutes the ones that work.
"Write clean code" fails this test; "no per-item query inside a loop" passes it.

**Contradiction is worse than omission.** Two rules that can't both be followed
buy unpredictability — the model resolves the conflict differently each run.

**Context beats instruction.** The highest-value section is the one listing sharp
edges and open incidents. Telling a frontier model to be helpful wastes the
budget; telling it that idempotency isn't actually guaranteed despite the design
doc saying so saves an incident.

**Never ask a reviewer to agree with you.** A config that optimises for agreement
throws away the main reason to have a second pair of eyes.

**State the permission boundary explicitly.** Three tiers — run freely, ask
first, never — so "should I ask?" is a lookup rather than an inference.

**No credentials, ever.** MCP headers reference environment variables; Claude
Code's own `~/.claude.json` is gitignored here because inlining a token into it
is the easy mistake.

**A config is maintained like code.** Owner, review date, and explicit update
triggers: the model did something wrong (missing rule), or I retyped the same
context into a prompt (missing section).
