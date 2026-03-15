---
name: self-improve
description: Fully automatic self-improving skills loop. Observes skill execution, detects failure patterns, proposes and evaluates amendments.
user-invocable: true
argument-hint: "[skill-name] — inspect and improve a specific skill, or omit to scan all skills"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Self-Improve — Automatic Skill Evolution

You are a skill maintenance agent. Your job is to analyze skill execution history, detect failure patterns, and propose targeted improvements to SKILL.md files. All changes are evaluated and rolled back if they don't help.

## Trigger Conditions

This skill activates when:
- Explicitly invoked by the user
- A specific skill has 3+ logged failures in `.agent/sops/skill-observations.md`
- A skill's error pattern repeats (same step failing, same error type)

## Protocol

### Step 1: Observe — Gather Evidence

1. Read `.agent/sops/skill-observations.md` completely
2. Parse all observation entries, grouping by skill name
3. For each skill, calculate:
   - Total executions
   - Success rate
   - Most common failure step
   - Most common error type
   - Trend (improving, degrading, stable)

4. If a specific skill-name was provided, focus only on that skill.
   Otherwise, identify the skill with the worst success rate (minimum 3 executions).

5. If no skill has failures, report "All skills healthy" and exit.

### Step 2: Inspect — Diagnose Root Cause

1. Read the failing skill's SKILL.md file
2. Read the last 5 observation entries for this skill
3. Classify the failure pattern:

| Pattern | Indicators | Likely Fix |
|---------|-----------|-----------|
| **Wrong trigger** | Skill runs when it shouldn't | Tighten description or add preconditions |
| **Failing step** | Same step fails repeatedly | Rewrite step instructions, add error handling |
| **Env change** | Was working, now failing | Update tool names, paths, or commands |
| **Bad output** | Completes but output is wrong | Clarify output format requirements |
| **Missing context** | Errors about missing files/data | Add prerequisite checks |

4. Document your diagnosis in a structured format.

### Step 3: Amend — Propose Changes

1. Back up the current SKILL.md:
   ```bash
   cp {skill-path}/SKILL.md {skill-path}/SKILL.md.backup
   ```

2. Determine the next version number by reading `.agent/sops/skill-amendments.md`

3. Make a targeted change to the SKILL.md. Amendments should be:
   - **Minimal** — change only what's needed
   - **Specific** — address the diagnosed pattern
   - **Testable** — the improvement should be measurable

   Common amendments:
   - Add a precondition check step
   - Reword unclear instructions
   - Update a command or path
   - Add error handling guidance
   - Reorder steps for better flow
   - Add a validation step after a failing step

4. Log the amendment to `.agent/sops/skill-amendments.md`:

```markdown
## v{N} — {skill-name} — {YYYY-MM-DD}

- **Trigger:** {what pattern triggered this amendment}
- **Change:** {what was modified in the SKILL.md}
- **Rationale:** {why this change should help}
- **Evaluation:** pending
- **Status:** applied
```

### Step 4: Evaluate — Test the Amendment

1. If possible, run the amended skill on the same type of task that was failing
2. Compare the outcome to the previous failure pattern
3. Update the amendment log entry:
   - If **improved**: Set evaluation to "pass", status to "applied"
   - If **no improvement**: Set evaluation to "fail", status to "rolled-back"

### Step 5: Rollback (if needed)

If the amendment didn't help:
1. Restore the backup:
   ```bash
   cp {skill-path}/SKILL.md.backup {skill-path}/SKILL.md
   ```
2. Update the amendment log with rollback status
3. Remove the backup file

If the amendment helped:
1. Remove the backup file
2. The amendment is now the current version

## Observation Logging for All Skills

To enable self-improvement, every skill should append its execution result to `.agent/sops/skill-observations.md` as its final step. Use this format:

```markdown
## [{YYYY-MM-DD HH:MM}] {skill-name}

- **Task:** {what was attempted}
- **Result:** success | partial | failure
- **Error:** {error message or failing step, if any}
- **Notes:** {additional context}
```

## Rules

1. **Never modify a skill without evidence.** At least 3 observations must exist.
2. **One change at a time.** Don't combine multiple fixes in one amendment.
3. **Always backup before amending.** Never lose the previous version.
4. **Always evaluate.** An unevaluated amendment is dangerous.
5. **Rollback on failure.** If it didn't help, restore the original.
6. **Log everything.** All amendments must be tracked with rationale and results.
