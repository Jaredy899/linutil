#!/bin/bash

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check if a package is installed
check_package() {
    if ! dpkg -l "$1" &> /dev/null; then
        echo -e "${RED}Package $1 is not installed. Installing...${NC}"
        sudo apt-get install -y "$1"
    fi
}

# Function to check if a target is installed
check_target() {
    if ! rustup target list | grep -q "$1 (installed)"; then
        echo -e "${RED}Target $1 is not installed. Installing...${NC}"
        rustup target add $1
    fi
}

# Function to check if Rust is installed
check_rust() {
    if ! command -v rustc &> /dev/null; then
        echo -e "${RED}Rust is not installed. Installing...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
    fi
}

# Check for Rust installation
echo -e "${GREEN}Checking for Rust installation...${NC}"
check_rust

# Check for required packages
echo -e "${GREEN}Checking required packages...${NC}"
sudo apt-get update
check_package "build-essential"
check_package "musl-tools"
check_package "musl-dev"
check_package "gcc-aarch64-linux-gnu"
check_package "gcc-arm-linux-gnueabihf"
check_package "libc6-dev-arm64-cross"
check_package "libc6-dev-armhf-cross"

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