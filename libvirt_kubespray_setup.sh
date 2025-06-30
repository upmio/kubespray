#!/bin/bash
#
# Kubespray Libvirt Environment Setup Script v2.0
#
# Description:
#   Automated setup script for Kubespray development environment using libvirt
#   on RHEL-based distributions (RHEL, CentOS, Rocky Linux, AlmaLinux)
#
# Usage:
#   # REQUIRED: Set the network interface to bridge
#   export BRIDGE_INTERFACE=ens192
#   
#   # Run the setup script
#   ./libvirt_kubespray_setup.sh
#   
#   Note: BRIDGE_INTERFACE must be set to a valid network interface name.
#         This interface will be bridged and used as the default libvirt network.
#
# Environment Variables:
#   HTTP_PROXY     - HTTP proxy URL (optional)
#   PIP_PROXY      - Pip proxy URL (optional)
#   GIT_PROXY      - Git proxy URL (optional)
#   PROJECT_DIR    - Project directory (default: ~/kubespray-project)
#   KUBESPRAY_REPO_URL - Kubespray repository URL
#   BRIDGE_INTERFACE - Network interface to bridge (REQUIRED)
#                      This interface will be used to create a transparent bridge
#                      that becomes the default libvirt network
#                      Example: export BRIDGE_INTERFACE=ens192
#   DEBUG          - Enable debug logging (true/false)
#
# Requirements:
#   - RHEL-based Linux distribution
#   - sudo privileges
#   - Internet connectivity
#   - At least 50GB free disk space
#   - At least 24GB available memory
#   - BRIDGE_INTERFACE environment variable MUST be set to a valid network interface
#     (This is mandatory - the script will fail without it)
#

set -eE

#######################################
# Constants and Configuration
#######################################
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly LOG_FILE="/tmp/${SCRIPT_NAME%.sh}.log"
readonly SCRIPT_VERSION="2.0"

# System configuration constants
readonly SELINUX_CONFIG="/etc/selinux/config"
readonly HASHICORP_REPO="/etc/yum.repos.d/hashicorp.repo"
readonly LIBVIRT_DEFAULT_NETWORK="/usr/share/libvirt/networks/default.xml"

# Package lists
readonly SYSTEM_PACKAGES="curl git"
readonly LIBVIRT_PACKAGES="qemu-kvm libvirt libvirt-python3 libvirt-client virt-install virt-viewer virt-manager bridge-utils"
readonly PLUGIN_DEPENDENCIES="pkgconf-pkg-config libvirt-libs libvirt-devel libxml2-devel libxslt-devel ruby-devel gcc gcc-c++ make krb5-devel zlib-devel"
readonly PYENV_DEPENDENCIES="gcc make patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel"

readonly KUBESPRAY_REPO_URL="https://github.com/upmio/kubespray.git"
# Default configuration
HTTP_PROXY="${HTTP_PROXY:-"http://192.168.21.101:7890"}"
PIP_PROXY="${PIP_PROXY:-$HTTP_PROXY}"
GIT_PROXY="${GIT_PROXY:-$HTTP_PROXY}"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)/$(hostname)-kubespray}" # Use hostname as default project directory with absolute path
# VAGRANT_VERSION="2.4.7"  # Note: Vagrant version for reference, installed via system package manager
PYTHON_VERSION="3.12.11"
DEBUG="${DEBUG:-false}"

#######################################
# Logging Functions
#######################################
log_with_level() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo "[$timestamp] [INFO] $message" | tee -a "$LOG_FILE"
            ;;
        "WARN")
            echo "[$timestamp] [WARN] $message" | tee -a "$LOG_FILE" >&2
            ;;
        "ERROR")
            echo "[$timestamp] [ERROR] $message" | tee -a "$LOG_FILE" >&2
            ;;
        "DEBUG")
            if [ "$DEBUG" = "true" ]; then
                echo "[$timestamp] [DEBUG] $message" | tee -a "$LOG_FILE"
            fi
            ;;
    esac
}

log_info() { log_with_level "INFO" "$@"; }
log_warn() { log_with_level "WARN" "$@"; }
log_error() { log_with_level "ERROR" "$@"; }
log_debug() { log_with_level "DEBUG" "$@"; }

# Backward compatibility
log() { log_info "$@"; }

#######################################
# Error Handling
#######################################
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "Command failed at line $line_number with exit code $exit_code"
    log_error "$2"
    exit $exit_code
}

