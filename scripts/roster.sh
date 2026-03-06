#!/bin/bash
# roster.sh — Browse and load agency agent definitions
set -euo pipefail

AGENCY_DIR="$HOME/.openclaw/workspace/agency-agents"

usage() {
  echo "Usage: roster.sh [command] [args]"
  echo ""
  echo "Commands:"
  echo "  list              List all available agents by division"
  echo "  load <path>       Print an agent definition (e.g., ventures/deal-analyst)"
  echo "  search <keyword>  Search agents by keyword in name/description"
  echo "  divisions         List all divisions"
  echo ""
  echo "Examples:"
  echo "  roster.sh list"
  echo "  roster.sh load ventures/deal-analyst"
  echo "  roster.sh search tokenomics"
}

cmd_list() {
  echo "=== Agency Roster ==="
  echo ""
  for div in "$AGENCY_DIR"/*/; do
    [ -d "$div" ] || continue
    divname=$(basename "$div")
    # Skip non-agent directories
    [[ "$divname" == "scripts" || "$divname" == "examples" || "$divname" == ".git" ]] && continue
    
    count=$(find "$div" -maxdepth 1 -name "*.md" ! -name "README*" ! -name "CONTRIBUTING*" ! -name "QUICKSTART*" ! -name "EXECUTIVE*" | wc -l | tr -d ' ')
    [ "$count" -eq 0 ] && continue
    
    echo "[$divname] ($count agents)"
    for agent in "$div"*.md; do
      [ -f "$agent" ] || continue
      fname=$(basename "$agent" .md)
      [[ "$fname" == "README" || "$fname" == "CONTRIBUTING" || "$fname" == "QUICKSTART" || "$fname" == "EXECUTIVE-BRIEF" || "$fname" == "nexus-strategy" ]] && continue
      # Extract name from frontmatter
      name=$(grep -m1 "^name:" "$agent" 2>/dev/null | sed 's/name: *//' || echo "$fname")
      desc=$(grep -m1 "^description:" "$agent" 2>/dev/null | sed 's/description: *//' | head -c 80 || echo "")
      printf "  %-35s %s\n" "$divname/$fname" "$name"
    done
    echo ""
  done
}

cmd_load() {
  local path="$1"
  # Add .md extension if not present
  [[ "$path" != *.md ]] && path="${path}.md"
  local fullpath="$AGENCY_DIR/$path"
  
  if [ -f "$fullpath" ]; then
    cat "$fullpath"
  else
    echo "ERROR: Agent not found at $fullpath"
    echo "Use 'roster.sh list' to see available agents"
    exit 1
  fi
}

cmd_search() {
  local keyword="$1"
  echo "Searching for '$keyword'..."
  echo ""
  grep -ril "$keyword" "$AGENCY_DIR" --include="*.md" 2>/dev/null | while read -r file; do
    rel=$(echo "$file" | sed "s|$AGENCY_DIR/||")
    [[ "$rel" == "README.md" || "$rel" == "CONTRIBUTING.md" || "$rel" == "LICENSE" ]] && continue
    name=$(grep -m1 "^name:" "$file" 2>/dev/null | sed 's/name: *//' || basename "$file" .md)
    printf "  %-40s %s\n" "$rel" "$name"
  done
}

cmd_divisions() {
  for div in "$AGENCY_DIR"/*/; do
    [ -d "$div" ] || continue
    divname=$(basename "$div")
    [[ "$divname" == "scripts" || "$divname" == "examples" || "$divname" == ".git" ]] && continue
    count=$(find "$div" -maxdepth 1 -name "*.md" ! -name "README*" | wc -l | tr -d ' ')
    [ "$count" -eq 0 ] && continue
    echo "$divname ($count agents)"
  done
}

case "${1:-list}" in
  list) cmd_list ;;
  load) cmd_load "${2:?Agent path required (e.g., ventures/deal-analyst)}" ;;
  search) cmd_search "${2:?Keyword required}" ;;
  divisions) cmd_divisions ;;
  -h|--help|help) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
