# Ralph Loop Theory

**Based on Geoffrey Huntley's Ralph Loop Philosophy**

---

## The Core Mental Model

> "You got to think of context windows as arrays because they are — they're literally arrays."

Huntley frames context window management as memory allocation:

| Concept | Traditional Programming | Ralph Loop Development |
|---------|------------------------|------------------------|
| Resource | RAM | Context tokens |
| Allocation | `malloc()` | Deliberate context injection |
| Deallocation | `free()` | Starting fresh context |
| Fragmentation | Memory fragmentation | Context pollution/drift |
| Window | Memory pages | Sliding attention window |

**Key insight**: There is NO memory server-side. The array IS the memory. Every token you put in the context displaces potential reasoning capacity.

### The Smart Zone vs. The Dumb Zone

Huntley identifies distinct performance zones in context utilization:

```
┌─────────────────────────────────────────────────────────────┐
│  CONTEXT WINDOW                                             │
├─────────────────────────────────────────────────────────────┤
│ ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ └── Core Context   └── Working Space    └── Dumb Zone ──┘  │
│     (~5,000 tokens)    (Primary work)      (Degraded)       │
└─────────────────────────────────────────────────────────────┘
```

**Strategy**: Keep your core context small (~5,000 tokens), leave maximum working space for the task, and **never enter the dumb zone**. When approaching it, terminate and start fresh.

### Deliberate Context Allocation

Instead of letting context accumulate organically, Huntley advocates for **deliberate allocation**:

1. **First ~5,000 tokens**: Fixed application context — "here's what we're building"
2. **Index files with hyperlinks**: "Tease and tickle the latent space" that other files exist
3. **Task-specific injection**: Only what's needed for the current objective
4. **Reset for each item**: Start fresh context for each piece of work

### Back Pressure Engineering

> "Our job is now engineering back pressure to the generative function."

The goal is to keep the AI on rails through:
- Specification documents that constrain scope
- Clear termination conditions
- Architectural guardrails in the codebase itself
- Human review at integration points

### Human ON the Loop, Not IN the Loop

Two modes of operation:
1. **AFK Mode**: Set up architecture, launch loop, return later to review
2. **On-the-loop Mode**: Monitor progress, adjust specifications as needed

Both modes require **reviewing work before integration** — this is where human judgment is applied.

---

## Why Fresh Context Per Iteration?

### The Compaction Problem

> "Compaction is the devil."

Claude Code's auto-compaction summarizes context when approaching limits. The fundamental problem: when the LLM summarizes its own context, it decides what's important. This loses precision and introduces drift. Human-curated specifications maintain fidelity.

| Auto-Compaction Approach | Fresh Context Approach |
|-------------------------|------------------------|
| Continue in same context | Fresh context each loop |
| Auto-compact when full | Terminate before dumb zone |
| LLM summarizes what's "important" | Human curates what persists |
| Promise-based completion | State-file based iteration |
| Implicit context management | Explicit context allocation |

### The External Bash Loop

**Critical distinction**: The Ralph loop runs OUTSIDE Claude Code, not inside it.

```bash
while :; do cat prompt.md | claude --dangerously-skip-permissions; done
```

This bash loop:
1. Spawns a **fresh Claude Code session** each iteration
2. Pipes in `prompt.md` as the **deterministic context allocation**
3. Session completes its work, exits
4. Loop immediately spawns next fresh session
5. State persists in **files and git**, not conversation memory

The `prompt.md` file is the key artifact — it's the standing instruction set that gets injected into every fresh context window.

---

## Parsimonious Context Engineering

### The Lookup Table Pattern

The `readme.md` is the high-level index that Claude's search tool uses to find context. It should:
1. Describe the project briefly
2. List available specs with **enough description** to guide search
3. Include hyperlinks that "tease and tickle the latent space"
4. NOT include full specifications inline — just enough to know what exists

### Token Budget

**Initial injection (via prompt.md):**

