#!/bin/sh -e

. ../common-script.sh

installPodman() {
    if ! command_exists podman; then
        printf "%b\n" "${YELLOW}Installing Podman...${RC}"
        case "$PACKAGER" in
            apt-get|nala|dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y podman
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install podman
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm --needed podman
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -y podman
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y podman
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Podman is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installPodman