error_exit() {
    log_error "$1"
    exit 1
}

trap 'handle_error $LINENO "Unexpected error occurred"' ERR

#######################################
# Utility Functions
#######################################
command_exists_cached() {
    local cmd="$1"
    if [ -z "${command_cache[$cmd]:-}" ]; then
        if command -v "$cmd" >/dev/null 2>&1; then
            command_cache["$cmd"]="true"
        else
            command_cache["$cmd"]="false"
        fi
    fi
    [ "${command_cache[$cmd]}" = "true" ]
}

# Backward compatibility
command_exists() {
    command_exists_cached "$1"
}

safe_sudo() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

install_packages() {
    local packages="$1"
    
    log_info "Installing packages: $packages"
    
    # 将包列表转换为数组处理
    local package_array
    read -ra package_array <<< "$packages"
    
    local failed_packages=()
    local installed_count=0
    local skipped_count=0
    
    for package in "${package_array[@]}"; do
        if ! rpm -q "$package" &>/dev/null; then
            log_info "Installing $package..."
            if safe_sudo dnf install -y "$package"; then
                log_info "$package installed successfully"
                installed_count=$((installed_count + 1))
            else
                log_error "Failed to install $package"
                failed_packages+=("$package")
            fi
        else
            log_debug "$package is already installed"
            skipped_count=$((skipped_count + 1))
        fi
    done
    
    # 安装结果汇总
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_error "Failed to install packages: ${failed_packages[*]}"
        error_exit "Package installation failed"
    fi
    
    log_info "Package installation summary: $installed_count installed, $skipped_count already present"
}

manage_service() {
    local service_name="$1"
    local action="$2"
    
    case "$action" in
        "enable")
            if ! systemctl is-enabled "$service_name" &>/dev/null; then
                log_info "Enabling $service_name service..."
                safe_sudo systemctl enable "$service_name"
            else
                log_debug "$service_name service is already enabled"
            fi
            ;;
        "start")
            if ! systemctl is-active "$service_name" &>/dev/null; then
                log_info "Starting $service_name service..."
                safe_sudo systemctl start "$service_name"
            else
                log_debug "$service_name service is already running"
            fi
            ;;
        "stop")
            if systemctl is-active "$service_name" &>/dev/null; then
                log_info "Stopping $service_name service..."
                safe_sudo systemctl stop "$service_name"
            else
                log_debug "$service_name service is already stopped"
            fi
            ;;
        "disable")
            if systemctl is-enabled "$service_name" &>/dev/null; then
                log_info "Disabling $service_name service..."
                safe_sudo systemctl disable "$service_name"
            else
                log_debug "$service_name service is already disabled"
            fi
            ;;
    esac
}

add_user_to_group() {
    local user="$1"
    local group="$2"
    
    if ! groups "$user" | grep -q "$group"; then
        log_info "Adding user '$user' to '$group' group..."
        safe_sudo usermod -aG "$group" "$user"
        log_info "User added to $group group. Please log out and back in for changes to take effect."
    else
        log_debug "User '$user' is already in '$group' group"
    fi
}

#######################################
# System Validation Functions
#######################################
check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check operating system
    if ! grep -q "Red Hat\|CentOS\|Rocky\|AlmaLinux" /etc/os-release; then
        error_exit "This script is designed for RHEL-based distributions"
    fi
    
    # Check system architecture
    if [ "$(uname -m)" != "x86_64" ]; then
        log_warn "This script is optimized for x86_64 architecture"
    fi
    
    # Check available disk space (50GB required)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=52428800  # 50GB in KB
    if [ "$available_space" -lt "$required_space" ]; then
        error_exit "Insufficient disk space. At least 50GB required."
    fi
    
    # Check memory
    local available_memory=$(free -m | awk 'NR==2{print $7}')
    if [ "$available_memory" -lt 24576 ]; then
        log_warn "Less than 24GB available memory. Performance may be affected."
    fi
    
    log_info "System requirements check passed"
}

