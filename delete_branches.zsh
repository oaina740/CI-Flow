#!/bin/zsh

# Script to delete local branches not matching protected names (case-insensitive)
# Protected branches: dev, QA, certification, prod
# Options: 
#   -n  Dry-run (show what would be deleted)
#   -f  Force delete unmerged branches

dry_run=false
force=false

while getopts "nf" opt; do
  case $opt in
    n) dry_run=true ;;
    f) force=true ;;
    *) echo "Usage: $0 [-n] [-f]"; exit 1 ;;
  esac
done

# Get current branch (empty if detached HEAD)
current_branch=$(git branch --show-current)

# Identify branches to delete
git branch --format='%(refname:short)' | while read -r branch; do
  # Skip current branch
  [[ -n "$current_branch" && "$branch" == "$current_branch" ]] && continue

  # Case-insensitive check for protected branches
  branch_lower=$(tr '[:upper:]' '[:lower:]' <<< "$branch")
  case "$branch_lower" in
    dev|qa|certification|prod) 
      continue 
      ;;
  esac

  # Delete branch (or dry-run)
  if $dry_run; then
    echo "Would delete: $branch"
  else
    if $force; then
      git branch -D "$branch"
    else
      git branch -d "$branch"
    fi
  fi
done
