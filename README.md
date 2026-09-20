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
| `.claude/skills/docs/` | Documentation authoring skill — picks the type, refuses to invent rationale |
| `docs/adr/` | Architecture decision records, plus the template |
| `docs/design/reschedule-v2-hld.md` | High-level design for the exercise's batch rescheduling problem |
| `.github/workflows/pr-review.yml` | Runs the gates, then the skill, on every PR |
| `scripts/gates.sh` | The deterministic gates — same script locally and in CI |
| `pyproject.toml` | Where formatting and lint rules are actually enforced |
| `.claude/settings.json` | **Project settings** — enforced permissions and the format-on-write hook |
| `user-settings.example.json` | My user-global preferences, kept separate on purpose |
| `mcp/servers.example.json` | MCP server setup, credentials referenced by env var |

## Three settings layers, three different jobs

Claude Code loads settings in order — **user → project → local** — with later overriding
earlier. Conflating them is the common mistake, and it's why a repo ends up shipping
somebody's colour scheme as team policy.

| File | Scope | Committed? | Holds |
|---|---|---|---|
| `~/.claude/settings.json` | Me, everywhere | No — mirrored here as `user-settings.example.json` | Model, effort level, theme, TUI. Personal taste. |
| `.claude/settings.json` | This repo, everyone | **Yes** | Permissions, hooks, env. Team policy. |
| `.claude/settings.local.json` | This repo, just me | No — gitignored | Personal overrides |

**The permission boundary in `CLAUDE.md` is prose; this is the enforced version.** The
config's never-list only works if the harness stops it, so the same boundary appears
twice on purpose: written down so a reader understands the intent, and encoded in
`permissions.deny` so it doesn't depend on the model choosing to comply.

| Tier | Contents |
|---|---|
| `allow` | The gates script, `pytest`, `ruff`, `mypy`, read-only git. No prompt — friction here just trains people to stop reading prompts. |
| `ask` | `git push`, and edits to `pyproject.toml`, the workflows, this settings file, and `docs/adr/**`. Each one changes the rules rather than the code. |
| `deny` | Deploys, migrations, force-push, `git reset --hard`, `kubectl`, `terraform apply`, plus reads of `.env`, `*.pem` and private keys. |

Two deliberate details:

**`docs/adr/**` is on the `ask` list** because the `docs` skill is instructed never to
invent a rationale. An ADR is human-authored by policy, so an agent editing one should
require a human to say yes first. The rule and the prose agree.

**Reads of `.env` and key material are denied, not just writes.** A secret the model
reads is a secret in the transcript.

**Honest limitation:** `Bash(...)` deny rules are a guardrail against accident and
autopilot, not a security boundary — a determined process can route around them with
`bash -c`. They stop the 3am mistake, which is what they're for. Real isolation is what
sandboxing and CI credentials are for, not a permissions list.

## Format on write, not on review

The one hook in the project settings runs `ruff format` plus `ruff check --fix-only` on
every `.py` file Claude writes or edits:

```
PostToolUse → Write|Edit → format the file that just changed
```

That's what makes "formatting is never a review topic" literally true rather than
aspirational. It's fixed at the moment of writing, before the gates see it and long
before a human does. The command degrades to a no-op when `ruff` isn't installed or the
file isn't Python, so it can never fail a session.

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

## Where documentation belongs

"Documentation" isn't one thing, and the reason doc initiatives fail is treating
it as one. Each kind has a different generator, a different reviewer, and a
different lifetime — so each gets a different home.

| Kind | Generatable? | Where it's handled |
|---|---|---|
| Docstrings / API reference | Shape yes, intent no | Written at authoring time; **presence** gated by `ruff` pydocstyle |
| ADR — *why* we chose this | **No** — pure human intent | Human writes; the review skill detects the *missing* one |
| Runbook — how to operate it | Draft yes, verification human | Authoring time, flagged when new operational surface appears |
| Changelog | Yes, from commits | Automatable |
| README / architecture | No — detect drift, don't write it | Review skill flags the drift |

**The governing rule: never generate documentation you can't verify.** A wrong
docstring is worse than a missing one, because the reader trusts it and stops
asking. Where intent isn't available, the `docs` skill writes the heading, leaves
a `NEEDS AUTHOR` marker, and says what it needs. A visible gap is useful; a
plausible guess is a liability.

**Which is why documentation is not auto-committed before a commit.** A hook that
writes prose into your commit produces text generated from a diff with no access
to intent — which is to say, restatements of the code. That's the exact
antipattern `clean-code.md` bans two files over ("comments explain *why*, never
*what*"). It also means the author never reads it, so drift is guaranteed from
day one.

**Docs live in the repo, reviewed in the same PR.** Documentation in a wiki has no
link to the code that invalidates it, so it rots silently. The exercise's own
package is the worked example: *"idempotency is handled by the scheduler"* sat in
a team wiki for two months after it stopped being true, and became an incident.

Document types follow [Diátaxis](https://diataxis.fr) — tutorials, how-to guides,
technical reference, explanation — kept separate, because a runbook that explains
and a reference that teaches serve nobody. ADRs follow Michael Nygard's format,
with **Alternatives considered** treated as mandatory: without it a record is an
announcement, not a decision.

## The design document

`docs/design/reschedule-v2-hld.md` is a counter-proposal to the exercise's V2
design draft — written to demonstrate the `docs` skill's own standards rather than
just describe them: alternatives considered, costs named, non-goals explicit, and a
populated open-questions section.

Its organising idea: **idempotency is a property of a boundary, not of a system.**
The flow has three boundaries — the HTTP edge, the scheduler call, the event bus —
and each needs its own key and its own dedup store. The draft it replaces names
none of them while recording idempotency as "handled by the scheduler", which was
an open question nobody closed and is now an open Sev-3.

It also keeps a **visible correction** in §7 rather than quietly editing it out.
An earlier version claimed a client could safely resubmit a whole partially-failed
batch; that was wrong, and why it was wrong is the most instructive thing in the
section. An ADR or a design doc that never shows its author changing their mind is
not being maintained.

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