validate_configuration() {
    log_info "Validating configuration..."
    
    # Validate proxy configuration
    if [ -n "$HTTP_PROXY" ]; then
        log_debug "Testing HTTP proxy: $HTTP_PROXY"
        if ! curl -s --proxy "$HTTP_PROXY" --connect-timeout 10 http://www.google.com > /dev/null; then
            log_warn "HTTP proxy $HTTP_PROXY may not be working correctly"
        fi
    fi
    
    # Validate Python version format
    if ! echo "$PYTHON_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        error_exit "Invalid Python version format: $PYTHON_VERSION"
    fi
    
    # Validate project directory permissions
    if [ ! -w "$(dirname "$PROJECT_DIR")" ]; then
        error_exit "No write permission for project directory parent: $(dirname "$PROJECT_DIR")"
    fi
    
    log_info "Configuration validation passed"
}

check_sudo_privileges() {
    log_info "Checking sudo privileges..."
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        log_info "This script requires sudo privileges. Please enter your password when prompted."
        if ! sudo true; then
            error_exit "Failed to obtain sudo privileges"
        fi
    fi
    log_info "Sudo privileges confirmed"
}

#######################################
# Network and Proxy Functions
#######################################
test_network_connectivity() {
    log_info "Testing network connectivity..."
    
    local test_urls=("http://www.google.com" "https://github.com" "https://pypi.org")
    local proxy_option=""
    
    if [ -n "$HTTP_PROXY" ]; then
        proxy_option="--proxy $HTTP_PROXY"
    fi
    
    for url in "${test_urls[@]}"; do
        if curl -s $proxy_option --connect-timeout 10 "$url" > /dev/null; then
            log_info "Network connectivity test passed for $url"
            return 0
        fi
    done
    
    log_warn "Network connectivity test failed. Please check your internet connection and proxy settings."
    return 1
}

configure_git_proxy() {
    if [ -n "$GIT_PROXY" ]; then
        log_info "Configuring git proxy: $GIT_PROXY"
        git config --global http.proxy "$GIT_PROXY"
        git config --global https.proxy "$GIT_PROXY"
    else
        log_debug "No git proxy configured"
    fi
}

remove_git_proxy() {
    log_debug "Cleaning up git proxy configuration..."
    git config --global --unset http.proxy 2>/dev/null || true
    git config --global --unset https.proxy 2>/dev/null || true
}

#######################################
# Installation Functions
#######################################
install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    # Update package cache
    log_info "Updating package cache..."
    safe_sudo dnf makecache
    
    # Install basic packages
    install_packages "$SYSTEM_PACKAGES"
    
    # Install Development Tools
    if ! dnf group list --installed | grep -q "Development Tools"; then
        log_info "Installing Development Tools..."
        safe_sudo dnf groupinstall -y "Development Tools"
    else
        log_debug "Development Tools already installed"
    fi
    
    # Install Libvirt packages
    install_packages "$LIBVIRT_PACKAGES"
    
    log_info "System dependencies installation completed"
}

configure_system_security() {
    log_info "Configuring system security..."
    
    # Configure firewall
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        log_info "Stopping firewalld..."
        manage_service "firewalld" "stop"
    fi
    
    manage_service "firewalld" "disable"
    
    # Configure SELinux
    log_info "Configuring SELinux..."
    if [ "$(getenforce)" != "Disabled" ]; then
        log_info "Temporarily disabling SELinux"
        safe_sudo setenforce 0
        
        log_info "Permanently disabling SELinux"
        safe_sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' "$SELINUX_CONFIG"
        safe_sudo sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' "$SELINUX_CONFIG"
        
        log_info "SELinux disabled. Changes will be permanent after reboot."
    else
        log_debug "SELinux already disabled"
    fi
    
    log_info "System security configuration completed"
}

# Create and configure bridge network connections
create_bridge_connections() {
    local bridge_name="$1"
    local interface="$2"
    local slave_name="bridge-slave-$interface"
    
    # Create bridge connection if it doesn't exist
    if ! safe_sudo nmcli con show "$bridge_name" &>/dev/null; then
        log_info "Creating transparent bridge $bridge_name..."
        safe_sudo nmcli con add type bridge con-name "$bridge_name" ifname "$bridge_name" || \
            error_exit "Failed to create bridge connection $bridge_name"
        
        # Configure bridge (disable IP, disable STP)
        safe_sudo nmcli con mod "$bridge_name" ipv4.method disabled ipv6.method disabled || \
            error_exit "Failed to disable IP on bridge $bridge_name"
        safe_sudo nmcli con mod "$bridge_name" bridge.stp no || \
            log_warn "Failed to disable STP on bridge $bridge_name"
    fi
    
    # Create bridge slave connection if it doesn't exist
    if ! safe_sudo nmcli con show "$slave_name" &>/dev/null; then
        log_info "Adding $interface to bridge $bridge_name..."
        safe_sudo nmcli con add type bridge-slave ifname "$interface" master "$bridge_name" con-name "$slave_name" || \
            error_exit "Failed to add $interface to bridge $bridge_name"
    fi
    
    # Activate connections
    safe_sudo nmcli con up "$bridge_name" && safe_sudo nmcli con up "$slave_name" || \
        error_exit "Failed to activate bridge connections"
    
    # Wait and verify bridge is ready
    sleep 2
    ip link show "$bridge_name" | grep -q "state UP" || \
        error_exit "Bridge $bridge_name is not in UP state"
}

