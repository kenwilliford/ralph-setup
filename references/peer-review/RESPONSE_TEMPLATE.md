# Review Response Template (For Claude Author)

Use this template when responding to peer review findings.

---

## Response Header

```markdown
# Review Response: [Plan Title]

**Author:** [Agent Name]
**Response Round:** [1 or 2]
**Date:** [ISO date]
**Responding to:** [Review document name]

## Executive Summary

[2-3 sentence summary of changes made and overall response approach]

## Overall Assessment

**GO / CONDITIONAL GO / NO-GO**

[1-2 sentence assessment from author's perspective after addressing feedback]
```

## Response to Findings

Each finding response should follow this structure:

```markdown
## Responses to Findings

### [F1] [Finding Title]

**Severity:** [As stated by reviewer]
**Disposition:** Accepted | Partially Accepted | Acknowledged | Contested

**Response:**
[Detailed response to the concern]

**Action Taken:**
[Specific changes made, or explanation if no changes]

**Evidence:**
[Reference to specific changes in plan, or supporting rationale]

---

### [F2] [Next Finding Title]
...
```

## Disposition Definitions

| Disposition | Meaning | Required Action |
|-------------|---------|-----------------|
| **Accepted** | Agree with finding, implementing recommended change | Must describe specific changes made |
| **Partially Accepted** | Agree with concern, but implementing different solution | Must explain alternative approach and rationale |
| **Acknowledged** | Understand the concern, but no change warranted | Must provide clear rationale for not changing |
| **Contested** | Disagree with the finding | Must provide evidence-based counter-argument |

## Response Quality Checklist

Before submitting response, verify:

- [ ] Every finding has a response (no skipped findings)
- [ ] Each response has clear disposition
- [ ] Accepted findings have specific evidence of changes
- [ ] Contested findings have substantive rationale (not dismissive)
- [ ] Questions from reviewer are answered
- [ ] Overall assessment is justified

## Answers to Questions

```markdown
## Answers to Reviewer Questions

### [Q1] [Question text]

**Answer:**
[Direct answer with supporting detail]

---

### [Q2] [Question text]
...
```

## Changes Summary

```markdown
## Summary of Changes

### Plan Modifications

| Section | Change | Rationale |
|---------|--------|-----------|
| [Section name] | [Brief description] | [Why] |
| ... | ... | ... |

### No-Change Decisions

| Finding | Rationale for No Change |
|---------|------------------------|
| [Finding ref] | [Brief rationale] |
| ... | ... |
```

## Closing

```markdown
## Recommendation to Editor

[Final paragraph directed at the human decision-maker, summarizing:
- The review process
- Key concerns and how they were addressed
- Any residual concerns or risks
- Author's recommendation]

**Final Assessment: GO / CONDITIONAL GO / NO-GO**

**Confidence Level:** High | Medium | Low

[Brief justification for confidence level]
```
