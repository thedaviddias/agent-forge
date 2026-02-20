# Agent Forge

A curated collection of primitives I use with LLMs and AI agents — skills, hooks, and MCP configs across Claude, Cursor, and other AI-native tools.

This repo is open source. Feel free to use, adapt, or fork anything here.

## Structure

Primitives are organized by category. Each one lives in its own folder.

**Skills** give agents specialized knowledge and workflows for specific tasks:

```
category/
└── skill-name/
    ├── SKILL.md          # Required: instructions and metadata
    ├── scripts/          # Optional: helper scripts
    ├── templates/        # Optional: document templates
    └── resources/        # Optional: reference files
```

## Creating a Skill

Each skill is a folder with a `SKILL.md` file using YAML frontmatter:

```markdown
---
name: my-skill-name
description: A clear description of what this skill does and when to use it.
---

# My Skill Name

Detailed description of the skill's purpose and capabilities.

## When to Use This Skill

- Use case 1
- Use case 2

## Instructions

[Detailed instructions for the agent on how to execute this skill]

## Examples

[Real-world examples showing the skill in action]
```

### Best Practices

- Focus on specific, repeatable tasks
- Include clear examples and edge cases
- Write instructions for the agent, not end users
- Test across Claude.ai, Claude Code, Cursor, and API
- Document prerequisites and dependencies
- Include error handling guidance
