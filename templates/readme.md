# [Project Name]

[Brief project description - 1-2 sentences]

## Reference Docs

- [constraints.md](reference/constraints.md) - [Brief description of what constraints are documented]
- [patterns.md](reference/patterns.md) - [Brief description of code patterns]

## Loop Discipline

Check context before major actions: `.ralph/check-context.sh`
- <80%: continue working
- >=80%: checkpoint and exit (next session continues fresh)

If step is larger than expected: break into sub-steps in the plan, commit progress, exit.
Always: commit working changes immediately, update plan before exit.

## Active Implementation Plans

- [current-spec.md](specs/current-spec.md) - [Description of current work]

## Architecture (if applicable)

- [Link to architecture docs]
- [Link to other relevant docs]

## Entry Points

```bash
# How to run tests
make test

# How to run the project
./run.sh
```