# Configure libvirt bridge network
configure_libvirt_network() {
    local network_name="$1"
    local bridge_name="$2"
    local xml_file="/tmp/$network_name.xml"
    
    if safe_sudo virsh net-list --all | grep -q "$network_name"; then
        # Ensure existing network is active and set to autostart
        safe_sudo virsh net-list | grep -q "$network_name.*active" || \
            safe_sudo virsh net-start "$network_name" 2>/dev/null
        safe_sudo virsh net-list --autostart | grep -q "$network_name" || \
            safe_sudo virsh net-autostart "$network_name" 2>/dev/null
    else
        # Create new bridge network
        log_info "Creating libvirt bridge network '$network_name'..."
        cat > "$xml_file" << EOF
<network>
  <name>$network_name</name>
  <forward mode='bridge'/>
  <bridge name='$bridge_name'/>
</network>
EOF
        
        safe_sudo virsh net-define "$xml_file" && \
        safe_sudo virsh net-autostart "$network_name" && \
        safe_sudo virsh net-start "$network_name" || \
            error_exit "Failed to create bridge network '$network_name'"
        
        rm -f "$xml_file"
        log_info "Bridge network '$network_name' created and configured"
    fi
}

# Disable default libvirt network and set bridge as default
set_bridge_as_default() {
    local network_name="$1"
    
    # Disable default network
    if safe_sudo virsh net-list --all | grep -q "default"; then
        safe_sudo virsh net-destroy default 2>/dev/null || true
        safe_sudo virsh net-autostart default --disable 2>/dev/null || true
    fi
    
    # Set bridge network as default
    local libvirt_config_dir="/etc/libvirt/qemu/networks"
    if [[ -d "$libvirt_config_dir" && -f "$libvirt_config_dir/$network_name.xml" ]]; then
        [[ -f "$libvirt_config_dir/default.xml" ]] && \
            safe_sudo cp "$libvirt_config_dir/default.xml" "$libvirt_config_dir/default.xml.backup" 2>/dev/null
        safe_sudo cp "$libvirt_config_dir/$network_name.xml" "$libvirt_config_dir/default.xml" 2>/dev/null || true
    fi
}

# Setup libvirt with bridge networking
setup_libvirt() {
    log_info "Setting up Libvirt with bridge networking..."
    
    # Verify bridge interface exists
    ip link show "$BRIDGE_INTERFACE" &>/dev/null || \
        error_exit "Network interface '$BRIDGE_INTERFACE' does not exist. Available: $(ip link show | grep -E '^[0-9]+:' | grep -v 'lo:' | cut -d: -f2 | tr -d ' ' | tr '\n' ' ')"
    
    # Enable and start libvirtd service
    manage_service "libvirtd" "enable"
    manage_service "libvirtd" "start"
    
    # Add current user to libvirt group
    add_user_to_group "$USER" "libvirt"
    
    # Setup bridge network
    local bridge_name="br0"
    local network_name="bridge-network"
    
    create_bridge_connections "$bridge_name" "$BRIDGE_INTERFACE"
    configure_libvirt_network "$network_name" "$bridge_name"
    set_bridge_as_default "$network_name"
    
    log_info "Libvirt setup completed - bridge network '$network_name' is now default"
}

install_vagrant() {
    log_info "Installing Vagrant..."
    
    if command_exists vagrant; then
        log_info "Vagrant is already installed"
        vagrant --version
        return 0
    fi
    
    # Install yum-utils
    install_packages "yum-utils"
    
    # Add HashiCorp repository
    if [ ! -f "$HASHICORP_REPO" ]; then
        log_info "Adding HashiCorp YUM repository..."
        safe_sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    else
        log_debug "HashiCorp YUM repository already exists"
    fi
    
    # Install Vagrant
    install_packages "vagrant"
    
    log_info "Vagrant installation completed"
    vagrant --version
}

