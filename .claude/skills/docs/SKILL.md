---
name: docs
description: Write or update documentation to the standards in this repo — docstrings, ADRs, runbooks, README and architecture notes. Use when documenting a change, when asked what documentation a change needs, or when a PR review flags a documentation obligation. Picks the right document type before writing a word.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(git log:*), Bash(git diff:*)
---

# Writing documentation

Your first job is not to write. It is to work out **which kind of document is
needed**, because the four kinds have different content, different structure and
different readers, and the commonest documentation failure is answering one
need with another kind of document.

Read `references/what-to-write.md` and pick the type before drafting.

## The rule that overrides everything else

**Never write documentation you cannot verify.** If you don't know why a decision
was made, do not infer a reason and write it down — an invented rationale is
worse than a blank section, because the next reader believes it and stops asking.

When you hit something only a human knows, write the heading, leave a marked gap,
and tell the user what you need:

```markdown
## Why we chose Temporal over a hand-rolled worker pool

<!-- NEEDS AUTHOR: the alternatives you actually weighed, and what decided it.
     I can see the choice in the code; I can't see the reasoning. -->
```

That gap is useful. A plausible guess in its place is a liability.

## What you may generate, and what you may not

**Generate freely** — the shape is derivable from the code:
- Docstring skeletons: parameters, return type, raised exceptions
- API reference from signatures and types
- Changelog entries from commit messages
- A runbook's mechanical sections: how to check status, where the logs are,
  which dashboard, which alert fires

**Draft, then require a human pass** — the shape is derivable but being wrong is
expensive:
- Runbook remediation steps. Wrong steps get followed at 3am by someone who
  trusts them.
- Anything describing failure behaviour you have not seen fail.

**Never generate** — requires intent you don't have access to:
- The *why* of any decision. ADR Context and Decision sections.
- Alternatives considered and why they were rejected.
- Trade-offs knowingly accepted.
- Anything that would go in a "known limitations" section.

## Standards

- **Docstrings:** `references/reference-docs.md`
- **ADRs:** `references/adr.md`, and `docs/adr/template.md` for the format
- **Prose style:** plain language, active voice, present tense. Say what the
  thing does, not what it "is designed to" do. Cut every sentence that would
  survive being deleted.

## Before you finish

- Does every claim in what you wrote correspond to something you actually read?
- Have you linked the code, ticket or dashboard a reader will want next?
- If this document goes stale, what will make that visible? An undated document
  with no owner is already stale and nobody can tell.
- Is there a `NEEDS AUTHOR` marker left? Say so explicitly in your reply — don't
  let it merge silently.
