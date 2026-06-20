---
kind: context
id: git_conventions
version: 1
source_id: pro_rails_docs
source_ref: context/conventions/git-conventions.md
domain: tooling
audience: [developer, architect, backend_engineer, frontend_engineer, tester]
topics: [role-base-developer, git, commits, conventions]
references: []
stability: stable
---

# Git & Commits (Pro-Rails)

## Rules

| Rule | Why |
|---|---|
| Conventional one-line commit messages, describe the change not the files | Readable log, useful for `git blame` and changelog generation |
| NEVER add `Co-Authored-By` / AI attribution lines | Project policy |
| Git runs on the HOST, not inside Docker | Container has no git config / SSH keys |
| Don't `--no-verify` / skip hooks | Hooks run lint, type-check, security scan — fix what they report |
| Prefer NEW commits over `--amend` | Exception: cleaning up an unpushed WIP commit is fine |

## Commit message shape

```
<type>: <imperative summary, lowercase>

# Examples
feat: add ticket assignment workflow
fix: prevent double-publish on rescheduled announcements
refactor: extract idempotency guard from PublishJob
docs: clarify interactor error handling rule
test: cover stale-timestamp branch in PublishJob
chore: bump rubocop to 1.62
```

Describe the **change**, not the files (`fix: handle nil author`, NOT `fix: ticket.rb line 47`).
