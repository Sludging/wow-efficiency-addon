#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s <version-tag>\nExample: %s v2.6.1\n' "${0##*/}" "${0##*/}"
}
die() {
    printf 'Packager update: %s\n' "$*" >&2
    exit 1
}

if [[ $# -eq 1 && ( $1 == -h || $1 == --help ) ]]; then
    usage
    exit 0
fi
if [[ $# -ne 1 ]]; then
    usage >&2
    exit 1
fi
version=$1
[[ $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][[:alnum:].-]+)?$ ]] || die "Unsupported version tag: $version (expected vMAJOR.MINOR.PATCH)."
for tool in git curl sha256sum mktemp; do
    command -v "$tool" >/dev/null || die "$tool is required."
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
upstream=https://github.com/BigWigsMods/packager.git
refs=$(git ls-remote --exit-code "$upstream" "refs/tags/$version" "refs/tags/$version^{}") \
    || die "Could not resolve upstream tag $version."
commit=
while IFS=$'\t' read -r sha ref; do
    case $ref in
        "refs/tags/$version") [[ -n $commit ]] || commit=$sha ;;
        "refs/tags/$version^{}") commit=$sha ;;
    esac
done <<< "$refs"
[[ $commit =~ ^[0-9a-f]{40}$ ]] || die "No commit found for upstream tag $version."

# Keep all downloads beside the lock so its final replacement is atomic.
download_dir=$(mktemp -d "$script_dir/.packager-update.XXXXXXXX")
trap 'rm -rf -- "$download_dir"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
for name in release.sh setup-packager.sh; do
    curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
        "https://raw.githubusercontent.com/BigWigsMods/packager/$commit/$name" \
        --output "$download_dir/$name" || die "Could not download $name at $commit; lock unchanged."
done
release_sha=$(sha256sum < "$download_dir/release.sh")
setup_sha=$(sha256sum < "$download_dir/setup-packager.sh")
printf 'PACKAGER_VERSION=%s\nPACKAGER_COMMIT=%s\nRELEASE_SHA256=%s\nSETUP_SHA256=%s\n' \
    "$version" "$commit" "${release_sha%% *}" "${setup_sha%% *}" > "$download_dir/packager.lock"
chmod 644 "$download_dir/packager.lock"
mv -f -- "$download_dir/packager.lock" "$script_dir/packager.lock"
printf 'Pinned BigWigsMods/packager %s (%s).\n' "$version" "$commit"
