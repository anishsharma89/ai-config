# CLAUDE.md — ReschedulingEngine (Team Aurora)

## What this service is

ReschedulingEngine handles customer-initiated rescheduling of jobs. It sits on
DMG's **Zero Touch critical path**: a ticket should complete its whole lifecycle
without a human touching it, and this service is one of the stages that has to
hold for that to be true.

**Blast radius when you get it wrong:** a bad reschedule sends a provider to the
wrong place at the wrong time. That is a missed customer SLA, a wasted truck
roll, and a billing dispute — not a stack trace someone notices in a dashboard.
Treat every change here as customer-facing.

## Commands

```
pytest tests/ -x -q              # run before every handoff back to me
pytest tests/test_batch.py -x    # single file while iterating
ruff check services/             # lint — must be clean
mypy services/rescheduling/      # typecheck — must be clean
```

Run all four before telling me a change is done. Don't ask permission to run
them.

## Repo map

```
services/rescheduling/
  api.py               # FastAPI routes, flag gating, request validation
  handler.py           # orchestration — the actual business flow
  scheduler_client.py  # gRPC client for SchedulerV2
  kafka_publisher.py   # event publication
  models.py            # request/response shapes
tests/                 # pytest, one file per handler
```

## Sharp edges — read this section before touching anything

These are live, they are not hypothetical, and each one has cost us something.

- **Idempotency is NOT guaranteed by SchedulerV2.** The original design doc
  claimed it was "handled by the scheduler." That was an open question nobody
  closed, and it is now an incident (AURORA-1247). Assume retries reach the
  scheduler more than once. If you write a code path that can be retried,
  it needs a dedup key — verify, do not assume.

- **`job.rescheduled` double-fires.** Known Sev-3. Any new code path that
  publishes this event must deduplicate before publishing, not after.
  NotificationService consumes it and will notify the customer twice.

- **~15% of traffic still routes through OldSchedulerV1** via a legacy adapter.
  The cleanup was started and abandoned (AURORA-1102). Any change to scheduling
  behaviour has to be correct on *both* paths until that is 0%.

- **The eligibility check is a hand-rolled DSL and it is our latency hot spot.**
  Its latency alert fired 156 times in the last 30 days. Do not refactor it
  without profiling first, and do not add work inside it.

- **`reschedule_events` is an audit log with downstream readers** — support
  tooling, dispute resolution, and the Snowflake pipelines. A schema change here
  breaks consumers who are not in this repo. Ask before changing its shape.

- **We are currently missing both SLOs:** success rate 99.2% against a 99.5%
  target, p99 920ms against 800ms. Do not add a synchronous hop to a request
  path without telling me what it costs.

## Rules

Every rule here is one a reviewer could check. If you find a rule in this file
that can't be checked, tell me and we'll delete it.

- Every behaviour change ships with a test that **fails without the change**.
  A test that passes either way is worse than no test — it buys false confidence.
- Any code path that publishes to Kafka carries an idempotency key and dedups
  on it.
- No per-item database query inside a loop over a collection. Batch or join.
- No `SELECT *` on a request path — name the columns.
- A new endpoint that mutates more than one entity is asynchronous: accept,
  return `202` with a job id, process on a worker, expose a status endpoint.
  Temporal is already in our stack; prefer it over hand-rolled queuing.
- Every new code path gets a structured log line and a counter before it merges.
  If it's on a request path, a span too.
- Every gRPC or HTTP call sets an explicit timeout. No exceptions.
- No new dependency without asking me first.
- Match the conventions of the file you're editing over any general preference.

## Permission boundary

**Run freely, no need to ask:** tests, `ruff`, `mypy`, reads of any kind, git
status/diff/log, creating a branch.

**Ask me first:** adding a dependency, changing `reschedule_events` schema,
touching the eligibility DSL, changing a Statsig flag's definition, anything
that alters an existing endpoint's contract.

**Never, under any circumstances:** run a database migration, run a deploy,
force-push, write to anything whose name matches `*prod*`, or modify a feature
flag's live rollout percentage. If a task seems to require one of these, stop
and tell me what you'd need.

## When you're uncertain

For reversible work, proceed on a clearly stated assumption and tell me the
assumption in your first line back. For anything that isn't reversible — data,
deploys, external calls, contract changes — stop and ask. Don't split the
difference by guessing quietly.

If you think a rule in this file is wrong for the task at hand, say so and say
why. Don't route around it and don't agree with me to be agreeable; I keep you
in the loop specifically to get an opinion that isn't mine.

## Definition of done

1. Tests pass, lint clean, typecheck clean.
2. A test exists that fails if the change is reverted.
3. New code paths have a log line and a counter.
4. Timeouts set on every outbound call.
5. If it can be retried, it dedups.
6. You've told me what you *didn't* do and why.

---

**Owner:** Aurora EM · **Last reviewed:** 2026-09-20

This file is maintained like code. Two triggers to update it: the model does
something wrong (that's a missing rule) or I find myself retyping the same
context into a prompt (that's a missing section).
