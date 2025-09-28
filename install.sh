#!/bin/bash
# Reds-Hyprland-DE Installation Script

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
    
    local packages=$(grep -v '^#' "$pkg_file" | grep -v '^$' | sed 's/[[:space:]]*$//' | tr '\n' ' ')
    
    if [[ -z "$packages" ]]; then
        warn "No packages found in ${category}"
        return
    fi
    
    log "Packages: $packages"
    
    sudo pacman -S --needed --noconfirm $packages
    
    log "${category} packages installed successfully"
}

deploy_configs() {
    info "Copying configuration files..."
    
    mkdir -p "$HOME/.config"
    
    backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    backup_created=false
    
    if [[ -d "${SCRIPT_DIR}/configs" ]]; then
        for config_dir in "${SCRIPT_DIR}/configs"/*; do
            if [[ -d "$config_dir" ]]; then
                config_name=$(basename "$config_dir")
                target_dir="$HOME/.config/$config_name"
                
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
    
    info "Creating Pictures directories..."

    mkdir -p "$HOME/Pictures/screenshots"
    mkdir -p "$HOME/Pictures/wallpapers"
    
    log "Screenshots folder created: ~/Pictures/screenshots"
    log "Wallpapers folder created: ~/Pictures/wallpapers"
    
    wallpaper_source="${SCRIPT_DIR}/themes/main-theme/wallpapers"
    if [[ -d "$wallpaper_source" ]]; then
        log "Copying wallpapers..."
        
        for wallpaper in "${wallpaper_source}"/*; do
            if [[ -f "$wallpaper" ]]; then
                cp "$wallpaper" "$HOME/Pictures/wallpapers/"
                log "Copied: $(basename "$wallpaper")"
            fi
        done        
    fi
    
    # Copy scripts to .local/bin
    info "Installing scripts to ~/.local/bin..."
    mkdir -p "$HOME/.local/bin"
    
    if [[ -d "${SCRIPT_DIR}/scripts" ]]; then
        for script in "${SCRIPT_DIR}/scripts"/*; do
            if [[ -f "$script"]]; then
                script_name=$(basename "$script")
                cp "$script" "$HOME/.local/bin/"
                chmod +x "$HOME/.local/bin/$script_name"
                log "Installed script: $script_name"
            fi
        done        
    else
        warn "Scripts directory not found: ${SCRIPT_DIR}/scripts"
    fi
    
    if [[ "$backup_created" == true ]]; then
        log "Backup of old configs in: $backup_dir"
    fi
}

enable_services() {
    info "Enabling system services..."
    
    if pacman -Qq bluez-utils &>/dev/null; then
        sudo systemctl enable bluetooth.service
        log "Bluetooth service enabled"
    fi
}

show_post_install() {
    

    if [[ "$INSTALL_TYPE" == "bare-bones" ]]; then
        log "You installed 'bare-bones' only. For more apps:"
        echo "  ./install.sh apps     # Add GUI apps"
        echo "  ./install.sh widgets  # Add widgets"
        echo "  ./install.sh full     # Install everything"
    fi
    echo ""
    log "Scripts installed to ~/.local/bin"  
    log "Please reboot to complete the installation."    
     
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
            install_packages_from_list "apps"
            ;;
        "widgets")            
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
    echo "             - Examples: Hyprland, Terminal Emulator, Vim, File Manager, Audio, Fonts, Bluetooth"
    echo ""
    echo "  apps       - important GUI applications"  
    echo "             - Examples: Firefox, GIMP"
    echo ""
    echo "  widgets    - additional tools"
    echo "             - Examples: Cava, Fastfetch"
    echo ""
    echo "  full       - Complete installation (bare-bones + apps + widgets)"
    echo ""
    echo "Install individual components:"
    echo "  ./install.sh bare-bones    # First install bare-bones system"
    echo "  ./install.sh apps          # Then add GUI apps"
    echo "  ./install.sh widgets       # Then add extra tools"
    echo ""
    echo "Full installation:"
    echo "  ./install.sh full      # Everything at once"
    exit 0
fi

main