#!/bin/sh -e

eval "$(curl -s https://raw.githubusercontent.com/Jaredy899/linux/refs/heads/main/common_script.sh)"

installGhostty() {
    printf "%b\n" "${YELLOW}Installing Ghostty...${RC}"
    
    # Check if already installed
    if command_exists ghostty; then
        printf "%b\n" "${GREEN}Ghostty is already installed.${RC}"
        exit 0
    fi

    case "$PACKAGER" in
        pacman)
            # Arch has an official package
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ghostty
            printf "%b\n" "${GREEN}Installed successfully.${RC}"
            ;;
        dnf)
            # Fedora has COPR packages
            printf "%b\n" "-----------------------------------------------------"
            printf "%b\n" "Select the package source:"
            printf "%b\n" "1. ${CYAN}COPR repository${RC}"
            printf "%b\n" "2. ${CYAN}Terra repository${RC}"
            printf "%b\n" "3. ${CYAN}Build from source${RC}"
            printf "%b\n" "-----------------------------------------------------"
            printf "%b" "Enter your choice: "
            read -r choice
            case $choice in
                1)
                    "$ESCALATION_TOOL" "$PACKAGER" copr enable -y pgdev/ghostty
                    "$ESCALATION_TOOL" "$PACKAGER" install -y ghostty
                    ;;
                2)
                    "$ESCALATION_TOOL" "$PACKAGER" install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
                    "$ESCALATION_TOOL" "$PACKAGER" install -y ghostty
                    ;;
                3)
                    buildFromSource
                    ;;
                *)
                    printf "%b\n" "${RED}Invalid choice:${RC} $choice"
                    exit 1
                    ;;
            esac
            printf "%b\n" "${GREEN}Installed successfully.${RC}"
            ;;
        zypper)
            # openSUSE has community packages
            "$ESCALATION_TOOL" zypper addrepo https://download.opensuse.org/repositories/home:avindra/openSUSE_Tumbleweed/home:avindra.repo
            "$ESCALATION_TOOL" zypper refresh
            "$ESCALATION_TOOL" zypper install -y ghostty
            printf "%b\n" "${GREEN}Installed successfully.${RC}"
            ;;
        apt-get|nala)
            printf "%b\n" "-----------------------------------------------------"
            printf "%b\n" "Select the installation method:"
            printf "%b\n" "1. ${CYAN}Install from .deb package${RC} (unofficial package)"
            printf "%b\n" "2. ${CYAN}Build from source${RC}"
            printf "%b\n" "-----------------------------------------------------"
            printf "%b" "Enter your choice: "
            read -r choice
            case $choice in
                1)
                    printf "%b\n" "${YELLOW}Downloading latest Ghostty .deb package...${RC}"
                    cd /tmp
                    # Get the actual download URL from the latest release
                    LATEST_DEB_URL=$(curl -s https://api.github.com/repos/ghostty-ubuntu/ghostty/releases/latest | \
                        grep "browser_download_url.*deb" | \
                        cut -d '"' -f 4)
                    if [ -z "$LATEST_DEB_URL" ]; then
                        printf "%b\n" "${RED}Failed to find latest .deb package URL${RC}"
                        exit 1
                    fi
                    printf "%b\n" "${YELLOW}Downloading from: ${LATEST_DEB_URL}${RC}"
                    curl -LO "$LATEST_DEB_URL"
                    "$ESCALATION_TOOL" dpkg -i ghostty_*_amd64.deb
                    rm ghostty_*_amd64.deb
                    printf "%b\n" "${GREEN}Installed successfully.${RC}"
                    ;;
                2)
                    buildFromSource
                    ;;
                *)
                    printf "%b\n" "${RED}Invalid choice:${RC} $choice"
                    exit 1
                    ;;
            esac
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy ghostty
            printf "%b\n" "${GREEN}Installed successfully.${RC}"
            ;;
        *)
            printf "%b\n" "${YELLOW}No pre-built package found for your distribution.${RC}"
            printf "%b" "${YELLOW}Do you want to build from source? (y/N): ${RC}"
            read -r choice
            case $choice in
                y|Y)
                    buildFromSource
                    ;;
                *)
                    printf "%b\n" "${RED}Ghostty not installed.${RC}"
                    exit 1
                    ;;
            esac
            ;;
    esac
}

buildFromSource() {
    printf "%b\n" "${YELLOW}Installing build dependencies...${RC}"
    
    # Install basic build dependencies
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm gtk4 libadwaita pkg-config
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y gtk4-devel libadwaita-devel pkgconf-pkg-config
            ;;
        apt)
            "$ESCALATION_TOOL" "$PACKAGER" install -y libgtk-4-dev libadwaita-1-dev git
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y gtk4-devel libadwaita-devel pkgconf-pkg-config
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y libgtk-4-devel libadwaita-devel perl-extutils-pkgconfig

            ;;
    esac

    # Install Zig 0.13
    printf "%b\n" "${YELLOW}Installing Zig 0.13...${RC}"
    ARCH=$(uname -m)
    ZIG_VERSION="0.13.0"
    
    case "$ARCH" in
        x86_64)
            ZIG_ARCH="x86_64"
            ;;
        aarch64|arm64)
            ZIG_ARCH="aarch64"
            ;;
        *)
            printf "%b\n" "${RED}Unsupported architecture:${RC} $ARCH"
            exit 1
            ;;
    esac

    ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz"
    
    # Download and extract Zig
    cd /tmp
    curl -LO "$ZIG_URL"
    "$ESCALATION_TOOL" tar xf "zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz" -C /usr/local --strip-components=1
    rm "zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz"

    # Apply patch for aarch64
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        printf "%b\n" "${YELLOW}Applying aarch64 memory patch...${RC}"
        MEM_ZIG_PATH="/usr/local/lib/std/mem.zig"
        if [ -f "$MEM_ZIG_PATH" ]; then
            "$ESCALATION_TOOL" sed -i 's/4 \* 1024/16 \* 1024/' "$MEM_ZIG_PATH"
        fi
    fi

    # Clone and build Ghostty
    printf "%b\n" "${YELLOW}Building Ghostty...${RC}"
    git clone https://github.com/ghostty-org/ghostty
    cd ghostty
    zig build -Doptimize=ReleaseFast -p /usr
    
    printf "%b\n" "${GREEN}Ghostty built and installed successfully.${RC}"
}

checkEnv
checkEscalationTool
installGhostty 