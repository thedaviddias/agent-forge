#!/usr/bin/env bash
set -euo pipefail

# Skills to skip (e.g. templates or examples)
SKIP_SKILLS=( "template-skill" )

# Canonical install in ~/.agents/; then symlink into each tool so they see the same skills
AGENTS_ROOT="${HOME}/.agents"
AGENTS_SKILLS="${AGENTS_ROOT}/skills"
AGENTS_RULES="${AGENTS_ROOT}/rules"
AGENTS_AGENTS="${AGENTS_ROOT}/agents"
AGENTS_MCP="${AGENTS_ROOT}/mcp.json"
AGENTS_MCP_D="${AGENTS_ROOT}/mcp.d"
AGENTS_HOOKS="${AGENTS_ROOT}/hooks"
AGENTS_COMMANDS="${AGENTS_ROOT}/commands"
AGENTS_TASKS="${AGENTS_ROOT}/tasks"
TOOL_DIRS=( "${HOME}/.cursor/skills" "${HOME}/.claude/skills" "${HOME}/.codex/skills" )
RELPATH_AGENTS="../../.agents/skills"

# Resolve absolute path (works on macOS and Linux)
abspath() {
  local dir="$1"
  (cd "$dir" && pwd -P)
}

# Parse flags
FORCE=false
DRY_RUN=false
WITH_MCP=false
WITH_RULES=false
WITH_AGENTS=false
WITH_HOOKS=false
WITH_COMMANDS=false
WITH_TASKS=false
for arg in "$@"; do
  case "$arg" in
    --force)          FORCE=true ;;
    --dry-run)        DRY_RUN=true ;;
    --all)            WITH_MCP=true; WITH_RULES=true; WITH_AGENTS=true; WITH_HOOKS=true; WITH_COMMANDS=true; WITH_TASKS=true ;;
    --with-mcp)       WITH_MCP=true ;;
    --with-rules)     WITH_RULES=true ;;
    --with-agents)    WITH_AGENTS=true ;;
    --with-hooks)     WITH_HOOKS=true ;;
    --with-commands)  WITH_COMMANDS=true ;;
    --with-tasks)     WITH_TASKS=true ;;
    -h|--help)
      echo "Usage: $0 [--force] [--dry-run] [--all | --with-mcp | --with-rules | --with-agents | --with-hooks | --with-commands | --with-tasks]"
      echo "  --force          Overwrite existing symlinks and replace real directories in ~/.agents/skills"
      echo "  --dry-run        Print actions without creating or changing anything"
      echo "  --all            Install all primitives (skills + rules + MCP + agents + hooks + commands + tasks)"
      echo "  --with-mcp       Also install MCP configs to ~/.agents/mcp.d/ and merge to ~/.agents/mcp.json"
      echo "  --with-rules     Also install bundle rules to ~/.agents/rules/"
      echo "  --with-agents    Also install bundle agents to ~/.agents/agents/"
      echo "  --with-hooks     Also install bundle hooks to ~/.agents/hooks/"
      echo "  --with-commands  Also install bundle commands to ~/.agents/commands/"
      echo "  --with-tasks     Also install bundle tasks to ~/.agents/tasks/"
      echo ""
      echo "By default only skills are installed (unchanged behavior)."
      exit 0
      ;;
  esac
done

FORGE_ROOT="$(abspath "$(dirname "$0")")"

