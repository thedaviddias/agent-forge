# Core Prompt Engineering Patterns

## Core Capabilities

### Few-Shot Learning

Use 2-5 input/output examples when behavior must be consistent (format, reasoning style, edge cases).

```markdown
Extract key information from support tickets:

Input: "My login doesn't work and I keep getting error 403"
Output: {"issue":"authentication","error_code":"403","priority":"high"}

Input: "Feature request: add dark mode to settings"
Output: {"issue":"feature_request","error_code":null,"priority":"low"}
```

### Chain-of-Thought Scaffolding

For multi-step tasks, ask for explicit intermediate checks before the final answer.

```markdown
Analyze the bug report.
Think step by step:
1. Expected behavior
2. Actual behavior
3. Recent changes
4. Most likely root cause
```

### Prompt Optimization Loop

Iterate in small steps and test each revision against a fixed input set.

```markdown
v1: summarize article
v2: summarize in 3 bullets
v3: identify top findings, then summarize in 3 bullets
```

### Template Systems

Create reusable templates with explicit variables.

```python
template = """
Review this {language} code for {focus_area}.
Code:
{code_block}
Checklist:
{checklist}
"""
```

### System Prompt Design

Put stable behavior in system instructions and keep request-specific details in user prompts.

```markdown
System: Senior backend engineer specialized in API design.
Rules:
- Flag security concerns
- Provide Python examples
- Include tradeoffs
```

## Key Patterns

### Progressive Disclosure

Start simple and only add complexity when quality requires it.

1. Direct instruction
2. Add constraints
3. Add reasoning steps
4. Add examples

### Instruction Hierarchy

`System Context -> Task Instruction -> Examples -> Input Data -> Output Format`

### Error Recovery

For uncertain or fragile tasks, require fallback behavior:

- State uncertainty explicitly
- Request missing information
- Offer best-effort answer with caveats

## Best Practices

- Be specific about output format and constraints.
- Prefer examples over long explanations.
- Test with normal and edge-case inputs.
- Track prompt versions and changelogs.
- Document why each major constraint exists.

## Common Pitfalls

- Over-engineering too early
- Ambiguous or conflicting instructions
- Excessive examples causing context bloat
- No edge-case validation

## Integration Patterns

### With RAG

```python
prompt = f"""Given this context:
{retrieved_context}

Question: {user_question}

Answer using only the context above.
If context is insufficient, say what is missing."""
```

### With Self-Verification

```python
prompt = f"""{main_task_prompt}

Before finalizing, verify:
1. Answered the question directly
2. Used only allowed context
3. Cited specific evidence
4. Flagged uncertainty"""
```

## Performance Optimization

### Token Efficiency

- Remove redundant wording
- Consolidate overlapping instructions
- Move stable policy to system prompt

### Latency Reduction

- Keep prompts concise
- Reuse cached prompt prefixes
- Batch similar requests when possible
