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
CLEAN=false
ALL_BUNDLES=false
PROJECT_DIR=""
BUNDLES=""
PROJECT_ONLY=false
WITH_MCP=false
WITH_RULES=false
WITH_AGENTS=false
WITH_HOOKS=false
WITH_COMMANDS=false
WITH_TASKS=false
while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    --force)          FORCE=true; shift ;;
    --dry-run)        DRY_RUN=true; shift ;;
    --clean)          CLEAN=true; shift ;;
    --all-bundles)    ALL_BUNDLES=true; shift ;;
    --project)
      PROJECT_DIR="${2:-}"; shift 2
      ;;
    --project=*)
      PROJECT_DIR="${arg#*=}"; shift
      ;;
    --bundles)
      BUNDLES="${2:-}"; shift 2
      ;;
    --bundles=*)
      BUNDLES="${arg#*=}"; shift
      ;;
    --project-only)   PROJECT_ONLY=true; shift ;;
    --all)            WITH_MCP=true; WITH_RULES=true; WITH_AGENTS=true; WITH_HOOKS=true; WITH_COMMANDS=true; WITH_TASKS=true; shift ;;
    --with-mcp)       WITH_MCP=true; shift ;;
    --with-rules)     WITH_RULES=true; shift ;;
    --with-agents)    WITH_AGENTS=true; shift ;;
    --with-hooks)     WITH_HOOKS=true; shift ;;
    --with-commands)  WITH_COMMANDS=true; shift ;;
    --with-tasks)     WITH_TASKS=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--force] [--dry-run] [--clean] [--all-bundles] [--project DIR --bundles b1,b2] [--project-only] [--all | --with-mcp | ...]"
      echo "  --force          Overwrite existing symlinks and replace real directories in ~/.agents/skills (or project dir)"
      echo "  --dry-run        Print actions without creating or changing anything"
      echo "  --clean          Remove skills in ~/.agents/skills (and tool dirs) that are not in the current install set"
      echo "  --all-bundles    Install skills from all bundles globally (default: only global/ bundle)"
      echo "  --project DIR   Install selected bundles into DIR/.cursor/skills (and .claude/skills, .codex/skills)"
      echo "  --bundles b1,b2  Comma-separated bundle names for --project (e.g. web,marketing)"
      echo "  --project-only   Only run per-project install (skip all global ~/.agents writes)"
      echo "  --all            Install all primitives (skills + rules + MCP + agents + hooks + commands + tasks)"
      echo "  --with-mcp       Also install MCP configs to ~/.agents/mcp.d/ and merge to ~/.agents/mcp.json"
      echo "  --with-rules     Also install bundle rules to ~/.agents/rules/"
      echo "  --with-agents    Also install bundle agents to ~/.agents/agents/"
      echo "  --with-hooks     Also install bundle hooks to ~/.agents/hooks/"
      echo "  --with-commands  Also install bundle commands to ~/.agents/commands/"
      echo "  --with-tasks     Also install bundle tasks to ~/.agents/tasks/"
      echo ""
      echo "By default only global/ skills are installed to ~/.agents/skills and tool dirs. Use --all-bundles for all bundles."
      echo "Use --project DIR --bundles web,marketing to install those bundles into a project's .cursor/skills."
      echo "Existing same-name: skip unless --force. Use --clean to leave only repo skills in the current install set."
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2; exit 1
      ;;
  esac
done

FORGE_ROOT="$(abspath "$(dirname "$0")")"

if [[ -n "$PROJECT_DIR" && -z "$BUNDLES" ]]; then
  echo "Error: --project requires --bundles (e.g. --project . --bundles web,marketing)." >&2
  exit 1
fi

if [[ -z "$PROJECT_DIR" && -n "$BUNDLES" ]]; then
  echo "Error: --bundles requires --project." >&2
  exit 1
fi

if [[ "$PROJECT_ONLY" == true ]]; then
  if [[ -z "$PROJECT_DIR" || -z "$BUNDLES" ]]; then
    echo "Error: --project-only requires both --project and --bundles." >&2
    exit 1
  fi
  if [[ "$CLEAN" == true || "$ALL_BUNDLES" == true || "$WITH_MCP" == true || "$WITH_RULES" == true || "$WITH_AGENTS" == true || "$WITH_HOOKS" == true || "$WITH_COMMANDS" == true || "$WITH_TASKS" == true ]]; then
    echo "Error: --project-only cannot be combined with global install flags (--clean, --all-bundles, --all, --with-*)." >&2
    exit 1
  fi
fi

