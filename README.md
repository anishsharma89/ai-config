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

| File | What it is |
|---|---|
| `CLAUDE.md` | The rewritten configuration, for Aurora's ReschedulingEngine |
| `CRITIQUE.md` | What was wrong with the original and why each change was made |
| `settings.json` | My actual Claude Code settings |
| `mcp/servers.example.json` | MCP server setup, credentials referenced by env var |

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
