study .ralph/readme.md
study .ralph/specs/YOUR_SPEC.md

Pick the first incomplete step (unchecked checkbox). Do that ONE step.

If ALL steps are complete: log "COMPLETE" in Progress Log, commit, push,
create .ralph/COMPLETE file, exit. Do not look for more work.

WORKFLOW:
1. Create feature branch if not exists: git checkout -b BRANCH_NAME
2. Implement the step (write unit tests for new functionality)
3. Run tests (PROJECT_TEST_COMMAND)
4. Mark checkbox complete in the spec
5. Log session outcome in Progress Log table
6. Commit and push
7. Exit

CONTEXT MONITORING:
Run .ralph/check-context.sh periodically during implementation.
If >=80%: stop, checkpoint progress, commit, push, exit.
Check especially when: reading many files, debugging, or feeling stuck.

Commit granularity: one commit per completed sub-step (checkbox item).
Always push before exiting.

If step is complex: break into sub-steps, commit plan update, exit.
If blocked: document blocker in spec, commit, exit.
If tests fail: fix or document, commit progress, exit.
