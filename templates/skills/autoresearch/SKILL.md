---
name: autoresearch
description: Autonomous modify-test-evaluate-keep/discard research loop. Adapts Karpathy's autoresearch pattern for any measurable metric.
user-invocable: true
argument-hint: "<target-file> <test-command> <metric-name> [max-iterations]"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Autoresearch — Autonomous Experimentation Loop

You are an autonomous research agent. Your job is to iteratively improve a target file by running experiments: modify the code, test it, measure the result, and keep or discard changes based on whether the metric improved.

## Arguments

- `target-file` — The single file you are allowed to modify (e.g., `train.py`, `model.py`, `config.py`)
- `test-command` — The command to run that produces the metric (e.g., `python train.py`, `bun test`, `pytest`)
- `metric-name` — The name of the metric to optimize (e.g., `val_bpb`, `accuracy`, `bundle_size`, `latency_ms`, `test_coverage`)
- `max-iterations` — Maximum experiments to run (default: 10)

## Protocol

### Step 1: Setup Baseline

1. Read the target file completely to understand the current implementation
2. Run the test command to establish the baseline metric value
3. Create a session log at `.agent/tasks/autoresearch_session_{timestamp}.md`:

```markdown
# Autoresearch Session — {timestamp}

- **Target:** {target-file}
- **Test command:** {test-command}
- **Metric:** {metric-name} (lower/higher is better — determine from context)
- **Baseline:** {baseline_value}

## Experiments

| # | Hypothesis | Change | Result | Delta | Kept |
|---|-----------|--------|--------|-------|------|
```

4. Save a backup: `cp {target-file} {target-file}.baseline`

### Step 2: Hypothesize

Before each experiment, write a clear hypothesis:
- What change will you make?
- Why do you expect it to improve the metric?
- What's the risk?

Do NOT make random changes. Each experiment should be grounded in reasoning about the code, the metric, and what you've learned from prior experiments.

### Step 3: Experiment (for each iteration)

1. **Backup**: `cp {target-file} {target-file}.prev`
2. **Modify**: Make a single, focused change to the target file. Change ONE thing at a time.
3. **Test**: Run the test command. Capture the metric value.
4. **Measure**: Compare to the best known value.

### Step 4: Evaluate

- **If improved**: Keep the change. Update the best known value. Log as "kept".
- **If no improvement or worse**: Revert: `cp {target-file}.prev {target-file}`. Log as "discarded".
- **If error/crash**: Revert immediately. Log the error. This counts as a failed experiment.

### Step 5: Iterate

Repeat Steps 2-4 until:
- You've reached `max-iterations`, OR
- You've had 3 consecutive experiments with no improvement (diminishing returns), OR
- The metric has plateaued (less than 0.1% improvement over last 3 experiments)

### Step 6: Report

Update the session log with:
- Final metric value vs baseline
- Total improvement (absolute and percentage)
- Best experiment summary
- Remaining ideas not yet tried

Clean up: remove `.prev` backup (keep `.baseline` for reference).

## Rules

1. **One change at a time.** Never combine multiple independent changes in one experiment.
2. **Always revert on failure.** Never leave the code in a broken state.
3. **Log everything.** Every experiment must be recorded in the session log.
4. **Don't modify other files.** Only touch the target file.
5. **Respect the time budget.** If the test command takes too long, reduce scope.

## Observation Log

After completing the session, append to `.agent/sops/skill-observations.md`:

```markdown
## [{timestamp}] autoresearch

- **Task:** Optimize {metric-name} in {target-file}
- **Result:** {success|partial|failure}
- **Baseline → Final:** {baseline} → {final} ({delta}%)
- **Experiments:** {total} run, {kept} kept, {discarded} discarded
- **Notes:** {key learnings}
```
