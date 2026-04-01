#!/usr/bin/env bash
#
# Source: https://github.com/guettli/git-tips
#
# Bash Strict Mode: https://github.com/guettli/bash-strict-mode
trap 'echo -e "\n🤷 🚨 🔥 Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0" 2>/dev/null || true) 🔥 🚨 🤷 "; exit 3' ERR
set -Eeuo pipefail

usage() {
    echo "Usage: ./scripts/git-worktree-has-changed.sh [--touch-stamp] <name> <path-in-repo>"
    echo ""
    echo "Check whether files in a git worktree path changed since the last successful run of an expensive task."
    echo "The script derives an implicit stamp file in .tmp/ from the repo root, the given name, and the given path."
    echo ""
    echo "Default mode exits 0 if no tracked or untracked, non-ignored file under <path-in-repo> is newer than its implicit stamp file."
    echo "--touch-stamp creates or updates the implicit stamp file."
    echo "<name> is required so multiple independent tasks can track the same path."
    echo ""
    echo "Developed for https://taskfile.dev/"
    echo
    echo "Example: Taskfile.yaml:"
    cat <<'EOF'

version: "3"
tasks:
  foo:
    status:
      - bash ./scripts/git-worktree-has-changed.sh foo .
    cmds:
      - bash ./internal/foo.sh
      - bash ./scripts/git-worktree-has-changed.sh --touch-stamp foo .
EOF
}

sanitize_name() {
    printf '%s' "$1" | sed 's/[^[:alnum:]._-]/_/g'
}

resolve_context() {
    task_name="$1"
    scan_path=$(cd "$2" && pwd -P)
    git_root=$(git -C "$scan_path" rev-parse --show-toplevel)
    repo_relative_path=$(git -C "$scan_path" rev-parse --show-prefix)
    repo_relative_path=${repo_relative_path:-.}
    safe_task_name=$(sanitize_name "$task_name")
    stamp_hash=$(printf '%s\0%s' "$git_root" "$repo_relative_path" | sha256sum | cut -d' ' -f1)
    stamp=$git_root/.tmp/worktree-has-changed-$safe_task_name-$stamp_hash.stamp
}

mode=check
case "${1:-}" in
--help | -h)
    usage
    exit 0
    ;;
--touch-stamp)
    mode=touch_stamp
    shift
    ;;
esac

if [[ $# -ne 2 ]]; then
    usage >&2
    exit 2
fi

resolve_context "$1" "$2"

case "$mode" in
touch_stamp)
    mkdir -p "$(dirname "$stamp")"
    touch "$stamp"
    exit 0
    ;;
esac

cd "$git_root"

if [[ ! -f "$stamp" ]]; then
    exit 1
fi

while IFS= read -r -d '' file; do
    if [[ ! -e "$file" || "$file" -nt "$stamp" ]]; then
        exit 1
    fi
done < <(
    git ls-files -z --cached --others --exclude-standard -- "$repo_relative_path"
)
