# Agent Prompting Best Practices

## Context Window as Shared Capacity

Treat context as a shared resource with system prompts, conversation history, and other loaded instructions.

- Keep new prompt text proportional to task risk.
- Avoid repeating concepts the model already knows.
- Keep reusable stable guidance in system-level instructions.

## Concision First

Prefer concise, direct prompts over explanatory prose.

### Better

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

### Worse

Long narratives that explain obvious concepts before giving executable instructions.

## Choose the Right Degree of Freedom

### High Freedom

Use when many valid approaches exist and context determines the best solution.

```markdown
Review the code for bugs, maintainability, and edge cases.
```

### Medium Freedom

Use when a preferred structure exists but implementation details can vary.

```python
def generate_report(data, format="markdown", include_charts=True):
    ...
```

### Low Freedom

Use when operations are fragile and sequence matters.

```bash
python scripts/migrate.py --verify --backup
```

## Practical Checklist

Before finalizing a prompt:

1. Is every line necessary for task success?
2. Are constraints explicit and testable?
3. Is output format unambiguous?
4. Is failure behavior defined?
5. Is token/latency cost justified?
