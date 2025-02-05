#!/bin/sh -e

. ../common-script.sh
. ../common-service-script.sh

install_cockpit() {
    if ! command_exists cockpit; then
        printf "%b\n" "${YELLOW}Installing Cockpit...${RC}"
        noninteractive cockpit
        startAndEnableService "cockpit.socket"
        printf "%b\n" "${GREEN}Cockpit service has been started.${RC}"
        configure_ufw_for_cockpit
        printf "%b\n" "${GREEN}Cockpit installation complete.${RC}"
    else
        printf "%b\n" "${GREEN}Cockpit is already installed.${RC}"
    fi
}

configureUFW() {
    if command_exists ufw; then
        "$ESCALATION_TOOL" ufw allow 9090/tcp
        "$ESCALATION_TOOL" ufw reload
        printf "%b\n" "${GREEN}UFW configuration updated to allow Cockpit.${RC}"
    else
        printf "%b\n" "${YELLOW}UFW is not installed. Please ensure port 9090 is open for Cockpit.${RC}"
    fi
    printf "%b\n" "${CYAN}You can access Cockpit via https://$(ip route get 1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'):9090${RC}"
}

checkEnv
checkEscalationTool
configureUFW
install_cockpit
