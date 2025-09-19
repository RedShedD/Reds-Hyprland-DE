#!/bin/bash

# Reds-Hyprland-DE Installation Script
# Usage: ./install.sh [bare-bones|apps|widgets|full]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_TYPE="${1:-bare-bones}"

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is for Arch Linux only!"
    fi
}

check_dependencies() {
    log "Checking system dependencies..."
    
    if ! command -v pacman &> /dev/null; then
        error "pacman not found!"
    fi
    
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root!"
    fi
    
    # Check if sudo works
    if ! sudo -n true 2>/dev/null; then
        log "Sudo privileges required..."
        sudo true
    fi
}

install_packages_from_list() {
    local category="$1"
    local pkg_file="${SCRIPT_DIR}/packages/${category}/package-list.txt"
    
    if [[ ! -f "$pkg_file" ]]; then
        warn "Package list ${pkg_file} not found, skipping..."
        return
    fi
    
    info "Installing ${category} packages..."
    
    # Read packages from list (ignore comments and empty lines)
    local packages=$(grep -v '^#' "$pkg_file" | grep -v '^$' | sed 's/[[:space:]]*$//' | tr '\n' ' ')
    
    if [[ -z "$packages" ]]; then
        warn "No packages found in ${category}"
        return
    fi
    
    log "Packages: $packages"
    
    # Install directly from repos
    sudo pacman -S --needed --noconfirm $packages
    
    log "${category} packages installed successfully"
}

