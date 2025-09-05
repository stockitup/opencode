---
description: Review pull request by checking out, merging with develop, and analyzing
agent: build
---

Checkout PR #$ARGUMENTS, merge with develop, check for migration conflicts, and review:

1. Run `gh pr checkout $ARGUMENTS`
2. Run `git merge origin/develop`
3. Check the migrations/ folder for conflicting migrations between this PR and develop:
   - List migrations in the current branch and check for numbering conflicts
   - If there are migration files with the same number from both branches, resolve by favoring develop's numbering (renumber the PR's migrations to the next available numbers)
   - Ensure migrations follow the sequential numbering pattern (e.g., 152_*.sql, 153_*.sql, etc.)
4. Run `gh pr diff $ARGUMENTS` to see the changes
5. Use researcher agent to review the code changes