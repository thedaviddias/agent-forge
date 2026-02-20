# Agent Forge

A curated collection of primitives I use with LLMs and AI agents — skills, rules, MCP configs, agents, and hooks across Claude, Cursor, Codex, and other AI-native tools.

This repo is open source. Feel free to use, adapt, or fork anything here.

## Installation

From the repo root, run:

```bash
./install.sh              # skills only (default): symlink into ~/.agents/skills and ~/.cursor, ~/.claude, ~/.codex
./install.sh --all        # install all primitives (skills + rules + MCP + agents + hooks)
./install.sh --with-mcp   # skills + MCP configs (~/.agents/mcp.d/ and merged ~/.agents/mcp.json)
./install.sh --with-rules # skills + bundle rules (~/.agents/rules/)
./install.sh --with-agents   # skills + bundle agents (~/.agents/agents/)
./install.sh --with-hooks     # skills + bundle hooks (~/.agents/hooks/)
./install.sh --with-commands # skills + bundle commands (~/.agents/commands/)
./install.sh --with-tasks    # skills + bundle tasks (~/.agents/tasks/)
./install.sh --dry-run       # show what would be done, no changes
./install.sh --force      # overwrite existing symlinks and replace real dirs in ~/.agents/skills
./install.sh -h           # help
```

- **Default**: only skills are installed (unchanged behavior). All primitives go to `~/.agents/`; tools symlink from there (e.g. `~/.cursor/skills` → `~/.agents/skills`).
- **Dry-run** (`--dry-run`): prints every link that would be created and a summary; does not create or change anything.
- **Force** (`--force`): replaces existing symlinks and real directories in `~/.agents/skills` with symlinks into this repo.

## Bundle contract

Each top-level category (`global/`, `openclaw/`, `web-development/`, etc.) is a **bundle** that can contain:

| Primitive | Location | Cursor | Claude | Codex |
|-----------|----------|--------|--------|-------|
| **skills** | `category/skills/<name>/` | ✓ | ✓ | ✓ |
| **rules** | `category/rules/` | ✓ | ✓ | — (AGENTS.md) |
| **commands** | `category/commands/` | ✓ (plugin) | ✓ | — |
| **agents** | `category/agents/` | ✓ (plugin) | other shape | AGENTS.md |
| **MCP** | `category/mcp.json` | ✓ | ✓ | ✓ |
| **hooks** | `category/hooks.json` or `category/hooks/` | ✓ | ✓ | — |
| **tasks** | `category/tasks/` | optional / future | — | — |

See [docs/BUNDLE-ARCHITECTURE.md](docs/BUNDLE-ARCHITECTURE.md) for the full layout, cross-tool comparison, and how `~/.agents/` is used as the canonical home for all primitives.

## What each folder is for (and how AI tools use it)

Each bundle can contain these folders (and files). Here’s what they do and which tools use them:

| Folder / file | What it’s for | How AI tools use it |
|---------------|----------------|----------------------|
| **skills/** | Task-specific capabilities: instructions, when to use, examples. One subfolder per skill, each with a `SKILL.md`. | **Cursor, Claude, Codex**: Load skills from `~/.cursor/skills`, `~/.claude/skills`, or `~/.agents/skills`. The agent picks a skill when your request matches its description; you can also invoke by name (e.g. `/skills` or `$skill-name`). |
| **rules/** | Persistent guidance (style, patterns, constraints). One `.md` or `.mdc` file per topic; often loaded at session start or when working in matching paths. | **Cursor**: Uses `.cursor/rules/` (.mdc with frontmatter). **Claude Code**: Uses `.claude/rules/` (.md); can target paths so rules apply only in certain files. **Codex**: No `rules/` folder; uses a single `AGENTS.md` for project instructions. |
| **commands/** | User-invoked shortcuts: “run this when I type `/something`.” One file per command (e.g. `review.md` → `/review`). Can include prompts, bash snippets, and args. | **Cursor**: Plugins can ship a `commands/` dir; commands are agent-executable. **Claude Code**: `.claude/commands/` — each `.md` becomes a slash command (e.g. `/review`); supports args and inline bash. **Codex**: No user-defined commands folder; only built-in slash commands. |
| **agents/** | Definitions for custom “sub-agents” or specialized personas (e.g. reviewer, advisor). Config or prompt per agent. | **Cursor**: Plugins can define agents in an `agents/` folder. **Claude Code**: Sub-agents / agent management (different structure). **Codex**: Uses a single `AGENTS.md` for instructions, not a folder of agents. |
| **tasks/** | Task templates or saved tasks (e.g. “migrate to TypeScript”, “add tests”). Optional; not all tools have a first-class tasks folder. | **Cursor**: Plan mode and tasks can be tool-specific. **Claude**: `/task` for in-session tasks. **Codex**: `/plan` for planning. This folder is for storing reusable task definitions if a tool supports it later. |
| **mcp.json** | Model Context Protocol: list of MCP servers (APIs, DBs, external tools) the agent can call. One file per bundle; install merges them. | **Cursor, Claude, Codex**: Each tool reads MCP config (project or user level) and connects to the listed servers so the agent can use those tools (e.g. GitHub, DB, Slack). |
| **hooks/** or **hooks.json** | Lifecycle automation: run scripts or inject prompts on events (e.g. before commit, on session start). | **Cursor**: Plugins can use `hooks.json` (e.g. pre-commit checks). **Claude Code**: Hooks in config for events like session start. **Codex**: No standard hooks folder in the same way. |

After you run `./install.sh --all`, everything is linked under `~/.agents/` (e.g. `~/.agents/skills`, `~/.agents/rules`, `~/.agents/commands`). Tools that use their own paths (e.g. `~/.cursor/skills`) are already symlinked from there for skills; for rules, commands, and MCP you may need to point the tool at `~/.agents/` or symlink/copy into the tool’s expected location (see [docs/BUNDLE-ARCHITECTURE.md](docs/BUNDLE-ARCHITECTURE.md)).

## Structure

Primitives are organized by category (bundles). Each skill lives in its own folder.

**Skills** give agents specialized knowledge and workflows for specific tasks:

```
category/
└── skills/
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