deploy_configs() {
    info "Copying configuration files..."
    
    # Create .config if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Create backup if configs exist
    backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    backup_created=false
    
    # Copy configs
    if [[ -d "${SCRIPT_DIR}/configs" ]]; then
        for config_dir in "${SCRIPT_DIR}/configs"/*; do
            if [[ -d "$config_dir" ]]; then
                config_name=$(basename "$config_dir")
                target_dir="$HOME/.config/$config_name"
                
                # Backup only if target directory exists
                if [[ -d "$target_dir" ]]; then
                    if [[ "$backup_created" == false ]]; then
                        mkdir -p "$backup_dir"
                        backup_created=true
                        log "Creating backup in: $backup_dir"
                    fi
                    log "Backing up existing configuration: $config_name"
                    cp -r "$target_dir" "$backup_dir/" 2>/dev/null || true
                fi
                
                log "Copying $config_name configuration..."
                cp -r "$config_dir" "$HOME/.config/"
            fi
        done
    fi
    
    # Create Pictures directories
    info "Creating Pictures directories..."
    mkdir -p "$HOME/Pictures/screenshots"
    mkdir -p "$HOME/Pictures/wallpapers"
    log "Screenshots folder created: ~/Pictures/screenshots"
    log "Wallpapers folder created: ~/Pictures/wallpapers"
    
    # Copy wallpapers if available
    wallpaper_source="${SCRIPT_DIR}/themes/main-theme/wallpapers"
    if [[ -d "$wallpaper_source" ]]; then
        log "Copying wallpapers..."
        
        # Copy all wallpapers to ~/Pictures/wallpapers
        for wallpaper in "${wallpaper_source}"/*; do
            if [[ -f "$wallpaper" ]]; then
                cp "$wallpaper" "$HOME/Pictures/wallpapers/"
                log "Copied: $(basename "$wallpaper")"
            fi
        done
        
        # Set default wallpaper for Hyprland config
        default_wallpaper=$(find "${wallpaper_source}" -name "*.jpg" -o -name "*.png" | head -1)
        if [[ -n "$default_wallpaper" ]]; then
            mkdir -p "$HOME/.config/hyprland"
            cp "$default_wallpaper" "$HOME/.config/hyprland/wallpaper$(echo "$default_wallpaper" | sed 's/.*\(\.[^.]*\)$/\1/')"
            log "Default wallpaper set for Hyprland"
        fi
    else
        warn "Wallpaper directory not found: $wallpaper_source"
    fi
    
    # Copy scripts to .local/bin
    info "Installing scripts to ~/.local/bin..."
    mkdir -p "$HOME/.local/bin"
    
    if [[ -d "${SCRIPT_DIR}/scripts" ]]; then
        for script in "${SCRIPT_DIR}/scripts"/*; do
            if [[ -f "$script" && -x "$script" ]]; then
                script_name=$(basename "$script")
                cp "$script" "$HOME/.local/bin/"
                chmod +x "$HOME/.local/bin/$script_name"
                log "Installed script: $script_name"
            fi
        done
        
        # Add ~/.local/bin to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            log "Added ~/.local/bin to PATH in .bashrc"
        fi
    else
        warn "Scripts directory not found: ${SCRIPT_DIR}/scripts"
    fi
    
    if [[ "$backup_created" == true ]]; then
        log "Backup of old configs in: $backup_dir"
    fi
}

enable_services() {
    info "Enabling system services..."
    
    # Enable Bluetooth if installed
    if pacman -Qq bluez-utils &>/dev/null; then
        sudo systemctl enable bluetooth.service
        log "Bluetooth service enabled"
    fi
}

show_post_install() {
    echo ""
    echo "=================================================================="
    log "Installation completed!"
    echo "=================================================================="
    echo ""
    log "Next steps:"
    echo "  1. Reboot: sudo reboot"
    echo "  2. Select 'Hyprland' in your display manager"
    echo "  3. Or start directly: Hyprland"
    echo ""
    
    log "Important keybindings:"
    echo "  Super + Return       Open terminal"
    echo "  Super + R           App launcher"
    echo "  Super + Q           Close window"
    echo "  Super + E           File manager"
    echo ""
    
    if [[ "$INSTALL_TYPE" == "bare-bones" ]]; then
        log "You installed 'bare-bones' only. For more apps:"
        echo "  ./install.sh apps     # Add GUI apps"
        echo "  ./install.sh widgets  # Add extra tools"
        echo "  ./install.sh full     # Install everything"
    fi
    
    echo ""
    log "Scripts installed to ~/.local/bin (restart terminal to use)"
    log "For issues: see docs/troubleshooting.md"
}

main() {
    echo "=================================================================="
    log "Reds-Hyprland-DE Installation (${INSTALL_TYPE})"
    echo "=================================================================="
    
    check_arch
    check_dependencies
    
    # Update package database
    info "Updating package database..."
    sudo pacman -Sy
    
    case "$INSTALL_TYPE" in
        "bare-bones")
            install_packages_from_list "bare-bones"
            ;;
        "apps")
            install_packages_from_list "bare-bones"
            install_packages_from_list "apps"
            ;;
        "widgets")
            install_packages_from_list "bare-bones"
            install_packages_from_list "apps"
            install_packages_from_list "widgets"
            ;;
        "full")
            install_packages_from_list "bare-bones"
            install_packages_from_list "apps"
            install_packages_from_list "widgets"
            ;;
        *)
            error "Unknown installation type: $INSTALL_TYPE"
            ;;
    esac
    
    deploy_configs
    enable_services
    show_post_install
}

# Show help
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Reds-Hyprland-DE Installation Script"
    echo ""
    echo "Usage: $0 [bare-bones|apps|widgets|full]"
    echo ""
    echo "Installation Types:"
    echo "  bare-bones - Minimal working system"
    echo "             - Hyprland, Terminal Emulator, Vim, File Manager, Audio, Fonts"
    echo ""
    echo "  apps       - Bare-bones + important GUI applications"  
    echo "             - Firefox, Thunar, Image viewer, Text editor"
    echo ""
    echo "  widgets    - Bare-bones + Apps + additional tools"
    echo "             - Cava, Fastfetch"
    echo ""
    echo "  full       - Complete installation (bare-bones + apps + widgets)"
    echo ""
    echo "Step-by-step installation:"
    echo "  ./install.sh bare-bones    # First install bare-bones system"
    echo "  ./install.sh apps          # Then add GUI apps"
    echo "  ./install.sh widgets       # Then add extra tools"
    echo ""
    echo "Direct installation:"
    echo "  ./install.sh full      # Everything at once"
    exit 0
fi

main