install_vagrant_libvirt_plugin() {
    log_info "Installing Vagrant libvirt plugin..."
    
    if vagrant plugin list | grep -q "vagrant-libvirt"; then
        log_info "vagrant-libvirt plugin is already installed"
        vagrant plugin list
        return 0
    fi
    
    # Enable EPEL repository
    install_packages "epel-release"
    
    # Enable CRB repository
    log_info "Enabling CRB repository..."
    safe_sudo dnf config-manager --set-enabled crb 2>/dev/null || log_debug "CRB repository may already be enabled"
    
    # Install plugin dependencies
    install_packages "$PLUGIN_DEPENDENCIES"
    
    # Configure proxy for plugin installation
    local proxy_env=""
    if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then
        log_info "Configuring proxy for vagrant plugin installation..."
        export http_proxy="$HTTP_PROXY"
        export https_proxy="$HTTPS_PROXY"
        export HTTP_PROXY="$HTTP_PROXY"
        export HTTPS_PROXY="$HTTPS_PROXY"
        export no_proxy="localhost,127.0.0.1,::1"
        export NO_PROXY="localhost,127.0.0.1,::1"
        export BUNDLE_HTTP_PROXY="$HTTP_PROXY"
        export BUNDLE_HTTPS_PROXY="$HTTPS_PROXY"
        export GEM_HTTP_PROXY="$HTTP_PROXY"
        export GEM_HTTPS_PROXY="$HTTPS_PROXY"
        
        log_debug "Proxy settings configured for plugin installation"
    fi
    
    # Install plugin
    log_info "Installing vagrant-libvirt plugin..."
    vagrant plugin install vagrant-libvirt
    
    log_info "Vagrant libvirt plugin installation completed"
    vagrant plugin list
}

setup_python_environment() {
    log_info "Setting up Python environment..."
    
    # Install pyenv if not present
    if ! command_exists pyenv; then
        install_pyenv
    else
        log_info "pyenv is already installed"
        setup_pyenv_environment
    fi
    
    # Install Python version
    if ! pyenv versions --bare | grep -q "$PYTHON_VERSION"; then
        log_info "Installing Python $PYTHON_VERSION using pyenv..."
        pyenv install "$PYTHON_VERSION"
    else
        log_debug "Python $PYTHON_VERSION is already installed"
    fi
    
    log_info "Python environment setup completed"
}

