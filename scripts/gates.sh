#!/usr/bin/env bash
# Deterministic quality gates. Identical locally and in CI — that is the point.
# Run this before you push:  ./scripts/gates.sh
#
# Nothing here involves a model. Every check returns the same answer for the
# same input, every time, on every machine. Formatting disputes end here rather
# than in review.

set -euo pipefail

BASE_REF="${BASE_REF:-origin/main}"
FAILED=0

step() { printf '\n\033[1m▸ %s\033[0m\n' "$1"; }
fail() { printf '\033[31m  ✗ %s\033[0m\n' "$1"; FAILED=1; }
pass() { printf '\033[32m  ✓ %s\033[0m\n' "$1"; }

step "Formatting (ruff format)"
if ruff format --check .; then
  pass "formatting is canonical"
else
  fail "run 'ruff format .' and commit — formatting is not a review topic"
fi

step "Lint (ruff check)"
if ruff check .; then
  pass "lint clean"
else
  fail "lint violations above"
fi

step "Types (mypy)"
if mypy .; then
  pass "typecheck clean"
else
  fail "type errors above"
fi

step "Tests + coverage"
if pytest -q --cov --cov-report=xml --cov-report=term-missing; then
  pass "tests pass"
else
  fail "tests failing"
fi

# 100% coverage of the lines this PR changed. Scoped to the diff because that
# is where the target is achievable without incentivising assertion-free tests
# written purely to move a global percentage.
step "Diff coverage (100% of changed lines)"
if [ -f coverage.xml ]; then
  if diff-cover coverage.xml --compare-branch="$BASE_REF" --fail-under=100; then
    pass "every changed line is covered"
  else
    fail "changed lines are not fully covered — see report above"
  fi
else
  fail "no coverage.xml produced"
fi

printf '\n'
if [ "$FAILED" -ne 0 ]; then
  printf '\033[31m✗ Gates failed. Fix these before review — a human should never\n'
  printf '  spend attention on something a tool can decide.\033[0m\n'
  exit 1
fi
printf '\033[32m✓ All gates passed. Ready for review.\033[0m\n'
