#!/bin/bash
# ============================================================================
# check-version.sh — Detect the latest Antigravity IDE version and URLs
# ============================================================================

set -euo pipefail

DOWNLOAD_PAGE="https://antigravity.google/download"
PAGE_CONTENT=$(curl -sL --compressed "$DOWNLOAD_PAGE" 2>/dev/null || true)

URL_X64=$(echo "$PAGE_CONTENT" | grep -oP 'href="[^"]*linux-x64[^"]*tar.gz[^"]*"' | grep "stable" | head -1 | cut -d'"' -f2)
URL_ARM64=$(echo "$PAGE_CONTENT" | grep -oP 'href="[^"]*linux-arm[^"]*tar.gz[^"]*"' | grep "stable" | head -1 | cut -d'"' -f2)

if [[ -z "$URL_X64" || -z "$URL_ARM64" ]]; then
    echo "ERROR: Could not find download URLs on $DOWNLOAD_PAGE" >&2
    exit 1
fi

NEW_VERSION=$(echo "$URL_X64" | grep -oP '\d+\.\d+\.\d+' | head -1)

if [[ -z "$NEW_VERSION" ]]; then
    echo "ERROR: Could not parse version from URL: $URL_X64" >&2
    exit 1
fi

echo "version=$NEW_VERSION"
echo "url_x64=$URL_X64"
echo "url_arm64=$URL_ARM64"