install_pyenv() {
    log_info "Installing pyenv..."
    
    # Install pyenv dependencies
    install_packages "$PYENV_DEPENDENCIES"
    
    # Remove existing pyenv installation
    if [ -d "$HOME/.pyenv" ]; then
        log_info "Removing existing pyenv installation..."
        rm -rf "$HOME/.pyenv"
    fi
    
    # Install pyenv with error handling and proxy support
    log_info "Downloading and installing pyenv..."
    
    # Prepare curl command with proxy support
    local curl_cmd="curl"
    local curl_options="--fail --location --show-error --silent"
    
    # Add proxy configuration if available
    if [ -n "$HTTP_PROXY" ]; then
        log_debug "Using HTTP proxy for pyenv installation: $HTTP_PROXY"
        curl_options="$curl_options --proxy $HTTP_PROXY"
    fi
    
    # Add timeout and retry options
    curl_options="$curl_options --connect-timeout 30 --max-time 300 --retry 3 --retry-delay 5"
    
    # Download and execute pyenv installer with error handling
    # First download the script to a temporary file
    local temp_script="$(mktemp)"
    if ! $curl_cmd $curl_options https://pyenv.run -o "$temp_script"; then
        rm -f "$temp_script"
        log_error "Failed to download pyenv installer script"
        log_error "This could be due to:"
        log_error "  1. Network connectivity issues"
        log_error "  2. Proxy configuration problems"
        log_error "  3. GitHub/raw.githubusercontent.com access restrictions"
        log_error "  4. Firewall blocking the connection"
        log_error ""
        log_error "Current proxy settings:"
        log_error "  HTTP_PROXY: ${HTTP_PROXY:-Not set}"
        log_error ""
        log_error "Troubleshooting steps:"
        log_error "  1. Check network connectivity: curl -I https://raw.githubusercontent.com"
        log_error "  2. Verify proxy settings if behind corporate firewall"
        log_error "  3. Try manual installation: git clone https://github.com/pyenv/pyenv.git ~/.pyenv"
        error_exit "pyenv installer download failed"
    fi
    
    # Execute the downloaded script with proxy environment variables
    log_debug "Executing pyenv installer script with proxy settings..."
    if [ -n "$HTTP_PROXY" ]; then
        export HTTP_PROXY
        export HTTPS_PROXY="$HTTP_PROXY"
        export http_proxy="$HTTP_PROXY"
        export https_proxy="$HTTP_PROXY"
    fi
    
    if ! bash "$temp_script"; then
        rm -f "$temp_script"
        log_error "Failed to execute pyenv installer script"
        log_error "This could be due to:"
        log_error "  1. Network connectivity issues during script execution"
        log_error "  2. Proxy configuration problems for git/curl operations in script"
        log_error "  3. Missing dependencies for pyenv installation"
        log_error "  4. Insufficient permissions"
        log_error ""
        log_error "Current proxy settings:"
        log_error "  HTTP_PROXY: ${HTTP_PROXY:-Not set}"
        log_error "  HTTPS_PROXY: ${HTTPS_PROXY:-Not set}"
        log_error ""
        log_error "Troubleshooting steps:"
        log_error "  1. Check network connectivity: curl -I https://raw.githubusercontent.com"
        log_error "  2. Verify proxy settings if behind corporate firewall"
        log_error "  3. Try manual installation: git clone https://github.com/pyenv/pyenv.git ~/.pyenv"
        log_error "  4. Check system dependencies: git, curl, build tools"
        error_exit "pyenv installation failed"
    fi
    
    # Clean up temporary script file
    rm -f "$temp_script"
    log_debug "Pyenv installer script executed successfully"
    
    # Verify pyenv installation
    if [ ! -d "$HOME/.pyenv" ]; then
        log_error "pyenv installation directory not found after installation"
        error_exit "pyenv installation verification failed"
    fi
    
    # Configure shell environment
    setup_pyenv_environment
    
    log_info "pyenv installation completed successfully"
}

setup_pyenv_environment() {
    # Determine shell configuration file
    local shell_rc
    case "$SHELL" in
        "/bin/bash")
            shell_rc="$HOME/.bashrc"
            ;;
        "/bin/zsh"|*/usr/bin/zsh)
            shell_rc="$HOME/.zshrc"
            ;;
        *)
            shell_rc="$HOME/.profile"
            ;;
    esac
    
    # Create shell config file if it doesn't exist
    if [ ! -f "$shell_rc" ]; then
        log_info "Creating shell config file: $shell_rc"
        touch "$shell_rc"
    fi
    
    # Configure pyenv environment variables
    if ! grep -q "PYENV_ROOT" "$shell_rc" 2>/dev/null; then
        log_info "Configuring pyenv environment variables in $shell_rc..."
        {
            echo 'export PYENV_ROOT="$HOME/.pyenv"'
            echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
            echo 'eval "$(pyenv init --path)"'
        } >> "$shell_rc"
    else
        log_debug "pyenv environment variables already configured"
    fi
    
    # Export variables for current script
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
}

setup_kubespray_project() {
    log_info "Setting up Kubespray project..."
    
    # Create project directory
    if [ ! -d "$PROJECT_DIR" ]; then
        log_info "Creating project directory: $PROJECT_DIR"
        mkdir -p "$PROJECT_DIR"
    fi
    
    local kubespray_dir="$PROJECT_DIR/kubespray"
    
    # Remove existing directory if present
    if [ -d "$kubespray_dir" ]; then
        log_info "Removing existing Kubespray directory for clean clone..."
        rm -rf "$kubespray_dir"
    fi
    
    # Configure git proxy and clone repository
    configure_git_proxy
    
    log_info "Cloning Kubespray repository..."
    if ! git clone "$KUBESPRAY_REPO_URL" "$kubespray_dir"; then
        log_error "Failed to clone Kubespray repository"
        log_error "Please check:"
        log_error "  1. Network connectivity"
        log_error "  2. Proxy configuration"
        log_error "  3. Git authentication"
        log_error "  4. Repository access permissions"
        error_exit "Kubespray repository clone failed"
    fi
    
    # Set up Python environment for project
    cd "$kubespray_dir"
    pyenv local "$PYTHON_VERSION"
    
    # Create and activate virtual environment
    setup_virtual_environment "$kubespray_dir"
    
    # Clean up git proxy
    remove_git_proxy
    
    log_info "Kubespray project setup completed"
}

