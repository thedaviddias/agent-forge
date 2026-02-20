#!/usr/bin/env bash
# Scaffold a new bundle category with standard folders (skills, rules, commands, agents, tasks).
# Usage: ./scaffold-category.sh <category-name>
# Example: ./scaffold-category.sh my-domain

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <category-name>"
  echo "  Creates a new bundle with: skills/, rules/, commands/, agents/, tasks/ (each with .gitkeep if empty)"
  exit 1
fi

NAME="$1"
# Sanitize: no spaces (use - or _)
NAME="${NAME// /-}"

ROOT="$(cd "$(dirname "$0")" && pwd -P)"
CAT="$ROOT/$NAME"

if [[ -d "$CAT" ]]; then
  echo "Category '$NAME' already exists at $CAT"
  echo "Creating any missing bundle folders..."
else
  echo "Creating category: $NAME"
  mkdir -p "$CAT"
fi

for dir in skills rules commands agents tasks; do
  SUB="$CAT/$dir"
  if [[ ! -d "$SUB" ]]; then
    mkdir -p "$SUB"
    touch "$SUB/.gitkeep"
    echo "  + $NAME/$dir/"
  else
    if [[ -z "$(ls -A "$SUB" 2>/dev/null)" ]]; then
      touch "$SUB/.gitkeep"
    fi
  fi
done

echo "Done. Add skills under $NAME/skills/<skill-name>/ with a SKILL.md file."
