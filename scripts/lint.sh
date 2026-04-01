#!/usr/bin/env bash
# Bash Strict Mode: https://github.com/guettli/bash-strict-mode
trap 'echo -e "\n🤷 🚨 🔥 Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0" 2>/dev/null || true) 🔥 🚨 🤷 "; exit 3' ERR
set -Eeuo pipefail

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: ./internal/lint.sh"
    echo ""
    echo "Run lint checks for tracked Markdown, YAML, and shell files."
    echo "Requires a nix dev shell."
    exit 0
fi

if [[ -z ${IN_NIX_SHELL:-} && -z ${DIRENV_DIR:-} ]]; then
    echo "Not in nix dev shell. Activate it first, for example: nix develop"
    exit 1
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
