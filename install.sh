#!/bin/bash
# Charm CLI Installer
# Usage: curl -sSL https://raw.githubusercontent.com/divyanshu-parihar/charm-cli/main/install.sh | bash

set -e

REPO="divyanshu-parihar/charm-cli"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="charm"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo ""
    echo -e "${CYAN}   ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗${NC}"
    echo -e "${CYAN}  ██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║${NC}"
    echo -e "${CYAN}  ██║     ███████║███████║██████╔╝██╔████╔██║${NC}"
    echo -e "${CYAN}  ██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║${NC}"
    echo -e "${CYAN}  ╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║${NC}"
    echo -e "${CYAN}   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝${NC}"
    echo ""
    echo -e "${GREEN}  Charm CLI Installer${NC}"
    echo ""
}

detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        *)
            echo -e "${RED}Unsupported architecture: $ARCH${NC}"
            exit 1
            ;;
    esac

    case "$OS" in
        linux)
            OS="linux"
            ;;
        darwin)
            OS="darwin"
            ;;
        mingw*|msys*|cygwin*)
            OS="windows"
            BINARY_NAME="charm.exe"
            ;;
        *)
            echo -e "${RED}Unsupported operating system: $OS${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${YELLOW}Platform: ${OS}-${ARCH}${NC}"
}

get_latest_release() {
    echo -e "${YELLOW}Fetching latest release...${NC}"
    
    LATEST_URL="https://api.github.com/repos/${REPO}/releases/latest"
    
    if command -v curl &> /dev/null; then
        RELEASE_INFO=$(curl -sL "$LATEST_URL")
    elif command -v wget &> /dev/null; then
        RELEASE_INFO=$(wget -qO- "$LATEST_URL")
    else
        echo -e "${RED}Error: curl or wget is required${NC}"
        exit 1
    fi
    
    # Extract download URL for our platform
    DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o "https://[^\"]*charm-${OS}-${ARCH}[^\"]*" | head -1)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}Could not find release for ${OS}-${ARCH}${NC}"
        echo ""
        echo -e "${YELLOW}No releases found. The maintainer may not have published a release yet.${NC}"
        exit 1
    fi
    
    VERSION=$(echo "$RELEASE_INFO" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "${GREEN}Found: ${VERSION}${NC}"
}

download_and_install() {
    echo -e "${YELLOW}Downloading charm CLI...${NC}"
    
    TMP_DIR=$(mktemp -d)
    TMP_FILE="${TMP_DIR}/${BINARY_NAME}"
    
    if command -v curl &> /dev/null; then
        curl -sL "$DOWNLOAD_URL" -o "$TMP_FILE"
    else
        wget -q "$DOWNLOAD_URL" -O "$TMP_FILE"
    fi
    
    chmod +x "$TMP_FILE"
    
    # Check if we can write to install dir
    if [ -w "$INSTALL_DIR" ]; then
        mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
    else
        echo -e "${YELLOW}Requesting sudo access to install to ${INSTALL_DIR}...${NC}"
        sudo mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
    fi
    
    rm -rf "$TMP_DIR"
}

verify_installation() {
    if command -v charm &> /dev/null; then
        echo ""
        echo -e "${GREEN}✓ Charm CLI installed successfully!${NC}"
        echo ""
        echo -e "Run ${CYAN}charm --help${NC} to get started."
        echo ""
    else
        echo -e "${YELLOW}Charm installed to ${INSTALL_DIR}/${BINARY_NAME}${NC}"
        echo -e "You may need to restart your terminal or add ${INSTALL_DIR} to PATH."
    fi
}

main() {
    print_banner
    detect_platform
    get_latest_release
    download_and_install
    verify_installation
}

main
