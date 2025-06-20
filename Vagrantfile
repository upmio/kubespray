# -*- mode: ruby -*-
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Kubespray Vagrant Configuration
# For help on using kubespray with vagrant, check out docs/vagrant.md

require 'fileutils'
require 'securerandom'

# Ensure minimum Vagrant version for compatibility
Vagrant.require_version ">= 2.0.0"

# Configuration file path - can be overridden via environment variable
CONFIG = File.join(File.dirname(__FILE__), ENV['KUBESPRAY_VAGRANT_CONFIG'] || 'vagrant/config.rb')

# Supported operating systems with their respective Vagrant boxes and default users
SUPPORTED_OS = {
  "ubuntu2204"          => {box: "generic/ubuntu2204",         user: "vagrant"},
  "ubuntu2404"          => {box: "bento/ubuntu-24.04",         user: "vagrant"},
  "rockylinux8"         => {box: "bento/rockylinux-8",         user: "vagrant"},
  "rockylinux9"         => {box: "bento/rockylinux-9",         user: "vagrant"},
  "opensuse"            => {box: "opensuse/Leap-15.4.x86_64",  user: "vagrant"},
  "opensuse-tumbleweed" => {box: "opensuse/Tumbleweed.x86_64", user: "vagrant"},
  "oraclelinux8"        => {box: "generic/oracle8",            user: "vagrant"},
  "rhel8"               => {box: "generic/rhel8",              user: "vagrant"},
}.freeze

# Load custom configuration file if it exists
begin
  require CONFIG if File.exist?(CONFIG)
rescue => e
  puts "Error loading config file #{CONFIG}: #{e.message}"
  exit 1
end

# =============================================================================
# DEFAULT CONFIGURATION VALUES
# These can be overridden in vagrant/config.rb or via environment variables
# =============================================================================

# Cluster Configuration
$num_instances ||= 3                           # Total number of VM instances
$instance_name_prefix ||= "k8s"                 # Prefix for VM names (e.g., k8s-1, k8s-2)
$etcd_instances ||= [$num_instances, 3].min     # Number of etcd nodes (max 3)
$kube_master_instances ||= [$num_instances, 2].min  # Number of master nodes (max 2)
$kube_node_instances ||= $num_instances         # All nodes are kube nodes
$upm_ctl_instances ||= 1                       # Number of UPM controller nodes

# VM Resource Configuration
$vm_gui ||= false                              # Enable/disable GUI for VMs
$vm_memory ||= 16384                           # Default memory for worker nodes (MB)
$vm_cpus ||= 8                                 # Default CPU cores for worker nodes
$kube_master_vm_memory ||= 4096                # Memory for master nodes (MB)
$kube_master_vm_cpus ||= 4                     # CPU cores for master nodes
$upm_control_plane_vm_memory ||= 32768         # Memory for UPM control plane (MB)
$upm_control_plane_vm_cpus ||= 8               # CPU cores for UPM control plane

# Network Configuration
$vm_network ||= "private_network"              # Network type: private_network or public_network
$subnet ||= "172.18.8"                         # IP subnet for VMs
$subnet_split4 ||= 100                         # Starting IP offset (e.g., 172.18.8.101)
$subnet_ipv6 ||= "fd3c:b398:0698:0756"         # IPv6 subnet prefix
$netmask ||= "255.255.255.0"                   # Network mask
$gateway ||= "172.18.8.1"                      # Default gateway
$dns_server ||= "8.8.8.8"                      # DNS server
$bridge_nic ||= "en0"                          # Bridge network interface for public_network

# System Configuration
$time_zone ||= "Asia/Shanghai"                 # System timezone
$os ||= "rockylinux9"                          # Default operating system

# Ntp Sever Configuration
$ntp_enabled ||= "True"
$ntp_manage_config ||= "True"

