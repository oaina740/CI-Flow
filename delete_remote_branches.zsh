#!/bin/zsh

# Delete unprotected remote branches from CI-Workflows
# Options:
#   -n  Dry-run (show branches to delete)
#   -f  Force (skip confirmation)
#   -r  Regex pattern to match branches (default: all except protected)

dry_run=false
force=false
pattern=".*"

while getopts "nfr:" opt; do
  case $opt in
    n) dry_run=true ;;
    f) force=true ;;
    r) pattern=$OPTARG ;;
    *) echo "Usage: $0 [-n] [-f] [-r pattern]"; exit 1 ;;
  esac
done

# Protected branches (case-insensitive)
protected=("main" "dev" "qa" "certification" "prod")

# Fetch and prune stale branches
git fetch CI-Workflows --prune

# Get remote branches, exclude protected ones
branches_to_delete=()
git branch -r --format="%(refname:short)" | 
  sed 's|CI-Workflows/||' | 
  grep -E "$pattern" |
  while read -r branch; do
    branch_lower=${branch:l}
    is_protected=false
    for p in $protected; do
      [[ $branch_lower == $p ]] && is_protected=true && break
    done
    $is_protected || branches_to_delete+=("$branch")
  done

# Exit if no branches to delete
[[ ${#branches_to_delete} -eq 0 ]] && echo "No branches to delete" && exit 0

# Show branches to delete
echo "Branches to delete:"
for branch in $branches_to_delete; do
  echo "  $branch"
done

# Confirm unless forced
if ! $dry_run && ! $force; then
  echo -n "Proceed? (y/n) "
  read -q
  echo
  [[ $REPLY != "y" ]] && exit 0
fi

# Delete branches
for branch in $branches_to_delete; do
  if $dry_run; then
    echo "[DRY-RUN] Would delete: CI-Workflows/$branch"
  else
    git push CI-Workflows --delete "$branch"
  fi
done