if [[ -n "$BUNDLES" ]]; then
  CHECK_AVAILABLE_BUNDLES=()
  for category in "$FORGE_ROOT"/*/; do
    [[ -d "${category}skills" ]] || continue
    CHECK_AVAILABLE_BUNDLES+=( "$(basename "$category")" )
  done

  CHECK_UNKNOWN_BUNDLES=()
  IFS=',' read -ra CHECK_BUNDLE_LIST <<< "$BUNDLES"
  for bundle in "${CHECK_BUNDLE_LIST[@]}"; do
    bundle="${bundle// /}"
    [[ -z "$bundle" ]] && continue
    if [[ ! -d "$FORGE_ROOT/$bundle/skills" ]]; then
      CHECK_UNKNOWN_BUNDLES+=( "$bundle" )
    fi
  done

  if [[ ${#CHECK_UNKNOWN_BUNDLES[@]} -gt 0 ]]; then
    echo ""
    echo "Unknown bundles requested:"
    for bundle in "${CHECK_UNKNOWN_BUNDLES[@]}"; do
      echo "  - $bundle"
    done
    echo ""
    echo "Available bundles:"
    for bundle in "${CHECK_AVAILABLE_BUNDLES[@]}"; do
      echo "  - $bundle"
    done
    exit 1
  fi
fi

# Discover all skills: (skill_name,category) pairs, first category wins if duplicate name
# Default: only global/ bundle. Use --all-bundles to install every bundle globally.
SKILL_NAMES=()
SKILL_CATEGORIES=()
if [[ "$PROJECT_ONLY" != true ]]; then
  if [[ "$ALL_BUNDLES" == true ]]; then
    CATEGORIES_TO_SCAN=("$FORGE_ROOT"/*/)
  else
    CATEGORIES_TO_SCAN=("$FORGE_ROOT/global/")
  fi
  for category in "${CATEGORIES_TO_SCAN[@]}"; do
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
fi

linked=0
skipped=0
warned=0