| Component | Budget |
|-----------|--------|
| prompt.md content | ~450 tokens |
| readme.md (loaded by prompt) | ~550 tokens |
| spec.md (loaded by prompt) | ~4000 tokens |
| **Total core context** | **~5000 tokens** |

This approach leaves the **maximum possible context** for actual work. Claude only loads additional docs as needed for the current task.

---

## Sandboxed Development

### The Risk Model

Running with `--dangerously-skip-permissions` gives Claude full system access. Three factors combine into serious risk:
1. **Network access** — egress to external systems
2. **Private data access** — access to sensitive files
3. **Untrusted input** — prompts/code that could be adversarial

### Blast Radius Limitation Strategies

#### Option A: Virtual Machine (Recommended for high-risk work)

Full VM isolation provides complete kernel separation:
- Snapshot before each session, rollback if needed
- No container escape vectors
- Can wipe and rebuild quickly

#### Option B: Container (Lighter alternative)

Docker provides lighter isolation with some tradeoffs:
- Faster startup, lower resource use
- Weaker isolation (shared kernel)
- Good for trusted codebases

#### Option C: Dedicated User Account (Minimum viable isolation)

A separate user account with limited access:
- No access to your personal files
- Own SSH keys and credentials
- Easiest to set up

#### Option D: Bare Metal (Huntley's approach)

Dedicated physical machine:
- Complete air-gap from personal data
- Declarative, reproducible configuration (e.g., NixOS)
- Gold standard but requires dedicated hardware

### Practical Recommendation

For most work: use a dedicated git branch and review before merging. The spec constrains scope, git tracks all changes, and human review catches issues.

For high-risk work (untrusted repos, sensitive environments): use a VM or container.

---

## The Specification as Back Pressure

The spec document is not just a plan — it's a constraint system:

1. **Scope limitation**: Only work described in the spec gets done
2. **Step atomicity**: One step per session prevents scope creep
3. **Evidence requirements**: Each step must show proof of completion
4. **Review gates**: Mandatory review phases catch accumulated errors
5. **Dual tracking**: Spec checkboxes AND beads tasks must agree

### Self-Updating Plans

The loop updates its own spec:
- Checkboxes get marked `[x]` as steps complete
- Progress log captures what happened each session
- Stuck flags document blocking issues
- The spec evolves as a living record

---

## Key Quotes from Geoffrey Huntley

> "Context windows are arrays...you got to think of context windows as arrays because they are — they're literally arrays."

> "The less that window needs to slide, the better. There is no memory server side. It's literally that an array. The array is the memory. So you want to allocate less."

> "We're deliberately allocating. This is the key. Deliberate context allocation about your application."

> "5,000ish tokens that are dedicated for like here's what we're building and we want that in every time."

> "index.md or readme.md which is a whole bunch of hyperlinks out to different specs...Enough to like tease and tickle the latent space."

> "Reset the goal. Reallocate the objective."

> "There is a dumb zone. You should stay out of it."

> "Human on the loop not in the loop."

> "Our job is now engineering back pressure to the generative function."

> "Compaction is the devil."

---

## Comparison Table

| Aspect | Long-Running Session | Ralph Loop |
|--------|---------------------|------------|
| Loop execution | Internal (same session) | External bash loop spawning sessions |
| Context per iteration | Same (continuing) | Fresh (new window each time) |
| Context injection | Accumulates organically | `cat prompt.md \| claude` pipes in |
| State persistence | In context memory | On disk (specs, git, beads) |
| Compaction | Auto-compacts when full | Never (fresh context each iteration) |
| Task selection | Continues where left off | Reads spec, picks first incomplete |
| Self-updating | Manual | Yes (updates spec checkboxes) |
| Human role | In the loop | On the loop (reviews at end) |
| Context management | Implicit | Explicit allocation via prompt.md |

---

*Based on Geoffrey Huntley's Ralph Loop methodology as presented in his talks and demonstrations.*
