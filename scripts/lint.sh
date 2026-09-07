#!/usr/bin/env bash
# Bash Strict Mode: https://github.com/guettli/bash-strict-mode
trap 'echo -e "\n🤷 🚨 🔥 Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0" 2>/dev/null || true) 🔥 🚨 🤷 "; exit 3' ERR
set -Eeuo pipefail

if [[ -z ${BSM_PROJECT_ROOT:-} ]]; then
    if [[ -n ${BSM_MISE_RETRY:-} ]]; then
        echo "mise env still not active. Did you run 'mise trust' in this repo?" >&2
        exit 1
    fi
    echo "mise env not active; re-running via mise"
    export BSM_MISE_RETRY=1
    exec mise -C "$(dirname -- "$(readlink -f -- "$0")")/.." exec -- "$0" "$@"
fi

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: ./internal/lint.sh"
    echo ""
    echo "Run lint checks for tracked Markdown, YAML, and shell files."
    echo "Requires the tools from mise.toml."
    exit 0
fi

mapfile -d '' markdown_files < <(git ls-files -z -- '*.md')
mapfile -d '' yaml_files < <(git ls-files -z -- '*.yml' '*.yaml')
mapfile -d '' shell_files < <(git ls-files -z -- '*.sh')

if [[ ${#markdown_files[@]} -eq 0 && ${#yaml_files[@]} -eq 0 && ${#shell_files[@]} -eq 0 ]]; then
    echo "No tracked Markdown, YAML, or shell files to lint."
    exit 0
fi

if [[ ${#markdown_files[@]} -gt 0 ]]; then
    echo "Running markdownlint..."
    markdownlint "${markdown_files[@]}"
fi

if [[ ${#yaml_files[@]} -gt 0 ]]; then
    echo "Running yamllint..."
    yamllint "${yaml_files[@]}"
fi

if [[ ${#shell_files[@]} -gt 0 ]]; then
    echo "Running shellcheck..."
    shellcheck "${shell_files[@]}"
fi
