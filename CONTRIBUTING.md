# Contributing

Thanks for contributing to Agent Forge.

## New Skill Checklist

1. Create the skill at `category/skills/<skill-slug>/SKILL.md`.
2. Use frontmatter with canonical naming:
   - `name` must exactly match `<skill-slug>`
   - `description` should be clear and include "Use when ..."
3. Keep `SKILL.md` concise:
   - Target <= 500 body lines
   - Move deep material to `references/`, `scripts/`, `assets/`, or `templates/`
4. Ensure local links resolve (no broken relative paths).
5. Run validation before opening a PR:
   - `pnpm run validate-skills`
   - `pnpm run check:links`
   - `pnpm run validate:all` (full check, includes secret scan)
6. If you add scripts, include usage docs and stable output behavior.
7. Update docs when behavior changes (`README.md`, `docs/`).

## Test Expectations

- Every change should include at least one verification step.
- For installer changes, include command/flag scenarios in your PR notes.
- For schema/contract changes, document compatibility impact and migration notes.
