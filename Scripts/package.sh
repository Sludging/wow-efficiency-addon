#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s <retail|forever> [output-dir]\n' "${0##*/}"
}

if [[ $# -eq 1 && ( $1 == -h || $1 == --help ) ]]; then
    usage
    exit 0
fi
if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage >&2
    exit 1
fi
case $1 in
    retail|forever) edition=$1 ;;
    *) printf 'Unsupported edition: %s\n' "$1" >&2; usage >&2; exit 1 ;;
esac

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
output_dir=${2-"$repo_root/../wow-efficiency-addon-artifacts/$edition"}
if [[ -z $output_dir || $output_dir == -* ]]; then
    printf 'Invalid output directory: %s\n' "$output_dir" >&2
    exit 1
fi
# Resolve relative output paths against the caller's working directory.
case $output_dir in
    /*) ;;
    *) output_dir="$PWD/$output_dir" ;;
esac

# Upstream clears its staging directory and replaces the ZIP on each run.
exec bash "$script_dir/release.sh" -d -l -u -g "$edition" -t "$repo_root" -r "$output_dir"
