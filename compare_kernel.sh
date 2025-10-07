#!/usr/bin/env bash

# === RHEL 9 BrewRoot kernel-automotive ===
BREW_URL="https://download-01.beak-001.prod.iad2.dc.redhat.com/brewroot/vol/rhel-9/packages/kernel-automotive/"

# Fetch HTML content and get the version directory (e.g., 5.14.0)
version_dir=$(curl -s "$BREW_URL" | grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+/' | sed 's:/$::')

if [ -z "$version_dir" ]; then
    echo "Could not find version directory in BrewRoot URL."
    exit 1
fi

# Build URL for the version directory
VERSION_URL="${BREW_URL}${version_dir}/"

# Fetch subdirectories and get the latest
subdirs=$(curl -s "$VERSION_URL" | grep -oP '(?<=href=")[^"/]+/' | sed 's:/$::')
latest_brew_dir=$(echo "$subdirs" | sort -V | tail -n1)

# Remove .el9iv suffix
latest_brew_dir_clean=$(echo "$latest_brew_dir" | sed 's/\.el9iv$//')

# Compose BrewRoot full version in same format as CentOS (replace / with -)
BREW_VERSION="${version_dir}-${latest_brew_dir_clean}"
echo "BrewRoot latest version: $BREW_VERSION"

# === CentOS Stream 9 kernel RPM ===
MIRROR_URL="https://mirror.stream.centos.org/SIGs/9-stream/autosd/x86_64/packages-main/Packages/k/"

html_content=$(curl -s "$MIRROR_URL")
latest_rpm=$(echo "$html_content" \
    | grep -oP 'href="kernel-automotive-[0-9][^"]*\.rpm"' \
    | awk -F'"' '{print $2}' \
    | sort -V \
    | tail -n 1)

if [ -n "$latest_rpm" ]; then
    latest_url="${MIRROR_URL}${latest_rpm}"
    echo "CentOS Stream latest RPM: $latest_url"

    # Extract version (X.Y.Z-ABC)
    MIRROR_VERSION=$(echo "$latest_rpm" | sed -E 's/^kernel-automotive-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.[0-9]+)\..*\.rpm$/\1/')
    echo "CentOS Stream version: $MIRROR_VERSION"
else
    echo "No kernel-automotive RPM found in mirror."
    exit 1
fi

# === Compare versions ===
if [ "$BREW_VERSION" != "$MIRROR_VERSION" ]; then
    echo "WARNING: Versions do not match!"
    echo "BrewRoot: $BREW_VERSION"
    echo "CentOS Stream: $MIRROR_VERSION"
else
    echo "Versions match: $BREW_VERSION"
fi