# Kubernetes Configuration
$network_plugin ||= "calico"                   # CNI plugin (calico, flannel, etc.)
$multi_networking ||= "False"                  # Enable Multus CNI for multi-networking
$kube_version ||= "1.32.5"                     # Kubernetes version

# Download and Cache Configuration
$download_run_once ||= "True"                  # Download binaries only once
$download_force_cache ||= "False"              # Force use of cache
$local_path_provisioner_enabled ||= "False"    # Enable local path provisioner
$local_path_provisioner_claim_root ||= "/opt/local-path-provisioner/"  # Local path root

# Storage Configuration (libvirt only)
$kube_node_instances_with_disks ||= false      # Add extra disks to worker nodes
$kube_node_instances_with_disks_size ||= "20G" # Size of additional disks
$kube_node_instances_with_disks_number ||= 2   # Number of additional disks per node
$kube_node_instances_with_disk_dir ||= ENV['HOME']  # Directory for disk files
$kube_node_instances_with_disk_suffix ||= 'xxxxxxxx'  # Suffix for disk files

# Virtualization Configuration
$libvirt_nested ||= false                      # Enable nested virtualization
$provider ||= ENV['VAGRANT_DEFAULT_PROVIDER'] || ""  # Preferred provider

# Ansible Configuration
$ansible_verbosity ||= false                   # Ansible verbosity level
$ansible_tags ||= ENV['VAGRANT_ANSIBLE_TAGS'] || ""  # Ansible tags to run
$playbook ||= "cluster.yml"                    # Main Ansible playbook
$extra_vars ||= {}                             # Additional Ansible variables

# Security Configuration
$vagrant_pwd ||= ENV['VAGRANT_PASSWORD'] || SecureRandom.hex(8)  # Vagrant user password

# Directory Configuration
$shared_folders ||= {}                         # Additional shared folders
$forwarded_ports ||= {}                        # Port forwarding configuration
$vagrant_dir ||= File.join(File.dirname(__FILE__), ".vagrant")  # Vagrant working directory

# =============================================================================
# CONFIGURATION VALIDATION AND SETUP
# =============================================================================

# Calculate the starting index for different node types
node_instances_begin = [$etcd_instances, $kube_master_instances].max
host_vars = {}

# Validate configuration parameters
def validate_configuration
  # Validate OS support
  unless SUPPORTED_OS.key?($os)
    puts "ERROR: Unsupported OS: #{$os}"
    puts "Supported OS are: #{SUPPORTED_OS.keys.join(', ')}"
    exit 1
  end

  # Validate resource configuration
  if $vm_memory < 2048
    puts "WARNING: VM memory (#{$vm_memory}MB) is below recommended minimum (2048MB)"
  end

  if $num_instances > 10
    puts "WARNING: Large number of instances (#{$num_instances}) may consume significant resources"
  end

  # Validate network configuration
  unless ["private_network", "public_network"].include?($vm_network)
    puts "ERROR: Invalid network type: #{$vm_network}. Must be 'private_network' or 'public_network'"
    exit 1
  end
end

# Run configuration validation
validate_configuration

# Set the Vagrant box based on selected OS
$box = SUPPORTED_OS[$os][:box]

# Setup inventory path - use sample if not specified
$inventory = "inventory/sample" unless $inventory
$inventory = File.absolute_path($inventory, File.dirname(__FILE__))

# Setup Ansible inventory symlink if hosts.ini doesn't exist
if !File.exist?(File.join(File.dirname($inventory), "hosts.ini"))
  $vagrant_ansible = File.join(File.absolute_path($vagrant_dir), "provisioners", "ansible")
  FileUtils.mkdir_p($vagrant_ansible) unless File.exist?($vagrant_ansible)
  $vagrant_inventory = File.join($vagrant_ansible, "inventory")
  FileUtils.rm_f($vagrant_inventory)
  FileUtils.ln_s($inventory, $vagrant_inventory)
end

