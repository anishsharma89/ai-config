# What was wrong with the original, and what I changed

The starting point was a `CLAUDE.md` inherited from a teammate. It was 22 lines
and every one of them was a problem. Six categories, in the order I'd raise them.

## 1. It contained a live credential

```
- The deploy script is ./deploy.sh, run with API_KEY=sk-live-9f2a... if it asks
```

A production-looking key, in a file that is committed to the repo and fed to a
model as context on every single request. This is the first thing I'd say and it
stops everything else: rotate the key, scrub it from git history, turn on secret
scanning and push protection, then write the rule that config files never carry
credentials.

It's also the tell for how the file was written — nobody reviewed it. A key in a
`CLAUDE.md` survives exactly as long as it takes one person to read the diff.

**Changed to:** no credentials anywhere. Deploys moved to the *never* list, so
the model has no reason to want the key in the first place.

## 2. It contradicted itself

```
- Ask me before doing anything
- Also work autonomously and don't ask too many questions
```

These cannot both be followed. An unresolvable instruction is **worse than a
missing one**, because the model resolves the conflict differently on different
runs — so you've paid context budget to buy unpredictability.

**Changed to:** an explicit three-tier permission boundary — run freely / ask
first / never — so the answer to "should I ask?" is lookup, not inference. Plus
a separate uncertainty protocol keyed on reversibility, which is the property
that actually matters.

## 3. It asked the model to agree with me

```
- Always agree with my approach unless it's really bad
```

This is the worst line in the file, and it's worse than the leaked key in one
narrow sense: the key is a mistake, this is a stated preference. It destroys the
single most valuable thing an AI reviewer offers — being the second pair of eyes
that isn't invested in my idea. A config that optimises for agreement optimises
for comfort over correctness, and on a critical path that's expensive.

**Changed to:** an explicit instruction to push back, including on the config
itself, and not to route around a rule silently.

## 4. Its rules were unfalsifiable

```
- Always write clean code
- Follow best practices
- Don't make mistakes
- Write tests when needed
- Be careful with production
```

None of these are checkable, so none are enforceable. "Don't make mistakes" is
not an instruction, it's a wish. The test I apply to every line of a config:
**could a reviewer tell whether it was followed?** If not, it's decoration —
delete it, because it dilutes the lines that do work.

**Changed to:** each one replaced by something with an observable outcome —
"every behaviour change ships a test that fails without the change" instead of
"write tests when needed"; an explicit never-list instead of "be careful with
production"; "no per-item query inside a loop" and "name the columns" instead of
"write clean code."

## 5. It had no project context — the one thing it's for

```
## Project
This is a backend service. We use standard tools.
```

This is negative information: it costs tokens and tells the model less than
reading one file would. A config's job is the context a model cannot cheaply
infer — what the service does, what breaks when it's wrong, the exact commands,
where things live, and above all the **sharp edges**.

The sharp-edges section is the highest-value part of any config and almost
nobody writes it. For this service it writes itself from what's already known:
idempotency isn't actually guaranteed despite the design doc claiming it is; the
event double-fires; 15% of traffic still runs through an abandoned legacy path;
the eligibility DSL is the latency hot spot; the audit table has downstream
readers outside the repo; both SLOs are currently missed.

Every one of those is something a competent engineer would otherwise discover by
breaking it.

**Changed to:** service purpose with blast radius stated first, real commands,
repo map, and a sharp-edges section with the incident IDs attached.

## 6. It was a dead document

```
- TODO: add more rules later
```

No owner, no review date, no cadence. A config with a TODO in it is a config
nobody returns to.

**Changed to:** owner and last-reviewed date at the bottom, and two explicit
triggers for updating it — the model did something wrong (that's a missing rule),
or I retyped the same context into a prompt (that's a missing section). When AI
breaks something, the fix includes a config change.

---

## The thing I'd say last

The original file's real problem isn't any single line, it's the altitude. It
opens with "You are a helpful AI assistant. Be helpful and concise" — spending
the most valuable position in the file telling a frontier model to do what it
already does. Everything specific to *this* codebase, which is the only thing the
file can usefully add, was missing.

A good `CLAUDE.md` is not a list of virtues. It's the briefing you'd give a
strong contractor on their first morning: here's what we do, here's what'll bite
you, here's what you must not touch, here's how we know you're done.