# Discover all skills: (skill_name,category) pairs, first category wins if duplicate name
SKILL_NAMES=()
SKILL_CATEGORIES=()
for category in "$FORGE_ROOT"/*/; do
  [ -d "${category}skills" ] || continue
  for skill_dir in "${category}skills"/*/; do
    [ -d "$skill_dir" ] || continue
    [ -f "${skill_dir}SKILL.md" ] || continue
    skill_name="$(basename "$skill_dir")"
    for skip in "${SKIP_SKILLS[@]}"; do
      [[ "$skill_name" == "$skip" ]] && continue 2
    done
    seen=false
    for ((j=0; j<${#SKILL_NAMES[@]}; j++)); do
      [[ "${SKILL_NAMES[$j]}" == "$skill_name" ]] && { seen=true; break; }
    done
    if [[ "$seen" != true ]]; then
      SKILL_NAMES+=( "$skill_name" )
      SKILL_CATEGORIES+=( "$(basename "$category")" )
    fi
  done
done

linked=0
skipped=0
warned=0

mkdir -p "$AGENTS_SKILLS"
for tool in "${TOOL_DIRS[@]}"; do
  mkdir -p "$tool"
done

# Sort by skill name for stable output (temp file avoids subshell array issues on Bash 3)
pair_count=${#SKILL_NAMES[@]}
tmp_list=$(mktemp)
trap 'rm -f "$tmp_list"' EXIT
for ((i=0; i<pair_count; i++)); do
  echo "${SKILL_NAMES[$i]}|${SKILL_CATEGORIES[$i]}"
done > "$tmp_list"
sort -t'|' -k1,1 "$tmp_list" -o "$tmp_list"

while IFS='|' read -r skill_name category; do
  source_dir="$FORGE_ROOT/$category/skills/$skill_name"
  target="$AGENTS_SKILLS/$skill_name"

  if [[ -L "$target" ]]; then
    if [[ "$FORCE" == true ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] would overwrite symlink: $target -> $source_dir"
      else
        rm "$target"
        ln -s "$source_dir" "$target"
        echo "linked: $skill_name ($target -> $source_dir)"
      fi
      ((linked++)) || true
    else
      echo "skip (existing symlink): $skill_name"
      ((skipped++)) || true
    fi
  elif [[ -d "$target" ]]; then
    if [[ "$FORCE" == true ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] would replace directory with symlink: $target -> $source_dir"
      else
        rm -r "$target"
        ln -s "$source_dir" "$target"
        echo "linked: $skill_name ($target -> $source_dir)"
      fi
      ((linked++)) || true
    else
      echo "warn (real directory, use --force to replace): $target"
      ((warned++)) || true
    fi
  else
    if [[ "$DRY_RUN" == true ]]; then
      echo "[dry-run] would link: $target -> $source_dir"
    else
      ln -s "$source_dir" "$target"
      echo "linked: $skill_name ($target -> $source_dir)"
    fi
    ((linked++)) || true
  fi

  # Symlink into each tool's skills dir when missing (same pattern as skills.sh)
  for tool in "${TOOL_DIRS[@]}"; do
    tool_skill="$tool/$skill_name"
    if [[ -e "$tool_skill" ]]; then
      continue
    fi
    if [[ "$DRY_RUN" == true ]]; then
      echo "  [dry-run] would link: $tool_skill -> $RELPATH_AGENTS/$skill_name"
    else
      ln -s "$RELPATH_AGENTS/$skill_name" "$tool_skill"
      echo "  -> $tool_skill"
    fi
  done
done < "$tmp_list"

echo ""
echo "Summary: linked=$linked skipped=$skipped warned=$warned"

# --- Optional primitives (bundles: rules, MCP, agents, hooks) ---

install_bundle_primitive() {
  local kind="$1"    # mcp, rules, agents, commands, tasks
  local dest_base="$2"
  local count=0
  for category in "$FORGE_ROOT"/*/; do
    [ -d "$category" ] || continue
    local name
    name="$(basename "$category")"
    local src
    case "$kind" in
      mcp)      src="${category}mcp.json"; [ -f "$src" ] || continue ;;
      rules)    src="${category}rules";    [ -d "$src" ] || continue ;;
      agents)   src="${category}agents";    [ -d "$src" ] || continue ;;
      commands) src="${category}commands"; [ -d "$src" ] || continue ;;
      tasks)    src="${category}tasks";    [ -d "$src" ] || continue ;;
      *)        continue ;;
    esac
    local dest="${dest_base}/${name}"
    if [[ "$kind" == "mcp" ]]; then
      dest="${dest_base}/${name}.json"
    fi
    if [[ "$DRY_RUN" == true ]]; then
      echo "[dry-run] would link $kind: $dest -> $src"
    else
      mkdir -p "$(dirname "$dest")"
      if [[ -L "$dest" ]] || [[ -e "$dest" ]]; then
        rm -rf "$dest"
      fi
      ln -sf "$src" "$dest"
      echo "bundle $kind: $name -> $dest"
    fi
    ((count++)) || true
  done
  if [[ $count -gt 0 ]] && [[ "$DRY_RUN" != true ]] && [[ "$kind" == "mcp" ]]; then
    if command -v jq >/dev/null 2>&1 && [[ -d "$AGENTS_MCP_D" ]]; then
      local merged
      merged=$(jq -s '[.[].mcpServers? // {}] | add | {mcpServers: .}' "$AGENTS_MCP_D"/*.json 2>/dev/null || true)
      if [[ -n "$merged" ]]; then
        echo "$merged" > "$AGENTS_MCP"
        echo "bundle mcp: merged -> $AGENTS_MCP"
      fi
    fi
  fi
}

install_bundle_hooks() {
  local dest_base="$1"
  for category in "$FORGE_ROOT"/*/; do
    [ -d "$category" ] || continue
    local name
    name="$(basename "$category")"
    if [[ -f "${category}hooks.json" ]]; then
      local dest="${dest_base}/${name}.json"
      if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] would link hooks: $dest -> ${category}hooks.json"
      else
        mkdir -p "$(dirname "$dest")"
        [[ -L "$dest" ]] || [[ -e "$dest" ]] && rm -rf "$dest"
        ln -sf "${category}hooks.json" "$dest"
        echo "bundle hooks: $name -> $dest"
      fi
    fi
    if [[ -d "${category}hooks" ]]; then
      local dest="${dest_base}/${name}"
      if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] would link hooks: $dest -> ${category}hooks"
      else
        mkdir -p "$(dirname "$dest")"
        [[ -L "$dest" ]] || [[ -e "$dest" ]] && rm -rf "$dest"
        ln -sf "${category}hooks" "$dest"
        echo "bundle hooks: $name (dir) -> $dest"
      fi
    fi
  done
}

if [[ "$WITH_MCP" == true ]]; then
  [[ "$DRY_RUN" != true ]] && mkdir -p "$AGENTS_MCP_D"
  install_bundle_primitive mcp "$AGENTS_MCP_D"
fi
if [[ "$WITH_RULES" == true ]]; then
  [[ "$DRY_RUN" != true ]] && mkdir -p "$AGENTS_RULES"
  install_bundle_primitive rules "$AGENTS_RULES"
fi
if [[ "$WITH_AGENTS" == true ]]; then
  [[ "$DRY_RUN" != true ]] && mkdir -p "$AGENTS_AGENTS"
  install_bundle_primitive agents "$AGENTS_AGENTS"
fi
if [[ "$WITH_HOOKS" == true ]]; then
  [[ "$DRY_RUN" != true ]] && mkdir -p "$AGENTS_HOOKS"
  install_bundle_hooks "$AGENTS_HOOKS"
fi
if [[ "$WITH_COMMANDS" == true ]]; then
  [[ "$DRY_RUN" != true ]] && mkdir -p "$AGENTS_COMMANDS"
  install_bundle_primitive commands "$AGENTS_COMMANDS"
fi
if [[ "$WITH_TASKS" == true ]]; then
  [[ "$DRY_RUN" != true ]] && mkdir -p "$AGENTS_TASKS"
  install_bundle_primitive tasks "$AGENTS_TASKS"
fi