# Configure proxy settings if vagrant-proxyconf plugin is available
if Vagrant.has_plugin?("vagrant-proxyconf")
  # Default no_proxy settings for common private networks
  $no_proxy = ENV['NO_PROXY'] || ENV['no_proxy'] || 
              "localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,::1"
  # Add VM IPs to no_proxy list
  (1..$num_instances).each do |i|
    $no_proxy += ",#{$subnet}.#{i+$subnet_split4}"
  end
end

# =============================================================================
# HELPER METHODS
# =============================================================================

# Configure VM network based on network type
def configure_vm_network(node, ip, instance_num)
  network_options = {
    ip: ip,
    netmask: $netmask,
    libvirt__guest_ipv6: 'yes',
    libvirt__ipv6_address: "#{$subnet_ipv6}::#{instance_num+100}",
    libvirt__ipv6_prefix: "64",
    libvirt__forward_mode: "none",
    libvirt__dhcp_enabled: false
  }

  if $vm_network == "public_network"
    network_options[:bridge] = $bridge_nic
    node.vm.network :public_network, **network_options
  else
    node.vm.network :private_network, **network_options
  end
end

# Configure Rocky Linux specific network settings
def configure_rocky_network(node)
  network_script = if $vm_network == "public_network"
    <<-SHELL
      # Configure public network for Rocky Linux
      sudo nmcli connection modify "eth0" ipv4.gateway ""
      sudo nmcli connection modify "eth0" ipv4.never-default yes
      sudo nmcli connection modify "System eth1" +ipv4.routes "0.0.0.0/0 #{$gateway}"
      sudo nmcli connection modify "System eth1" ipv4.gateway "#{$gateway}"
      sudo nmcli connection up "eth0"
      sudo nmcli connection up "System eth1"
    SHELL
  else
    <<-SHELL
      # Configure private network for Rocky Linux
      sudo nmcli connection modify "System eth1" ipv4.gateway "#{$gateway}"
      sudo nmcli connection up "System eth1"
    SHELL
  end

  # Common DNS configuration for Rocky Linux
  network_script += <<-SHELL
    sudo echo -e "[main]\ndns=default\n\n[global-dns-domain-*]\nservers=#{$dns_server}" | sudo tee /etc/NetworkManager/conf.d/dns.conf
    sudo systemctl restart NetworkManager
  SHELL

  node.vm.provision "shell", inline: network_script
end

# Configure Ansible provisioner
def configure_ansible_provisioner(node, host_vars)
  node.vm.provision "ansible" do |ansible|
    ansible.playbook = $playbook
    ansible.compatibility_mode = "2.0"
    ansible.verbose = $ansible_verbosity
    
    # Set inventory path if hosts.ini exists
    ansible_inventory_path = File.join($inventory, "hosts.ini")
    ansible.inventory_path = ansible_inventory_path if File.exist?(ansible_inventory_path)
    
    # Ansible configuration
    ansible.become = true
    ansible.limit = "all,localhost"
    ansible.host_key_checking = false
    
    # Optimize Ansible performance
    max_forks = [$num_instances, 10].min
    ansible.raw_arguments = ["--forks=#{max_forks}", "--flush-cache", "-e ansible_become_pass=vagrant"]
    
    # Set host variables and extra variables
    ansible.host_vars = host_vars
    ansible.extra_vars = ($extra_vars || {}).merge({
      'ansible_python_interpreter' => '/usr/bin/python3'
    })
    
    # Apply Ansible tags if specified
    ansible.tags = [$ansible_tags] unless $ansible_tags.empty?
    
    # Define Ansible groups for Kubernetes cluster
    ansible.groups = {
      "etcd" => ["#{$instance_name_prefix}-[1:#{$etcd_instances}]"],
      "kube_control_plane" => ["#{$instance_name_prefix}-[1:#{$kube_master_instances}]"],
      "kube_node" => ["#{$instance_name_prefix}-[1:#{$kube_node_instances}]"],
      "k8s_cluster:children" => ["kube_control_plane", "kube_node"]
    }
  end
