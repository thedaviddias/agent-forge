# Bundle architecture

Bundles are top-level directories that contain primitives (skills, rules, commands, agents, tasks, MCP, hooks).

## Skills: global vs per-project

- **Global install (default):** Only the **global/** bundle’s skills are installed to `~/.agents/skills/` and symlinked into `~/.cursor/skills`, `~/.claude/skills`, `~/.codex/skills`. Use `./install.sh --all-bundles` to install every bundle’s skills globally (legacy behavior).
- **Per-project:** Other bundles (web, marketing, game, etc.) are installed only when you opt in per project: `./install.sh --project <dir> --bundles web,marketing`. That creates symlinks in `<dir>/.cursor/skills` (and `.claude/skills`, `.codex/skills`) so that project sees those skills in addition to your global skills.

## Canonical home: `~/.agents/`

After `./install.sh` (skills only) or `./install.sh --all`:

- **Skills** → `~/.agents/skills/` (default: global bundle only; use `--all-bundles` for all). Symlinked into `~/.cursor/skills`, `~/.claude/skills`, `~/.codex/skills`.
- **Rules** → `~/.agents/rules/` (when installed with `--with-rules` or `--all`)
- **Commands** → `~/.agents/commands/`
- **Agents** → `~/.agents/agents/`
- **Tasks** → `~/.agents/tasks/`
- **MCP** → `~/.agents/mcp.d/` (per-bundle) and merged `~/.agents/mcp.json`
- **Hooks** → `~/.agents/hooks/`

Tools that expect their own paths (e.g. Cursor’s `.cursor/rules`) may need to be pointed at `~/.agents/` or symlinked; see each tool’s docs.

## Cross-tool comparison

| Primitive | Cursor | Claude Code | Codex |
|-----------|--------|--------------|-------|
| skills    | ✓      | ✓            | ✓     |
| rules     | ✓ (.mdc) | ✓ (.md)    | AGENTS.md |
| commands  | ✓ (plugin) | ✓        | —     |
| agents    | ✓ (plugin) | other shape | AGENTS.md |
| MCP       | ✓      | ✓            | ✓     |
| hooks     | ✓      | ✓            | —     |
