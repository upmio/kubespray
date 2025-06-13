# Vagrant configuration file for Kubespray
# Kubespray Vagrant Configuration Sample
# This file allows you to customize various settings for your Vagrant environment
# Copy this file to vagrant/config.rb and modify the values according to your needs

# =============================================================================
# PROXY CONFIGURATION
# =============================================================================
# Configure proxy settings for the cluster if you're behind a corporate firewall
# Leave empty or comment out if no proxy is needed

# HTTP proxy URL - used for HTTP traffic
# Example: "http://proxy.company.com:8080"
# $http_proxy = ""

# HTTPS proxy URL - used for HTTPS traffic
# Example: "https://proxy.company.com:8080"
# $https_proxy = ""

# No proxy list - comma-separated list of hosts/domains that should bypass proxy
# Common entries: localhost, 127.0.0.1, local domains, cluster subnets
# Example: "localhost,127.0.0.1,.local,.company.com,10.0.0.0/8,192.168.0.0/16"
# $no_proxy = ""

# Additional no proxy entries - will be added to the default no_proxy list
# Use this to add extra domains without overriding the defaults
# Example: ".internal,.corp,.k8s.local"
# $additional_no_proxy = ""

# =============================================================================
# ANSIBLE CONFIGURATION
# =============================================================================
# Ansible verbosity level for debugging (uncomment to enable)
# Options: "v" (verbose), "vv" (more verbose), "vvv" (debug), "vvvv" (connection debug)
#$ansible_verbosity = "vvv"

# =============================================================================
# VIRTUAL MACHINE CONFIGURATION
# =============================================================================
# Prefix for VM instance names (will be followed by node number)
$instance_name_prefix = "k8s"

# Default CPU and memory settings for worker nodes
$vm_cpus = 8                    # Number of CPU cores per worker node
$vm_memory = 16384              # Memory in MB per worker node (16GB)

# Master/Control plane node resources
$kube_master_vm_cpus = 4        # CPU cores for Kubernetes master nodes
$kube_master_vm_memory = 4096   # Memory in MB for Kubernetes master nodes (4GB)

# UPM Control plane node resources (if using UPM)
$upm_control_plane_vm_cpus = 8      # CPU cores for UPM control plane
$upm_control_plane_vm_memory = 8192 # Memory in MB for UPM control plane (8GB)

# =============================================================================
# STORAGE CONFIGURATION
# =============================================================================
# Enable additional disks for worker nodes (useful for storage testing)
$kube_node_instances_with_disks = true

# Size of additional disks in MB (200GB in this example)
$kube_node_instances_with_disks_size = 204800

# Number of additional disks per node
$kube_node_instances_with_disks_number = 1

# Directory to store additional disk files
$kube_node_instances_with_disk_dir = ENV['HOME'] + "/.vagrant.d/upm_disks"

# Suffix for disk file names
$kube_node_instances_with_disk_suffix = "upm"

# =============================================================================
# CLUSTER TOPOLOGY
# =============================================================================
# Total number of nodes in the cluster (masters + workers)
$num_instances = 5

# Number of etcd instances (should be odd number: 1, 3, 5, etc.)
$etcd_instances = 1

# Number of Kubernetes master/control plane instances
$kube_master_instances = 1

# Number of UPM control instances (if using UPM)
$upm_ctl_instances = 1

# =============================================================================
# SYSTEM CONFIGURATION
# =============================================================================
# Timezone for all VMs
$time_zone = "Asia/Shanghai"

# Ntp Sever Configuration
$ntp_enabled ||= "True"
$ntp_manage_config ||= "True"

# Operating system for VMs
# Supported options: "ubuntu2004", "ubuntu2204", "centos7", "centos8", "rockylinux8", "rockylinux9", etc.
$os = "rockylinux9"

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================
# Network type: "private_network" (host-only) or "public_network" (bridged)
$vm_network = "private_network"

# Network subnet (first 3 octets)
$subnet = "10.37.129"

# Starting IP for the 4th octet (VMs will get IPs starting from this number)
$subnet_split4 = 100

# Network configuration
$netmask = "255.255.255.0"      # Subnet mask
$gateway = "10.37.129.1"        # Default gateway
$dns_server = "8.8.8.8"         # DNS server

# Bridge network interface (required when using "public_network")
# Example: "en0" on macOS, "eth0" on Linux
$bridge_nic = ""

# =============================================================================
# KUBERNETES CONFIGURATION
# =============================================================================
# Container Network Interface (CNI) plugin
# Options: "calico", "flannel", "weave", "cilium", "kube-ovn", etc.
$network_plugin = "calico"

# Enable multi-networking support
$multi_networking = "False"

# Ansible inventory directory
$inventory = "inventory/sample"

# Shared folders between host and VMs (empty by default)
$shared_folders = {}

# Kubernetes version to install
$kube_version = "1.33.1"