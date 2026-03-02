#!/bin/bash

set -euo pipefail

# Configuration variables
declare -r BASE_URL="https://raw.githubusercontent.com/onixsat/linux/refs/heads/main/editor/nginx/alterados"
declare -r NGINX_CONF_URL="${BASE_URL}/etc/nginx/nginx.conf"
declare -r SITES_ENABLED_DEFAULT_URL="${BASE_URL}/etc/nginx/sites-enabled/default"
declare -r SITES_AVAILABLE_BO_URL="${BASE_URL}/etc/nginx/sites-available/bo.conf"
declare -r SITES_AVAILABLE_LB_URL="${BASE_URL}/etc/nginx/sites-available/lb.conf"

# Local temporary files
declare -r TEMP_DIR="/tmp/nginx_update_$$"
declare -r NGINX_CONF_TEMP="${TEMP_DIR}/nginx.conf"
declare -r DEFAULT_TEMP="${TEMP_DIR}/default"
declare -r BO_CONF_TEMP="${TEMP_DIR}/bo.conf"
declare -r LB_CONF_TEMP="${TEMP_DIR}/lb.conf"

# Target paths
declare -r NGINX_CONF_TARGET="/etc/nginx/nginx.conf"
declare -r SITES_ENABLED_DEFAULT_TARGET="/etc/nginx/sites-enabled/default"
declare -r SITES_AVAILABLE_BO_TARGET="/etc/nginx/sites-available/bo.conf"
declare -r SITES_AVAILABLE_LB_TARGET="/etc/nginx/sites-available/lb.conf"

# Colors for output
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[1;33m'
declare -r NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Cleanup function
cleanup() {
    if [[ -d "${TEMP_DIR}" ]]; then
        log_info "Cleaning up temporary files..."
        rm -rf "${TEMP_DIR}"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Check if required commands exist
check_dependencies() {
    local deps=("wget" "cp" "systemctl" "nginx")
    for cmd in "${deps[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            log_error "Required command '${cmd}' not found. Please install it first."
            exit 1
        fi
    done
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    mkdir -p "${TEMP_DIR}"
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /etc/nginx/sites-available
}

# Download configuration files
download_configs() {
    log_info "Downloading Nginx configuration files..."
    
    local files=(
        "${NGINX_CONF_URL}|${NGINX_CONF_TEMP}"
        "${SITES_ENABLED_DEFAULT_URL}|${DEFAULT_TEMP}"
        "${SITES_AVAILABLE_BO_URL}|${BO_CONF_TEMP}"
        "${SITES_AVAILABLE_LB_URL}|${LB_CONF_TEMP}"
    )
    
    for item in "${files[@]}"; do
        IFS='|' read -r url temp_file <<< "${item}"
        log_info "Downloading: ${url}"
        
        if ! wget -q --timeout=30 --tries=3 -O "${temp_file}" "${url}"; then
            log_error "Failed to download ${url}"
            exit 1
        fi
        
        # Verify file was downloaded and is not empty
        if [[ ! -s "${temp_file}" ]]; then
            log_error "Downloaded file ${temp_file} is empty"
            exit 1
        fi
    done
    
    log_info "All files downloaded successfully"
}

# Backup existing configuration files
backup_configs() {
    log_info "Creating backups of existing configuration files..."
    
    local backups=(
        "${NGINX_CONF_TARGET}|nginx.conf.bkp2"
        "${SITES_ENABLED_DEFAULT_TARGET}|default.bkp2"
        "${SITES_AVAILABLE_BO_TARGET}|bo.conf.bkp2"
        "${SITES_AVAILABLE_LB_TARGET}|lb.conf.bkp2"
    )
    
    for item in "${backups[@]}"; do
        IFS='|' read -r target backup_name <<< "${item}"
        local backup_path="${target}.bkp2"
        
        if [[ -f "${target}" ]]; then
            cp -p "${target}" "${backup_path}"
            log_info "Backed up ${target} to ${backup_path}"
        else
            log_warn "Original file ${target} not found, skipping backup"
        fi
    done
}

# Install new configuration files
install_configs() {
    log_info "Installing new configuration files..."
    
    # Copy new configurations
    cp "${NGINX_CONF_TEMP}" "${NGINX_CONF_TARGET}"
    cp "${DEFAULT_TEMP}" "${SITES_ENABLED_DEFAULT_TARGET}"
    cp "${BO_CONF_TEMP}" "${SITES_AVAILABLE_BO_TARGET}"
    cp "${LB_CONF_TEMP}" "${SITES_AVAILABLE_LB_TARGET}"
    
    # Set appropriate permissions
    chmod 644 "${NGINX_CONF_TARGET}"
    chmod 644 "${SITES_ENABLED_DEFAULT_TARGET}"
    chmod 644 "${SITES_AVAILABLE_BO_TARGET}"
    chmod 644 "${SITES_AVAILABLE_LB_TARGET}"
    
    log_info "Configuration files installed successfully"
}

# Test Nginx configuration
test_nginx_config() {
    log_info "Testing Nginx configuration..."
    if ! nginx -t; then
        log_error "Nginx configuration test failed. Rolling back..."
        rollback_configs
        exit 1
    fi
    log_info "Nginx configuration test passed"
}

# Rollback function in case of failure
rollback_configs() {
    log_warn "Rolling back to previous configuration..."
    
    local backups=(
        "${NGINX_CONF_TARGET}.bkp2|${NGINX_CONF_TARGET}"
        "${SITES_ENABLED_DEFAULT_TARGET}.bkp2|${SITES_ENABLED_DEFAULT_TARGET}"
        "${SITES_AVAILABLE_BO_TARGET}.bkp2|${SITES_AVAILABLE_BO_TARGET}"
        "${SITES_AVAILABLE_LB_TARGET}.bkp2|${SITES_AVAILABLE_LB_TARGET}"
    )
    
    for item in "${backups[@]}"; do
        IFS='|' read -r backup target <<< "${item}"
        if [[ -f "${backup}" ]]; then
            cp -p "${backup}" "${target}"
            log_info "Restored ${target} from backup"
        fi
    done
}

# Restart Nginx service
restart_nginx() {
    log_info "Restarting Nginx service..."
    if systemctl restart nginx; then
        log_info "Nginx restarted successfully"
        
        # Verify nginx is actually running
        if systemctl is-active --quiet nginx; then
            log_info "Nginx is running and active"
        else
            log_error "Nginx is not running after restart"
            exit 1
        fi
    else
        log_error "Failed to restart Nginx"
        exit 1
    fi
}

# Main execution function
main() {
    log_info "Starting Nginx configuration update..."
    
    check_root
    check_dependencies
    create_directories
    download_configs
    backup_configs
    install_configs
    test_nginx_config
    restart_nginx
    
    log_info "Nginx configuration update completed successfully!"
    log_info "Backup files are available with .bkp2 extension"
}

# Run main function
main "$@"
