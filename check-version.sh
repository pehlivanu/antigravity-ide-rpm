#!/bin/bash
# ============================================================================
# check-version.sh — Detect the latest Antigravity IDE version
# ============================================================================
# This script checks for the latest available version of Antigravity IDE
# by downloading the tarball headers or the download page from
# antigravity.google.
#
# Usage:
#   ./check-version.sh [current-version]
#
# Output (on stdout):
#   If a newer version is available:  NEW_VERSION DOWNLOAD_URL
#   If already up-to-date:            (nothing, exit 0)
#   On error:                         (error message on stderr, exit 1)
#
# Exit codes:
#   0 — success (check output for version info)
#   1 — error
# ============================================================================

set -euo pipefail

SPEC_FILE="$(dirname "$0")/antigravity-ide.spec"
DOWNLOAD_PAGE="https://antigravity.google/download"

# ---- Determine the current packaged version ----
if [[ -n "${1:-}" ]]; then
    CURRENT_VERSION="$1"
elif [[ -f "$SPEC_FILE" ]]; then
    CURRENT_VERSION=$(grep -m1 '^Version:' "$SPEC_FILE" | awk '{print $2}')
else
    CURRENT_VERSION="0.0.0"
fi

echo "Current packaged version: $CURRENT_VERSION" >&2

# ---- Strategy 1: Try known download URL pattern with HEAD request ----
# Google often uses a redirect from a stable URL. We try to follow redirects
# and extract version from the final filename.
detect_from_redirect() {
    local url="$1"
    local final_url
    final_url=$(curl -sIL -o /dev/null -w '%{url_effective}' "$url" 2>/dev/null || true)

    if [[ -n "$final_url" ]]; then
        # Try to extract version from URL like:
        #   .../Antigravity-2.1.2-linux-x64.tar.gz
        #   .../antigravity-ide-2.1.2.tar.gz
        local version
        version=$(echo "$final_url" | grep -oP '[\d]+\.[\d]+\.[\d]+' | head -1 || true)
        if [[ -n "$version" ]]; then
            echo "$version $final_url"
            return 0
        fi
    fi
    return 1
}

# ---- Strategy 2: Scrape the download page for version info ----
detect_from_page() {
    local page_content
    page_content=$(curl -sL "$DOWNLOAD_PAGE" 2>/dev/null || true)

    if [[ -z "$page_content" ]]; then
        return 1
    fi

    # Look for version numbers in download links
    local version
    version=$(echo "$page_content" | grep -oP 'Antigravity[^"]*?(\d+\.\d+\.\d+)' | grep -oP '\d+\.\d+\.\d+' | head -1 || true)

    if [[ -z "$version" ]]; then
        # Fallback: look for any semver-like string near "download" or "linux"
        version=$(echo "$page_content" | grep -oP '(?:version|Version|ver)["\s:=]+(\d+\.\d+\.\d+)' | grep -oP '\d+\.\d+\.\d+' | head -1 || true)
    fi

    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi

    return 1
}

# ---- Strategy 3: Check the update endpoint (VS Code-compatible) ----
detect_from_update_api() {
    # Antigravity is a VS Code fork, so it may use a similar update API
    local api_urls=(
        "https://update.antigravity.google/api/update/linux-x64/stable/latest"
        "https://antigravity.google/api/update/linux-x64/stable/latest"
    )

    for api_url in "${api_urls[@]}"; do
        local response
        response=$(curl -sL --max-time 10 "$api_url" 2>/dev/null || true)
        if [[ -n "$response" ]]; then
            local version
            version=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('productVersion', d.get('version', '')))" 2>/dev/null || true)
            if [[ -n "$version" ]]; then
                local url
                url=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('url',''))" 2>/dev/null || true)
                echo "$version $url"
                return 0
            fi
        fi
    done
    return 1
}

# ---- Strategy 4: Check installed version's product.json for update URL ----
detect_from_product_json() {
    local product_json="/opt/antigravity-ide/resources/app/product.json"
    if [[ -f "$product_json" ]]; then
        local ide_version
        ide_version=$(python3 -c "import json; d=json.load(open('$product_json')); print(d.get('ideVersion',''))" 2>/dev/null || true)
        if [[ -n "$ide_version" ]]; then
            echo "$ide_version"
            return 0
        fi
    fi
    return 1
}

# ---- Run detection strategies in order ----
RESULT=""

# Try each strategy
for strategy in detect_from_redirect detect_from_page detect_from_update_api; do
    RESULT=$($strategy "$DOWNLOAD_PAGE" 2>/dev/null || true)
    if [[ -n "$RESULT" ]]; then
        break
    fi
done

# Last resort: check locally installed version
if [[ -z "$RESULT" ]]; then
    RESULT=$(detect_from_product_json 2>/dev/null || true)
fi

if [[ -z "$RESULT" ]]; then
    echo "ERROR: Could not determine latest version." >&2
    exit 1
fi

# Parse the result
NEW_VERSION=$(echo "$RESULT" | awk '{print $1}')
DOWNLOAD_URL=$(echo "$RESULT" | awk '{print $2}')

echo "Latest available version: $NEW_VERSION" >&2

# ---- Compare versions ----
version_gt() {
    # Returns 0 (true) if $1 > $2
    printf '%s\n%s' "$1" "$2" | sort -V | head -1 | grep -qv "^$1$"
}

if version_gt "$NEW_VERSION" "$CURRENT_VERSION"; then
    echo "Update available: $CURRENT_VERSION → $NEW_VERSION" >&2
    echo "$NEW_VERSION $DOWNLOAD_URL"
    exit 0
else
    echo "Already up-to-date ($CURRENT_VERSION)." >&2
    exit 0
fi
