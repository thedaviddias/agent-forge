# Persuasion Principles for Agent Communication

Use these principles to improve instruction adherence in prompts and skills. Apply them ethically.

## Summary

Research by Meincke et al. (2025) found persuasion framing can materially increase compliance in AI conversations. Use this to enforce quality and safety practices, not to manipulate users.

## Seven Principles

### 1. Authority

- Use clear non-negotiable wording for critical constraints.
- Best for safety, verification, and fragile procedures.

### 2. Commitment

- Require explicit choices, checklists, or announcements.
- Best for multi-step workflows and accountability.

### 3. Scarcity

- Use time or sequence constraints when order matters.
- Best for immediate verification steps.

### 4. Social Proof

- Reinforce norms with patterns like "always" or "every time".
- Best for preventing repeated failure modes.

### 5. Unity

- Use collaborative language around shared goals and quality.
- Best for peer-style workflows.

### 6. Reciprocity

- Usually unnecessary in agent instructions.
- Use sparingly to avoid manipulative tone.

### 7. Liking

- Avoid for compliance enforcement.
- Can weaken honest critique and create sycophancy.

## Recommended Combinations

| Prompt type | Use | Avoid |
| --- | --- | --- |
| Discipline-enforcing | Authority + Commitment + Social Proof | Liking, Reciprocity |
| Guidance | Moderate Authority + Unity | Heavy authority |
| Collaborative | Unity + Commitment | Authority-heavy framing |
| Reference docs | Clarity only | Persuasion stacking |

## Ethical Guardrail

Use persuasion framing only when it improves reliability, safety, and user outcomes. If it would feel deceptive when explained openly, do not use it.
