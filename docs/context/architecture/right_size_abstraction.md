---
kind: skill
id: right_size_abstraction
version: 1
source_id: pro_rails_docs
source_ref: skills/principle/right_size_abstraction.md
domain: architecture
audience: [architect, backend_engineer, frontend_engineer]
topics: [principle, abstraction, dry]
applies_to_roles: [architect, backend_engineer, frontend_engineer]
requires_context_topics: []
stability: stable
---

# Right-Size Abstraction

Pick the simplest abstraction that preserves the dependency rule.

## Heuristics

- **Rule of three**: duplicate twice, extract on the third.
- **Right tool, right complexity**: 3-line action → no interactor. 200-line action → definitely interactor.
- **Single source of truth**: same rule in two places = future drift.
- **Consistency > cleverness**: match the project's existing pattern.

## Callback / observer scoring

| Trigger | Type | Action |
|---|---|---|
| Data integrity (must happen, same TX) | Keep close to entity |
| Side effect (email, webhook, queue) | Move to Application layer |
| Logging / metrics | Infrastructure, edge |

Side effect inside entity callback = smell.

## When NOT to abstract

- Used once. Inline.
- Used twice, no clear shape yet. Inline both, watch.
- "Might need it later." No.

## When to abstract

- Used 3+ times with same shape.
- Rule must be enforced regardless of caller.
- Pattern documented in project docs.

## Smells

| Smell | Diagnosis |
|---|---|
| Premature abstraction (1 use) | Inline it |
| Under-abstracted chaos (3+ copies) | Extract |
| Abstraction wraps 1-line call | Delete the wrapper |
| Conditional logic switching by type 3+ places | STI or polymorphism |