setup_virtual_environment() {
    local project_dir="$1"
    local venv_dir="$project_dir/.venv"
    
    log_info "Setting up Python virtual environment..."
    
    # Create virtual environment
    if [ ! -d "$venv_dir" ]; then
        log_info "Creating virtual environment: $venv_dir"
        python3 -m venv "$venv_dir"
    else
        log_debug "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    log_info "Activating virtual environment..."
    source "$venv_dir/bin/activate"
    
    # Upgrade pip
    local pip_install_cmd="pip install"
    if [ -n "$PIP_PROXY" ]; then
        log_debug "Using proxy for pip: $PIP_PROXY"
        pip_install_cmd="$pip_install_cmd --proxy $PIP_PROXY"
    fi
    
    log_info "Upgrading pip..."
    $pip_install_cmd --upgrade pip
    
    # Install dependencies
    if [ -f "$project_dir/requirements.txt" ]; then
        log_info "Installing Kubespray dependencies..."
        if ! pip list | grep -q "ansible"; then
            $pip_install_cmd -r "$project_dir/requirements.txt"
        else
            log_info "Updating existing dependencies..."
            $pip_install_cmd --upgrade -r "$project_dir/requirements.txt"
        fi
    else
        log_warn "requirements.txt not found in $project_dir"
    fi
    
    log_info "Virtual environment setup completed"
}

#######################################
# Main Function
#######################################
main() {
    log_info "Starting Kubespray Libvirt Environment Setup v$SCRIPT_VERSION"
    log_info "Log file: $LOG_FILE"
    
    # Validate required environment variables first
    if [[ -z "${BRIDGE_INTERFACE:-}" ]]; then
        error_exit "BRIDGE_INTERFACE environment variable is required. Please set it to a valid network interface name (e.g., export BRIDGE_INTERFACE=ens192)"
    fi
    
    log_info "Using bridge interface: $BRIDGE_INTERFACE"
    
    # Verify the specified interface exists
    if ! ip link show "$BRIDGE_INTERFACE" &>/dev/null; then
        error_exit "Network interface '$BRIDGE_INTERFACE' does not exist. Available interfaces: $(ip link show | grep -E '^[0-9]+:' | grep -v 'lo:' | cut -d: -f2 | tr -d ' ' | tr '\n' ' ')"
    fi
    
    # System validation
    check_sudo_privileges
    check_system_requirements
    validate_configuration
    test_network_connectivity
    
    # Installation steps
    install_system_dependencies
    configure_system_security
    setup_libvirt
    install_vagrant
    install_vagrant_libvirt_plugin
    setup_python_environment
    setup_kubespray_project
    
    # Final summary
    print_completion_summary
    
    log_info "Kubespray environment setup completed successfully!"
}

print_completion_summary() {
    local kubespray_dir="$PROJECT_DIR/kubespray"
    
    log_info "################################################################"
    log_info "# Environment Setup Completed Successfully!                   #"
    log_info "################################################################"
    log_info "#                                                             #"
    log_info "# Kubespray Location: $kubespray_dir"
    log_info "# Virtual Environment: $kubespray_dir/.venv"
    log_info "#                                                             #"
    log_info "# Next Steps:                                                 #"
    log_info "# 1. cd $kubespray_dir"
    log_info "# 2. source .venv/bin/activate"
    log_info "# 3. vagrant up --provider=libvirt"
    log_info "#                                                             #"
    log_info "# Important Notes:                                            #"
    log_info "# - If kernel was updated, reboot before using libvirt       #"
    log_info "# - Log out and back in for group changes to take effect     #"
    log_info "# - Use 'vagrant up --provider=libvirt' for libvirt provider #"
    log_info "#                                                             #"
    log_info "# Environment Variables:                                     #"
    log_info "# - PIP_PROXY: ${PIP_PROXY:-Not set}"
    log_info "# - GIT_PROXY: ${GIT_PROXY:-Not set}"
    log_info "# - KUBESPRAY_REPO_URL: $KUBESPRAY_REPO_URL"
    log_info "# - PROJECT_DIR: $PROJECT_DIR"
    log_info "################################################################"
}

#######################################
# Script Execution Entry Point
#######################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi