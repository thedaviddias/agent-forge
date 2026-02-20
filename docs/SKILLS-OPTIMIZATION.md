# Skills: how tools manage them and how to optimize

This doc summarizes how Cursor, Claude Code, and Codex load skills (and thus use tokens), and how to keep many skills efficient.

## How each tool handles skills

All three follow the [Agent Skills](https://agentskills.io/) open standard and use **progressive disclosure**: only a small amount of context per skill is loaded upfront; full content loads when a skill is chosen.

### Shared model (Agent Skills spec)

1. **Metadata (~100 tokens per skill)** — Loaded at startup for **all** skills: `name` and `description` from YAML frontmatter. Used so the agent can decide which skill is relevant.
2. **Full SKILL.md** — Loaded only when the skill is **activated** (user invokes it or the agent matches the description).
3. **References / scripts / assets** — Loaded **on demand** when the skill references them during execution.

So the main token cost of “having many skills” is **N × (tokens for name + description)**. Full instructions and references only add tokens when a skill is actually used.

### Cursor

- Uses **dynamic context discovery**: name and description are in “static context” in the system prompt so the agent can pick a skill.
- The agent can also discover relevant skills via tools (e.g. grep, semantic search).
- Long outputs (e.g. terminal, MCP) are written to files instead of stuffing the context window.

Sources: [Cursor dynamic context](https://cursor.com/blog/dynamic-context-discovery), [working with context](https://docs.cursor.com/guides/working-with-context).

### Claude Code

- **Level 1**: Metadata (name, description) discovered at startup — lightweight.
- **Level 2**: Full `SKILL.md` content when the skill is triggered (user message matches description, or user invokes `/skill-name`).
- **Level 3**: Supporting files in the skill directory (e.g. `references/`, `scripts/`) loaded only when referenced.

So many skills only add metadata to the initial context; full content is on-demand.

Sources: [Claude Code skills](https://code.claude.com/docs/en/skills), [Claude API Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview), [lazy loading issue](https://github.com/anthropics/claude-code/issues/16160).

### Codex

- Skills are stored under `~/.agents/skills` (and repo/user/admin scope). Activated implicitly (task matches description) or explicitly (user mentions the skill).
- **AGENTS.md** (custom instructions) is separate: it’s concatenated from multiple files and **capped at 32 KiB** by default. Skills themselves follow the same progressive-disclosure idea: metadata for selection, full content when activated.

Sources: [Codex skills](https://developers.openai.com/codex/skills), [AGENTS.md](https://developers.openai.com/codex/guides/agents-md).

---

## Optimization tips

1. **Keep descriptions short and precise**
   Descriptions are in context for every skill. ~50–100 tokens each is typical; 50 skills ≈ 2.5k–5k tokens. Avoid long paragraphs; focus on “what it does + when to use it” and clear keywords so the right skill is chosen.

2. **Keep SKILL.md body under ~500 lines / &lt; 5000 tokens**
   The [Agent Skills spec](https://agentskills.io/specification) recommends this so that when a skill is activated, it doesn’t dominate the context. Move long reference material into `references/` or `assets/` and link from `SKILL.md` so those files load only when needed.

3. **Use the spec’s description limit**
   Description is max 1024 characters. Shorter is better for token use; make every sentence count for matching.

4. **Prefer references for deep content**
   Put detailed guides, examples, or templates in `references/` (or `assets/`) and reference them from the main instructions. Tools load these on demand, so you get “unbounded” depth without paying tokens until the skill runs.

5. **Use subfolders so SKILL.md stays short**
   Put long content in subfolders and link from `SKILL.md`; tools load them only when the skill references them.
   - **references/** — Deep docs, guides, examples, reference tables. Link from SKILL.md (e.g. `See [references/guide.md](references/guide.md)`).
   - **scripts/** — Runnable helpers (CLI, validation, one-off scripts). Refer to them in instructions (e.g. `Run scripts/validate.sh`).
   - **assets/** — Static files (images, data, schemas). Reference when the skill needs them.
   - **templates/** — Document or code templates the agent fills in.
   Keep the main **SKILL.md** to core “when to use”, steps, and pointers; move everything else into these folders so the skill stays under ~500 lines and only pulls in what’s needed.

6. **Avoid duplicate or overlapping skills**
   Overlapping descriptions make it harder for the agent to choose and can bloat metadata. Merge or narrow scope so each skill has a clear, distinct purpose.

7. **Scope by project**
   By default this repo installs only the **global/** bundle to `~/.agents/skills`; other bundles (web, marketing, etc.) are installed per-project with `./install.sh --project DIR --bundles web,marketing`. That keeps the global metadata set small and adds only the bundle skills each project needs in its `.cursor/skills`. Cursor and other tools merge project-level skills with global skills.

---

## Summary

| Concern | What actually happens |
|--------|------------------------|
| **Many skills = slow or expensive?** | Cost scales with **metadata** (name + description) for all skills. Full instructions and references are loaded only when a skill is activated. |
| **Cursor** | Metadata in system context; full skill + references on demand; dynamic discovery. |
| **Claude Code** | Metadata at startup; full SKILL.md when triggered; supporting files on demand. |
| **Codex** | Same idea: metadata for selection, full content when skill is used; AGENTS.md is separate (32 KiB cap). |
| **Best levers** | Short, precise descriptions; keep SKILL.md under ~500 lines; use `references/`, `scripts/`, `assets/` for long content and link from SKILL.md. |

---

## Reviewing and enforcing limits

### Validation script (this repo)

Run the built-in validator from the repo root to check all skills against the spec and token limits:

```bash
node scripts/validate-skills.mjs           # strict by default: name, description ≤1024, body ≤500 (allowlist for long skills)
node scripts/validate-skills.mjs --no-strict  # basic only: no body line limit
node scripts/validate-skills.mjs --lenient # skip name-vs-directory match (enforce description/body only)
```

It checks:

- Every skill has `SKILL.md` with YAML frontmatter and required `name` + `description`
- `name` matches the skill directory and uses only `a-z`, `0-9`, `-` (per [spec](https://agentskills.io/specification))
- `description` length ≤ 1024 characters
- **Body ≤ 500 lines** (default). Skills listed in `scripts/skills-strict-allowlist.txt` (one `category/skill-name` per line) are allowed to exceed 500 lines until refactored; remove a line after moving content to `references/`.
- **Formatting:** frontmatter field order (`name` before `description`); file must end with a single newline . **Warnings** (do not fail): description very short or missing “use when” phrasing; broken links to `references/*.md`.

### Structural reporting

To **inspect size metrics** for all skills (without changing validation behavior), use `--report`:

```bash
node scripts/validate-skills.mjs --report        # one line per skill: desc length, body lines, token estimate, OK/OVER
node scripts/validate-skills.mjs --report=json  # same metrics as JSON array (for piping or dashboards)
node scripts/validate-skills.mjs --report=csv    # same metrics as CSV
```

You can combine with `--no-strict` or `--lenient`; validation still runs and exit code is 1 if any skill fails validation. The report is additive: it prints after any validation errors.

**Metrics:**

- **desc** — Description length in characters (spec max 1024).
- **body** — Body (content after frontmatter) in lines.
- **~tokens** — Rough token estimate for the body (chars ÷ 4); no LLM tokenizer is used.
- **status** — `OK` or `OVER`. `OVER` means the skill exceeds recommended limits: description &gt; 1024 chars, or body &gt; 500 lines, or body token estimate &gt; 5000. The [Agent Skills spec](https://agentskills.io/specification) recommends keeping the SKILL.md body under ~500 lines and ~5000 tokens so the skill doesn’t dominate context when activated.

Use the report to find skills to refactor (move content to `references/`) or to track size over time (e.g. pipe `--report=json` to a file and diff).

### Outcome evals

To measure whether a skill **improves agent behavior** (outcome efficiency), use the **outcome evals** in `scripts/evals/`. Each eval is a prompt plus a deterministic verifier (no LLM-as-judge). Run from repo root:

```bash
ANTHROPIC_API_KEY=... node scripts/run-skill-evals.mjs [--eval id] [--report-dir path]
```

See [scripts/evals/README.md](scripts/evals/README.md) for the eval format, how to add evals, and how to interpret the report.

The pre-commit hook runs `node scripts/validate-skills.mjs` (strict by default), so new or edited skills must stay under 500 lines (or be added to the allowlist temporarily). Fix any reported errors and re-run until it passes.

### Reviewing and refactoring long skills

1. **See which skills are over 500 lines:** Run `node scripts/validate-skills.mjs` — any skill not in the allowlist that fails has a body that’s too long. Skills in the allowlist are “known long” and should be refactored when you touch them.
2. **Refactor without losing quality:** Move long sections (reference material, detailed examples, tables) into `references/` and link from `SKILL.md`. Keep in `SKILL.md` only: when to use, a short overview, and links to the reference files. See `global/skills/prompt-engineering/` for an example: the main doc is short and points to `references/core-patterns.md`, `references/agent-best-practices.md`, and `references/persuasion-principles.md`.
3. **After refactoring:** Remove that skill from `scripts/skills-strict-allowlist.txt` so the strict check enforces the 500-line limit for it from then on.

### Do you need Lefthook or Biome?

- **Lefthook (git hooks)** — Optional but useful. This repo includes a `.lefthook.yml` that runs the validator on pre-commit when any `*/skills/**/*.md` file is staged. Setup:
  1. Install: `npm install -g @evilmartians/lefthook` or `brew install lefthook`
  2. In repo root: `lefthook install`
  The hook runs `node scripts/validate-skills.mjs` (strict by default: body ≤500 lines; allowlisted skills excepted until refactored).
- **Biome** — Not needed for skill limits. Biome is a linter/formatter for JavaScript, TypeScript, JSON, etc. It doesn’t understand `SKILL.md` or the Agent Skills spec. Use Biome if you want consistent formatting for other repo files (e.g. `package.json`, scripts); use the validation script (and optionally Lefthook) to enforce skill rules.
