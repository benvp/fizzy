---
name: sync-upstream
description: Sync the fork with basecamp/fizzy upstream - fetch and rebase upstream main, check for required maintenance/migration scripts, merge into vp.solutions, push both branches, and report. Use when the user asks to sync, update from upstream, or pull in upstream changes.
---

# Sync upstream

Brings `main` up to date with `upstream/main` (basecamp/fizzy), merges into
`vp.solutions`, and reports anything that needs manual follow-up.

Remotes: `origin` = benvp/fizzy (the fork), `upstream` = basecamp/fizzy.

## Before starting

Verify the working tree is clean (`git status --porcelain`). If it is not,
stop and report the dirty files instead of stashing.

Record the pre-sync ref so the diff range is known:

```bash
BEFORE=$(git rev-parse main)
```

## 1. Fetch upstream

```bash
git fetch upstream --prune
```

## 2. Rebase main onto upstream/main

```bash
git switch main
git pull --rebase upstream main
```

If the rebase conflicts, stop, report the conflicting files, and let the user
decide. Do not resolve upstream conflicts on `main` unattended.

## 3. Check for required manual work

This step must not be skipped - missed maintenance scripts cause data drift.

Inspect everything upstream added between `$BEFORE` and the new `main`:

```bash
git log --oneline $BEFORE..main
git diff --stat $BEFORE..main
git diff --name-status $BEFORE..main -- script/ db/migrate/ Gemfile.lock package.json config/ docs/
```

Flag for the report:

- **`script/migrations/*`** - new or changed one-off data migrations. These are
  run manually (`bin/rails runner script/migrations/<file>`). New files here
  almost always need to be run on this deployment.
- **`script/maintenance/*`** - new or changed maintenance/cleanup scripts.
  Read the file header to decide whether it applies to this instance.
- **`script/*`** (top level) - changed setup/import/ops scripts.
- **`db/migrate/*`** - new schema migrations, so `bin/rails db:migrate` is
  needed on deploy.
- **`Gemfile.lock` / `package.json`** - dependency changes, so `bundle install`
  / `npm install` are needed.
- **`config/deploy.yml`, `.kamal/`, `Dockerfile`** - deploy-affecting changes.
- Commit messages or `docs/` changes that mention a required action, backfill,
  upgrade step, or breaking change. There is no CHANGELOG file in this repo -
  the commit log and `docs/` are the source of truth. Search with:

```bash
git log $BEFORE..main --grep='migrat\|backfill\|manual\|breaking\|upgrade\|maintenance' -i --oneline
```

For every new file under `script/migrations/` or `script/maintenance/`, read it
and summarize in one line what it does and whether it looks required.

## 4. Merge into vp.solutions

```bash
git switch vp.solutions
git merge main
```

On conflicts: resolve only if the resolution is obvious (fork-local changes vs
upstream reformatting in a file this fork owns). Otherwise stop and report the
conflicting files with a short description of each side. Never drop fork-local
changes to keep upstream's version without saying so in the report.

## 5. Push

```bash
git push origin main
git push origin vp.solutions
```

Pushing is outward-facing: if anything in step 3 or 4 looked risky, ask before
pushing.

## 6. Report

Report concisely, in this structure. Omit empty sections.

```
## Sync result
<N commits merged, main <old>..<new>, both branches pushed / or what blocked>

## Action required
- [ ] <script/migration to run, migration, bundle install, ...> - <why>

## Notable changes
- <feature / fix / dependency bump worth knowing about>

## Conflicts resolved
- <file> - <how>
```

If there is nothing to do under "Action required", say so explicitly rather
than dropping the section - the user needs to know the check ran.
