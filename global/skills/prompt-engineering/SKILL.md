---
name: prompt-engineering
description: Use when designing or improving prompts, commands, hooks, skills, or sub-agent instructions, including output quality, reliability, and token efficiency.
---

# Prompt Engineering

Use this skill to design robust prompts that are clear, testable, and cost-aware.

## When to Use This Skill

- Creating or refactoring prompts for skills, commands, hooks, and reusable templates
- Improving output consistency, formatting, or reasoning quality
- Reducing token usage or latency while preserving quality
- Choosing the right level of strictness (high, medium, low freedom)
- Defining guardrails and verification steps for fragile workflows

## Workflow

1. Define the exact task outcome, constraints, and required format.
2. Choose the minimum instruction detail needed for the task's fragility.
3. Start with a concise baseline prompt.
4. Add structure: examples, explicit output schema, and failure handling.
5. Add verification criteria for correctness and uncertainty handling.
6. Test on varied and edge-case inputs, then iterate.

## Expected Outputs

- A production-ready prompt (or template) with clear task, context, and output contract
- A short rationale for major design choices
- A test checklist with representative inputs and edge cases
- Notes on token and latency tradeoffs

## References

- [Core Patterns](references/core-patterns.md)
- [Agent Best Practices](references/agent-best-practices.md)
- [Persuasion Principles](references/persuasion-principles.md)
