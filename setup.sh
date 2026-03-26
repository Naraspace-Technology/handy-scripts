#!/bin/bash
# setup.sh — Unified installer for Debian/Ubuntu environments
# Usage:
#   Interactive:  curl -fsSL <RAW_URL> | bash
#   With option:  curl -fsSL <RAW_URL> | bash -s -- --install
#                 curl -fsSL <RAW_URL> | bash -s -- --scmd
#                 curl -fsSL <RAW_URL> | bash -s -- --all
set -e

############################################
# Constants
############################################
SCMD_RAW_URL="https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/ubuntu/scmd.sh"
SCMD_INSTALL_PATH="/usr/local/bin/scmd"

############################################
# Color helpers
############################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

############################################
# OS Detection
############################################
detect_os() {
    if [ ! -f /etc/os-release ]; then
        error "Cannot detect OS. /etc/os-release not found."
    fi

    . /etc/os-release

    case "$ID" in
        ubuntu)
            OS="ubuntu"
            info "Detected OS: Ubuntu ($VERSION_ID)"
            ;;
        debian)
            OS="debian"
            info "Detected OS: Debian ($VERSION_ID)"
            ;;
        *)
            error "Unsupported OS: $ID. Only Ubuntu and Debian are supported."
            ;;
    esac
}

############################################
# Install: Docker Engine
############################################
install_docker() {
    info "Installing Docker Engine..."

    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh

    info "Docker Engine installed: $(docker --version)"
}

############################################
# Install: Docker Compose (latest)
############################################
install_docker_compose() {
    info "Installing Docker Compose (latest)..."

    sudo apt-get install -y jq

    VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
    DESTINATION=/usr/local/bin/docker-compose

    sudo curl -L "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o "$DESTINATION"
    sudo chmod 755 "$DESTINATION"
    sudo ln -sf "$DESTINATION" /usr/bin/docker-compose

    info "Docker Compose installed: $(docker-compose --version)"
}

############################################
# Install: Common packages
############################################
install_common_packages() {
    info "Installing common packages..."

    sudo apt-get update -y
    sudo apt-get install -y \
        net-tools \
        iputils-ping \
        iproute2 \
        git \
        wget \
        vim \
        make \
        gh \
        python3 \
        python3-pip \
        python3-venv

    info "Common packages installed."
    info "Python: $(python3 --version)"
}

############################################
# Configure: KST timezone
############################################
configure_timezone() {
    info "Setting timezone to Asia/Seoul (KST)..."

    sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
    echo "Asia/Seoul" | sudo tee /etc/timezone > /dev/null

    info "Timezone set: $(date)"
}

############################################
# Install: scmd
############################################
install_scmd() {
    info "Installing scmd to ${SCMD_INSTALL_PATH}..."

    sudo curl -fsSL "$SCMD_RAW_URL" -o "$SCMD_INSTALL_PATH"
    sudo chmod 755 "$SCMD_INSTALL_PATH"

    info "scmd installed. Run 'scmd --help' to use."
}

############################################
# Run: Base install (all-in-one)
############################################
run_install() {
    install_docker
    install_docker_compose
    install_common_packages
    configure_timezone

    echo ""
    info "========================================="
    info " Base installation complete!"
    info "========================================="
}

############################################
# Run: scmd install
############################################
run_scmd() {
    install_scmd

    echo ""
    info "========================================="
    info " scmd installation complete!"
    info "========================================="
}

############################################
# Interactive menu
############################################
show_menu() {
    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN} Naraspace Handy Scripts - Setup${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e " OS: ${GREEN}${OS}${NC}"
    echo ""
    echo "  1) Base install  (Docker + Compose + Python3 + utilities + KST)"
    echo "  2) scmd install  (Install scmd command)"
    echo "  3) All           (Base install + scmd)"
    echo "  q) Quit"
    echo ""

    # curl | bash 에서도 입력 받기 위해 /dev/tty 사용
    read -r -p "Select [1/2/3/q]: " choice < /dev/tty

    case "$choice" in
        1) run_install ;;
        2) run_scmd ;;
        3) run_install; run_scmd ;;
        q|Q) echo "Bye."; exit 0 ;;
        *) error "Invalid selection: $choice" ;;
    esac
}

############################################
# Parse arguments
############################################
MODE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install)  MODE="install";  shift ;;
        --scmd)     MODE="scmd";     shift ;;
        --all)      MODE="all";      shift ;;
        --help|-h)
            echo "Usage: setup.sh [--install | --scmd | --all]"
            echo ""
            echo "Options:"
            echo "  --install   Install Docker, Compose, Python3, utilities, KST timezone"
            echo "  --scmd      Install scmd command to /usr/local/bin/scmd"
            echo "  --all       Install everything (base + scmd)"
            echo "  -h, --help  Show this help"
            echo ""
            echo "No option: interactive menu"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use --help for usage."
            ;;
    esac
done

############################################
# Main
############################################
detect_os

case "$MODE" in
    install)  run_install ;;
    scmd)     run_scmd ;;
    all)      run_install; run_scmd ;;
    "")       show_menu ;;
esac