end

# =============================================================================
# VAGRANT CONFIGURATION
# =============================================================================

Vagrant.configure("2") do |config|
  # Base VM configuration
  config.vm.box = $box
  config.vm.box_url = SUPPORTED_OS[$os][:box_url] if SUPPORTED_OS[$os].has_key?(:box_url)
  config.ssh.username = SUPPORTED_OS[$os][:user]

  # Disable VirtualBox Guest Additions auto-update to avoid conflicts
  config.vbguest.auto_update = false if Vagrant.has_plugin?("vagrant-vbguest")

  # Use Vagrant's insecure key for SSH (development only)
  config.ssh.insert_key = false

  (1..$num_instances).each do |i|
    config.vm.define vm_name = "%s-%01d" % [$instance_name_prefix, i] do |node|
      node.vm.hostname = vm_name
      if Vagrant.has_plugin?("vagrant-proxyconf")
        node.proxy.http     = ENV['HTTP_PROXY'] || ENV['http_proxy'] || ""
        node.proxy.https    = ENV['HTTPS_PROXY'] || ENV['https_proxy'] ||  ""
        node.proxy.no_proxy = $no_proxy
      end

      # Determine VM resources based on node type
      memory_size, cpu_num = if i <= node_instances_begin
        # Master/Control plane nodes
        ["#{$kube_master_vm_memory}", "#{$kube_master_vm_cpus}"]
      elsif i > node_instances_begin && i <= node_instances_begin + $upm_ctl_instances
        # UPM control plane nodes
        ["#{$upm_control_plane_vm_memory}", "#{$upm_control_plane_vm_cpus}"]
      else
        # Worker nodes
        ["#{$vm_memory}", "#{$vm_cpus}"]
      end

      ["vmware_fusion", "vmware_workstation"].each do |vmware|
        node.vm.provider vmware do |v|
          v.vmx['memsize'] = memory_size
          v.vmx['numvcpus'] = cpu_num
        end
      end

      node.vm.provider "parallels" do |prl|
        prl.memory = memory_size
        prl.cpus = cpu_num
        prl.linked_clone = true
        prl.update_guest_tools = false
        prl.check_guest_tools = false
      end

      node.vm.provider :virtualbox do |vb|
        vb.memory = memory_size
        vb.cpus = cpu_num
        vb.gui = $vm_gui
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--vram", "8"] # ubuntu defaults to 256 MB which is a waste of precious RAM
        vb.customize ["modifyvm", :id, "--audio", "none"]
      end

      node.vm.provider :libvirt do |lv|
        lv.nested = $libvirt_nested
        lv.cpu_mode = "host-model"
        lv.memory = memory_size
        lv.cpus = cpu_num
        lv.default_prefix = 'kubespray'
        # Fix kernel panic on fedora 28
        if $os == "fedora"
          lv.cpu_mode = "host-passthrough"
        end
      end

      if $kube_node_instances_with_disks && i > node_instances_begin
        # install lvm2 package
        node.vm.provision "shell", inline: "sudo dnf install -y lvm2"
        # Libvirt
        driverletters = ('a'..'z').to_a
        disk_dir = "#{$kube_node_instances_with_disk_dir}"
        node.vm.provider :libvirt do |lv|
          # always make /dev/sd{a/b/c} so that CI can ensure that
          # virtualbox and libvirt will have the same devices to use for OSDs
          (1..$kube_node_instances_with_disks_number).each do |d|
            disk_path = "#{disk_dir}/disk-#{i}-#{driverletters[d]}-#{$kube_node_instances_with_disk_suffix}.disk"
            lv.storage :file, :device => "hd#{driverletters[d]}", :path => disk_path, :size => $kube_node_instances_with_disks_size, :bus => "scsi"
          end
        end
        node.vm.provider :virtualbox do |vb|
          # always make /dev/sd{a/b/c} so that CI can ensure that
          # virtualbox and libvirt will have the same devices to use for OSDs
          (1..$kube_node_instances_with_disks_number).each do |d|
            disk_path = "#{disk_dir}/disk-#{i}-#{driverletters[d]}-#{$kube_node_instances_with_disk_suffix}.disk"
            if !File.exist?(disk_path)
              vb.customize ['createhd', '--filename', disk_path, '--size', $kube_node_instances_with_disks_size] # 10GB disk
            end
            vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', d, '--device', 0, '--type', 'hdd', '--medium', disk_path, '--nonrotational', 'on', '--mtype', 'normal']
          end
        end

        node.vm.provider :parallels do |prl|
          (1..$kube_node_instances_with_disks_number).each do |d|
            prl.customize ['set', :id, '--device-add', 'hdd', '--iface', 'nvme', '--size', $kube_node_instances_with_disks_size, '--type', 'expand']
          end
        end
      end

      $forwarded_ports.each do |guest, host|
        node.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
      end

      if ["rhel8"].include? $os
        # Vagrant synced_folder rsync options cannot be used for RHEL boxes as Rsync package cannot
        # be installed until the host is registered with a valid Red Hat support subscription
        node.vm.synced_folder ".", "/vagrant", disabled: false
        $shared_folders.each do |src, dst|
          node.vm.synced_folder src, dst
        end
      else
        node.vm.synced_folder ".", "/vagrant", disabled: false, type: "rsync", rsync__args: ['--verbose', '--archive', '--delete', '-z'] , rsync__exclude: ['.git','venv']
        $shared_folders.each do |src, dst|
          node.vm.synced_folder src, dst, type: "rsync", rsync__args: ['--verbose', '--archive', '--delete', '-z']
        end
      end

      ip = "#{$subnet}.#{i+$subnet_split4}"
      # Configure network based on selected network type
      configure_vm_network(node, ip, i)

      # Configure Rocky Linux specific network settings
      configure_rocky_network(node) if ["rockylinux8", "rockylinux9"].include?($os)

      # if provider = virtualbox , set ethtool -K net device tx-checksum-ip-generic off
      if $provider == "virtualbox"
        if ["rockylinux8","rockylinux9"].include? $os
          node.vm.provision "shell", inline: <<-SHELL
            sudo ethtool -K eth0 tx-checksum-ip-generic off
            sudo ethtool -K eth1 tx-checksum-ip-generic off
            sudo nmcli conn modify eth0 ethtool.feature-tx-checksum-ip-generic off
            sudo nmcli conn modify 'System eth1' ethtool.feature-tx-checksum-ip-generic off
          SHELL
        end
      end

      # Disable swap for each vm
      node.vm.provision "shell", inline: "swapoff -a"

      # Set password for vagrant user
      node.vm.provision "shell", inline: "echo 'vagrant:#{$vagrant_pwd}' | sudo chpasswd"

      # Create symlinks for Kubernetes CLI tools
      node.vm.provision "shell", privileged: true, inline: <<-SHELL
        # Create symlinks for Kubernetes CLI tools
        echo "INFO: Creating symlinks for Kubernetes CLI tools..."
        declare -a k8s_tools=("kubectl" "helm" "nerdctl" "crictl")
        for tool in "${k8s_tools[@]}"; do
          source_path="/usr/local/bin/$tool"
          target_path="/usr/bin/$tool"
          echo "INFO: Creating symlink: $source_path -> $target_path"
          ln -sf "$source_path" "$target_path"
        done
        echo "INFO: Symlinks for Kubernetes CLI tools created successfully."
      SHELL
      # OS-specific configurations
      configure_os_specific_settings(node, config)

      # Set system timezone
      node.vm.provision "shell", inline: "timedatectl set-timezone #{$time_zone}", 
                        name: "Set timezone to #{$time_zone}"

      host_vars[vm_name] = {
        "ip": ip,
        "kube_network_plugin": $network_plugin,
        "kube_network_plugin_multus": $multi_networking,
        "download_run_once": $download_run_once,
        "download_localhost": "False",
        "download_cache_dir": ENV['HOME'] + "/kubespray_cache",
        # Make kubespray cache even when download_run_once is false
        "download_force_cache": $download_force_cache,
        # Keeping the cache on the nodes can improve provisioning speed while debugging kubespray
        "download_keep_remote_cache": "False",
        "docker_rpm_keepcache": "1",
        # These two settings will put kubectl and admin.config in $inventory/artifacts
        "kubeconfig_localhost": "True",
        "kubectl_localhost": "True",
        "local_path_provisioner_enabled": "#{$local_path_provisioner_enabled}",
        "local_path_provisioner_claim_root": "#{$local_path_provisioner_claim_root}",
        "ntp_enabled": "#{$ntp_enabled}",
        "ntp_manage_config": "#{$ntp_manage_config}",
        "helm_enabled": "True",
        "ansible_ssh_user": SUPPORTED_OS[$os][:user],
        "ansible_ssh_private_key_file": File.join(Dir.home, ".vagrant.d", "insecure_private_key"),
        "unsafe_show_logs": "True",
        "preinstall_selinux_state": "disabled",
        "kube_version": "#{$kube_version}"
      }

      # Add proxy configuration to host_vars if defined in config.rb
      if defined?($http_proxy) && !$http_proxy.to_s.empty?
        host_vars[vm_name]["http_proxy"] = $http_proxy
      end
      if defined?($https_proxy) && !$https_proxy.to_s.empty?
        host_vars[vm_name]["https_proxy"] = $https_proxy
      end
      if defined?($no_proxy) && !$no_proxy.to_s.empty?
        host_vars[vm_name]["no_proxy"] = $no_proxy
      end
      if defined?($additional_no_proxy) && !$additional_no_proxy.to_s.empty?
        host_vars[vm_name]["additional_no_proxy"] = $additional_no_proxy
      end

      # Display VM information for debugging
      puts "INFO: Configuring VM #{vm_name} with IP #{ip} (#{memory_size}MB RAM, #{cpu_num} CPUs)"

      # Execute Ansible provisioner only on the last VM to ensure all VMs are ready
      if i == $num_instances
        configure_ansible_provisioner(node, host_vars)
      end
    end
  end
