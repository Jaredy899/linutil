#!/bin/bash

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check if a target is installed
check_target() {
    if ! rustup target list | grep -q "$1 (installed)"; then
        echo -e "${RED}Target $1 is not installed. Installing...${NC}"
        rustup target add $1
    fi
}

# Check and install required targets
check_target "aarch64-unknown-linux-musl"
check_target "armv7-unknown-linux-musleabihf"
check_target "x86_64-unknown-linux-musl"

# Create output directory
mkdir -p builds

# Build for each target
echo -e "${GREEN}Building for aarch64-musl...${NC}"
cargo build --target aarch64-unknown-linux-musl --release
cp target/aarch64-unknown-linux-musl/release/linutil builds/linutil-aarch64

echo -e "${GREEN}Building for armv7-musl...${NC}"
cargo build --target armv7-unknown-linux-musleabihf --release
cp target/armv7-unknown-linux-musleabihf/release/linutil builds/linutil-armv7l

echo -e "${GREEN}Building for x86_64-musl...${NC}"
cargo build --target x86_64-unknown-linux-musl --release
cp target/x86_64-unknown-linux-musl/release/linutil builds/linutil

echo -e "${GREEN}All builds completed! Binaries are in the 'builds' directory${NC}"
ls -lh builds/