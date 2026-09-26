---
name: commit-message
description: Write or refine Conventional Commit messages for this project, or create a local commit when explicitly requested. Never push.
---

# Commit messages for this project

Follow this repository’s commit conventions from `CONTRIBUTING.md`, the `commitlint` configuration in `package.json`, and recent history.

## Workflow

1. Read `git log --oneline -10` to match the project’s current style.
2. Inspect the relevant staged and unstaged diff. Summarize the actual changes before choosing a type and scope. Do not include unrelated work in a commit.
3. Write one concise subject. Add a short body when the user asks for one or the change needs context; separate it from the subject with a blank line and explain what changed and why.
4. If the user explicitly asks to commit, stage only files relevant to that commit, create the local commit, and report its subject and hash. Never push.

Do not stage or commit when the user only asks for a suggested message.

## Format

```text
<type>(<scope>): <short description>
```

The scope is optional. Use `ios`, `android`, or `js` when the change is limited to that platform or layer. Omit the scope when a change spans multiple layers.

Use a Conventional Commit type accepted by this repository’s `commitlint` configuration. Common choices include:

- `feat`: add functionality
- `fix`: correct a bug
- `refactor`: change implementation without adding a feature or fixing a bug
- `docs`: update documentation
- `test`: add or change tests
- `chore`: dependency, configuration, or other supporting work
- `release`: prepare a release

Write commit messages in English. Keep the subject lowercase and no longer than 72 characters. Do not end it with punctuation or add emoji. Keep any body concise and specific to the diff.

Examples from this project:

```text
feat: add updateMaximumDate to dynamically update max selectable date
fix(ios): stop calendar scroll on dismiss to prevent crash
chore: upgrade react native and dependencies
release: 1.2.0
```