end

# =============================================================================
# OS-SPECIFIC CONFIGURATION METHOD
# =============================================================================

# Configure OS-specific settings
def configure_os_specific_settings(node, config)
  # Re-enable IPv6 on Ubuntu systems where it's disabled by default
  if ["ubuntu2204", "ubuntu2404"].include?($os)
    node.vm.provision "shell", 
                      inline: "rm -f /etc/modprobe.d/local.conf",
                      name: "Remove IPv6 disable configuration"
    node.vm.provision "shell", 
                      inline: "sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf /etc/sysctl.conf",
                      name: "Remove IPv6 sysctl disable settings"
  end

  # Configure UEFI for Rocky Linux systems
  if ["rockylinux8", "rockylinux9"].include?($os)
    config.vm.provider "libvirt" do |domain|
      domain.loader = "/usr/share/OVMF/x64/OVMF_CODE.fd"
    end
  end

  # Disable firewalld on RHEL-based systems
  rhel_based_os = ["oraclelinux", "oraclelinux8", "rhel7", "rhel8", "rockylinux8", "rockylinux9"]
  if rhel_based_os.include?($os)
    node.vm.provision "shell", 
                      inline: "systemctl stop firewalld 2>/dev/null || true; systemctl disable firewalld 2>/dev/null || true",
                      name: "Disable firewalld service"
  end
end
