---
name: visualize
description: Generate SVG or HTML diagrams to visualize architecture, data flow, state machines, or any system concept.
user-invocable: true
argument-hint: "<subject> [format] — format: svg (default), html"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Visualize — Diagram Generation

Generate clear, well-structured diagrams as SVG or HTML files. Useful for architecture overviews, data flow diagrams, state machines, dependency graphs, and any other visual representation.

## Steps

### Step 1: Understand the Subject

1. Parse the subject from the arguments
2. If the subject refers to existing code/architecture, read the relevant files to understand the structure
3. If the subject is abstract (e.g., "auth flow"), gather context from:
   - `directives/SOP.md` (architecture section)
   - `.agent/system/architecture.md`
   - Relevant source files

### Step 2: Design the Diagram

Choose the appropriate diagram type:

| Subject | Diagram Type | Best Format |
|---------|-------------|-------------|
| System architecture | Box-and-arrow | SVG |
| Data flow | Flowchart | SVG |
| State machine | State diagram | SVG |
| API endpoints | Table/tree | HTML |
| File structure | Tree | SVG |
| Dependency graph | Directed graph | SVG |
| Sequence/timeline | Sequence diagram | SVG |
| Dashboard/metrics | Cards + charts | HTML |

### Step 3: Generate

**For SVG:**
- Write a clean SVG file with:
  - Readable fonts (14-16px, system font stack)
  - Good spacing and alignment
  - Meaningful colors (not random)
  - Proper viewBox for scaling
  - Grouped elements with descriptive IDs

**For HTML:**
- Write a self-contained HTML file with:
  - Inline CSS (no external dependencies)
  - Responsive layout
  - Clean, modern styling
  - Dark/light mode support via `prefers-color-scheme`

### Step 4: Save

Save the output to a descriptive path:
```
docs/diagrams/{subject-slug}.{svg|html}
```

Create the `docs/diagrams/` directory if it doesn't exist.

### Step 5: Report

Tell the user:
- What was visualized
- Where the file was saved
- How to view it (e.g., `open docs/diagrams/architecture.svg`)

## Rules

1. **Self-contained** — No external dependencies, CDN links, or imports
2. **Readable** — Use clear labels, adequate spacing, and appropriate font sizes
3. **Accurate** — Diagram must reflect actual code/architecture, not assumptions
4. **Accessible** — Use text labels (not just colors) to convey meaning

## Observation Log

After completing, append to `.agent/sops/skill-observations.md`:

```markdown
## [{timestamp}] visualize

- **Task:** Visualize {subject}
- **Result:** success | partial | failure
- **Error:** {if any}
- **Notes:** Output saved to {path}
```
