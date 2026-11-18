#!/usr/bin/env bash
set -euo pipefail

# Bootstrap the same verified upstream packager for local use and CI.
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)

die() {
    printf 'Packager: %s\n' "$*" >&2
    exit 1
}

PACKAGER_VERSION= PACKAGER_COMMIT= RELEASE_SHA256= SETUP_SHA256=
# This repository-owned lock contains only the upstream version and digests.
source "$script_dir/packager.lock"
[[ $PACKAGER_VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][[:alnum:].-]+)?$ ]] || die 'Invalid version in packager.lock.'
[[ $PACKAGER_COMMIT =~ ^[0-9a-f]{40}$ ]] || die 'Invalid commit in packager.lock.'
[[ $RELEASE_SHA256 =~ ^[0-9a-f]{64}$ && $SETUP_SHA256 =~ ^[0-9a-f]{64}$ ]] || die 'Invalid SHA256 in packager.lock.'
command -v sha256sum >/dev/null || die 'sha256sum is required.'

cache_root=${XDG_CACHE_HOME:-${HOME:?Set HOME or XDG_CACHE_HOME.}/.cache}
cache_dir="$cache_root/wowefficiency-packager/$PACKAGER_COMMIT"
mkdir -p -- "$cache_dir"
download_dir=
cleanup() {
    if [[ -n $download_dir ]]; then
        rm -rf -- "$download_dir"
    fi
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

verify_file() {
    local actual
    [[ -f $2 ]] || return 1
    actual=$(sha256sum < "$2") || return 1
    [[ ${actual%% *} == "$1" ]]
}

fetch_script() {
    local name=$1 digest=$2
    if verify_file "$digest" "$cache_dir/$name"; then
        return
    fi
    command -v curl >/dev/null || die 'curl is required to download the pinned packager.'
    if [[ -z $download_dir ]]; then
        download_dir=$(mktemp -d "$cache_dir/.download.XXXXXXXX")
    fi
    curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
        "https://raw.githubusercontent.com/BigWigsMods/packager/$PACKAGER_COMMIT/$name" \
        --output "$download_dir/$name" || die "Could not download $name at $PACKAGER_COMMIT."
    verify_file "$digest" "$download_dir/$name" || die "SHA256 mismatch for $name; refusing to run it."
    mv -f -- "$download_dir/$name" "$cache_dir/$name"
}

fetch_script release.sh "$RELEASE_SHA256"
fetch_script setup-packager.sh "$SETUP_SHA256"
cleanup
download_dir=

# Upstream setup may install runner dependencies. Never run it on local machines.
if [[ -n ${GITHUB_ACTIONS:-} ]]; then
    INPUT_PANDOC=${INPUT_PANDOC:-false} INPUT_ARGS=${INPUT_ARGS-"$*"} \
        GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-$repo_root} bash "$cache_dir/setup-packager.sh"
fi

# Explicit caller options still take precedence over the repository default.
exec bash "$cache_dir/release.sh" -t "$repo_root" "$@"
