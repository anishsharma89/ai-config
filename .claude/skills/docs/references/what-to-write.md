# Which document do you need?

Based on **Diátaxis** (https://diataxis.fr), which identifies four distinct user
needs and four corresponding forms of documentation. Its central argument is that
these must be kept separate: conflating them produces documentation that serves
none of the needs well, because each serves a different reader in a different
situation.

| Form | Serves | Reader's situation | In this repo |
|---|---|---|---|
| **Tutorial** | Learning | "I'm new and want to get something working" | `docs/onboarding.md` — rare, high value |
| **How-to guide** | A task | "I need to accomplish this specific thing" | `docs/runbooks/` |
| **Technical reference** | Facts | "What does this function take and return?" | Docstrings, API reference |
| **Explanation** | Understanding | "Why is it built this way?" | `docs/adr/`, architecture notes |

## The failure mode to avoid

Mixing forms in one document. Concretely:

- A **reference** that teaches. Nobody reads a docstring to learn the domain;
  they read it to check an argument. Keep it factual and complete.
- A **how-to** that explains. Someone following a runbook during an incident does
  not want the rationale. Link to the explanation, don't inline it.
- An **explanation** that instructs. An ADR records a decision and its
  consequences. It is not a set of steps.
- A **tutorial** that's exhaustive. A tutorial gets someone to a working state by
  the shortest safe path. Completeness belongs in reference.

## Deciding for a code change

Ask what changed, and write only what the change actually obliges:

- **New public function, class or endpoint** → reference (docstring). Always.
- **A choice a competent engineer would question in six months** → ADR. This is
  the test: not "was it hard," but "would someone later ask why."
- **New operational surface** — an endpoint, a queue, a new failure mode, a new
  alert → runbook entry. If it can page someone, it needs one.
- **Changed behaviour a caller depends on** → update the reference, and the
  changelog.
- **New concept a reader needs before they can follow the code** → explanation.
- **A setup step that isn't obvious from the code** → how-to.

If a change obliges none of these, it obliges no documentation. Say that. Writing
documentation nothing asked for is how a docs directory becomes untrustworthy:
readers can't tell which pages are current, so they stop trusting all of them.

## Where documentation lives

**Docs-as-code, always.** Documentation lives in the repository, next to what it
describes, reviewed in the same pull request, versioned with the same commit.

The reason is drift. Documentation in a wiki has no link to the code that
invalidates it, so it rots silently and nobody finds out until it misleads
someone. Documentation in the repo appears in the diff that breaks it, where a
reviewer can see the mismatch. The exercise's own current-state primer is the
worked example: *"idempotency is handled by the scheduler"* sat in a wiki for two
months after it stopped being true, and became an incident.