if [[ "$PROJECT_ONLY" != true ]]; then
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

  # --- Clean: remove skills not in current install set (--clean) ---
  if [[ "$CLEAN" == true ]]; then
    cleaned_agents=0
    cleaned_tools=0
    for entry in "$AGENTS_SKILLS"/*; do
      [[ -e "$entry" ]] || continue
      name=$(basename "$entry")
      in_list=false
      for ((i=0; i<${#SKILL_NAMES[@]}; i++)); do
        [[ "${SKILL_NAMES[$i]}" == "$name" ]] && { in_list=true; break; }
      done
      keep=false
      if [[ "$in_list" == true ]]; then
        if [[ -L "$entry" ]]; then
          dest=$(readlink "$entry")
          if [[ "$dest" == /* ]]; then
            [[ "$dest" == "$FORGE_ROOT"/* ]] && keep=true
          else
            resolved=$(cd "$AGENTS_SKILLS" && cd "$dest" 2>/dev/null && pwd -P) || true
            [[ -n "$resolved" && "$resolved" == "$FORGE_ROOT"/* ]] && keep=true
          fi
        fi
      fi
      if [[ "$keep" != true ]]; then
        if [[ "$DRY_RUN" == true ]]; then
          echo "[dry-run] would remove (not from repo): $entry"
        else
          rm -rf "$entry"
          echo "removed: $name"
        fi
        ((cleaned_agents++)) || true
      fi
    done
    for tool in "${TOOL_DIRS[@]}"; do
      [[ -d "$tool" ]] || continue
      for entry in "$tool"/*; do
        [[ -e "$entry" ]] || continue
        name=$(basename "$entry")
        in_list=false
        for ((i=0; i<${#SKILL_NAMES[@]}; i++)); do
          [[ "${SKILL_NAMES[$i]}" == "$name" ]] && { in_list=true; break; }
        done
        if [[ "$in_list" != true ]]; then
          if [[ "$DRY_RUN" == true ]]; then
            echo "[dry-run] would remove from tool: $entry"
          else
            rm -rf "$entry"
            echo "removed from $(basename "$tool"): $name"
          fi
          ((cleaned_tools++)) || true
        fi
      done
    done
    echo "Clean: $cleaned_agents from ~/.agents/skills, $cleaned_tools from tool dirs"
  fi

  echo ""
  echo "Summary: linked=$linked skipped=$skipped warned=$warned"
fi

# --- Per-project install: --project DIR --bundles b1,b2 ---
if [[ -n "$PROJECT_DIR" && -n "$BUNDLES" ]]; then
  PROJECT_ROOT="$(abspath "$PROJECT_DIR")"
  PROJECT_TOOL_DIRS=( "$PROJECT_ROOT/.cursor/skills" "$PROJECT_ROOT/.claude/skills" "$PROJECT_ROOT/.codex/skills" )
  AVAILABLE_BUNDLES=()
  for category in "$FORGE_ROOT"/*/; do
    [[ -d "${category}skills" ]] || continue
    AVAILABLE_BUNDLES+=( "$(basename "$category")" )
  done
  PROJ_SKILL_NAMES=()
  PROJ_SKILL_CATEGORIES=()
  UNKNOWN_BUNDLES=()
  IFS=',' read -ra BUNDLE_LIST <<< "$BUNDLES"
  for bundle in "${BUNDLE_LIST[@]}"; do
    bundle="${bundle// /}"
    [[ -z "$bundle" ]] && continue
    category="$FORGE_ROOT/$bundle"
    if [[ ! -d "$category/skills" ]]; then
      UNKNOWN_BUNDLES+=( "$bundle" )
      continue
    fi
    for skill_dir in "$category/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      [ -f "${skill_dir}SKILL.md" ] || continue
      skill_name="$(basename "$skill_dir")"
      for skip in "${SKIP_SKILLS[@]}"; do
        [[ "$skill_name" == "$skip" ]] && continue 2
      done
      seen=false
      for ((j=0; j<${#PROJ_SKILL_NAMES[@]}; j++)); do
        [[ "${PROJ_SKILL_NAMES[$j]}" == "$skill_name" ]] && { seen=true; break; }
      done
      if [[ "$seen" != true ]]; then
        PROJ_SKILL_NAMES+=( "$skill_name" )
        PROJ_SKILL_CATEGORIES+=( "$bundle" )
      fi
    done
  done
  if [[ ${#UNKNOWN_BUNDLES[@]} -gt 0 ]]; then
    echo ""
    echo "Unknown bundles requested:"
    for bundle in "${UNKNOWN_BUNDLES[@]}"; do
      echo "  - $bundle"
    done
    echo ""
    echo "Available bundles:"
    for bundle in "${AVAILABLE_BUNDLES[@]}"; do
      echo "  - $bundle"
    done
    exit 1
  fi
  if [[ "$DRY_RUN" != true ]]; then
    for tool in "${PROJECT_TOOL_DIRS[@]}"; do
      mkdir -p "$tool"
    done
  fi
  proj_linked=0
  proj_skipped=0
  proj_warned=0
  for ((i=0; i<${#PROJ_SKILL_NAMES[@]}; i++)); do
    skill_name="${PROJ_SKILL_NAMES[$i]}"
    category="${PROJ_SKILL_CATEGORIES[$i]}"
    source_dir="$FORGE_ROOT/$category/skills/$skill_name"
    for tool in "${PROJECT_TOOL_DIRS[@]}"; do
      target="$tool/$skill_name"
      if [[ -L "$target" ]]; then
        if [[ "$FORCE" == true ]]; then
          if [[ "$DRY_RUN" == true ]]; then
            echo "[dry-run] would overwrite project symlink: $target -> $source_dir"
          else
            rm "$target"
            ln -s "$source_dir" "$target"
          fi
          ((proj_linked++)) || true
        else
          ((proj_skipped++)) || true
        fi
      elif [[ -d "$target" ]]; then
        if [[ "$FORCE" == true ]]; then
          if [[ "$DRY_RUN" == true ]]; then
            echo "[dry-run] would replace with project symlink: $target -> $source_dir"
          else
            rm -r "$target"
            ln -s "$source_dir" "$target"
          fi
          ((proj_linked++)) || true
        else
          ((proj_warned++)) || true
        fi
      else
        if [[ "$DRY_RUN" == true ]]; then
          echo "[dry-run] would link project: $target -> $source_dir"
        else
          ln -s "$source_dir" "$target"
        fi
        ((proj_linked++)) || true
      fi
    done
  done
  echo "Project $PROJECT_ROOT: linked=$proj_linked skipped=$proj_skipped warned=$proj_warned"
fi

# --- Optional primitives (bundles: rules, MCP, agents, hooks) ---

dir_has_non_gitkeep_files() {
  local dir="$1"
  find "$dir" -type f ! -name ".gitkeep" -print -quit | grep -q .
}

install_bundle_primitive() {
  local kind="$1"    # mcp, rules, agents, commands, tasks
  local dest_base="$2"
  local count=0
  local skipped_empty=0
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
    if [[ "$kind" == "rules" || "$kind" == "agents" || "$kind" == "commands" || "$kind" == "tasks" ]]; then
      if ! dir_has_non_gitkeep_files "$src"; then
        if [[ "$DRY_RUN" == true ]]; then
          echo "[dry-run] skip empty $kind bundle: $name"
        else
          echo "skip empty $kind bundle: $name"
        fi
        ((skipped_empty++)) || true
        continue
      fi
    fi
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
  if [[ "$skipped_empty" -gt 0 ]]; then
    echo "$kind: skipped $skipped_empty empty bundle(s)"
  fi
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
