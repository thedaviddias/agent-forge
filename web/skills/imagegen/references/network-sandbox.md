# Network and sandbox (tool-agnostic)

Image generation uses the OpenAI Image API, so the CLI needs outbound network access. Some agents run in a sandbox or require approval before networked commands. This guidance can vary by tool and environment; prefer the defaults in your environment when in doubt.

## Why am I asked to approve every image generation call?

The CLI needs network access to call the OpenAI API. In many setups, network is disabled by default or the approval policy requires confirmation before networked commands run.

## Per-tool notes

**Codex**
- Network access is often disabled in stricter sandbox modes. To reduce repeated approval prompts: enable network for the relevant sandbox and relax the approval policy.
- Example `~/.codex/config.toml`: `approval_policy = "never"`, `sandbox_mode = "workspace-write"`, and under `[sandbox_workspace_write]` set `network_access = true`.
- Or for a single session: `codex --sandbox workspace-write --ask-for-approval never`.

**Cursor**
- If the tool restricts network or sandbox, allowlist or enable network for this skill’s scripts (e.g. the directory containing `scripts/image_gen.py`).

**Claude Code**
- If the tool restricts network, enable or allowlist network for the script runs used by this skill.

## Safety note

Use caution: enabling network and disabling approvals reduces friction but increases risk if you run untrusted code or work in an untrusted repository.
