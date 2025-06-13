<!--
Copyright 2024 The Kubespray Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Kubespray Vagrant Configuration Guide

[]: # (Language Selector)
  <a href="./vagrant-configuration-guide.md">English</a> | <a href="./vagrant-configuration-guide_zh.md">中文</a>
</p>

# Kubespray Vagrant Configuration Guide

This guide provides a detailed overview of how to configure and use Vagrant with Kubespray to set up a Kubernetes cluster. Vagrant allows you to create and manage lightweight, reproducible, and portable development environments.

## Overview

Kubespray uses a `Vagrantfile` at the root of the repository to define the settings for the virtual machines (VMs). You can customize the Vagrant environment by creating a configuration file at `vagrant/config.rb`. If this file exists, the `Vagrantfile` will load it, allowing you to override default settings.

Alternatively, you can specify the path to a custom configuration file using the `KUBESPRAY_VAGRANT_CONFIG` environment variable.

## Getting Started

1. **Install Prerequisites**:

    * **Vagrant**: Download and install from the [official Vagrant website](https://www.vagrantup.com/downloads.html).
        *   **Verification**: Open a terminal or command prompt and run `vagrant --version`. You should see the installed Vagrant version.
    *   **Vagrant Provider (Hypervisor)**: This is the underlying virtualization software. **VirtualBox** is the primary recommended provider for this guide.
        *   **VirtualBox (Recommended)**:
            *   **Installation**: Download and install from the [official VirtualBox website](https://www.virtualbox.org/wiki/Downloads). It's advisable to also install the VirtualBox Extension Pack for full functionality.
            *   **Verification**: After installation, you should be able to run `VBoxManage --version` in a terminal, or simply open the VirtualBox application.
        *   **VMware Fusion** (macOS) / **VMware Workstation** (Windows/Linux) (Advanced): Commercial products, download from the [official VMware website](https://www.vmware.com/).
            *   **Verification**: Ensure the application can start and you can manually create a VM through its UI.
    *   **Vagrant Plugins (Optional but Recommended)**:
        *   `vagrant-proxyconf`: Manages proxy settings within guest VMs. Install with `vagrant plugin install vagrant-proxyconf`.
            *   **Verification**: Run `vagrant plugin list` to see if `vagrant-proxyconf` is listed.

2.  **Clone the Kubespray Repository**:
    ```bash
    git clone https://github.com/upmio/kubespray.git
    cd kubespray
    ```

3.  **Prepare Ansible Environment**

    Vagrant uses Ansible to provision the Kubernetes cluster on the created virtual machines. Therefore, you need to set up an Ansible environment on the host machine where you'll run `vagrant up`.

    **a. Clone Kubespray Repository (if not already done):**

    If you haven't cloned the Kubespray repository yet, do so now. The `Vagrantfile` and Ansible playbooks are part of this repository.

    ```bash
    # If not already in the kubespray directory
    # git clone https://github.com/upmio/kubespray.git
    # cd kubespray
    ```

    **b. Install Ansible and Dependencies:**

    It's highly recommended to use a Python virtual environment to install Ansible and its dependencies to avoid conflicts with system-wide packages.

    1.  **Create and Activate a Python Virtual Environment:**

        ```bash
        # Navigate to your Kubespray directory (e.g., where Vagrantfile is)
        # cd /path/to/kubespray
        python3 -m venv venv
        source venv/bin/activate
        ```
        Once activated, your shell prompt will typically change to indicate you're in the virtual environment (e.g., `(venv) your-prompt$`).

    2.  **Install Ansible and Required Python Packages:**

        Kubespray provides a `requirements.txt` file that lists compatible Ansible versions and other necessary Python libraries.

        ```bash
        # Ensure you are in the Kubespray root directory
        pip install -U -r requirements.txt
        ```

        This command will install the specific Ansible version tested with Kubespray, along with other dependencies like `jinja2`, `netaddr`, etc.

        *   **Python Version Compatibility**: Kubespray and Ansible have specific Python version requirements. If you encounter errors during installation, refer to the [official Kubespray Ansible documentation](../ansible/ansible.md#installing-ansible) for details on compatible Python and Ansible versions.

    With these steps completed, your Ansible environment is ready, and Vagrant will be able to use it to execute the Kubespray playbooks.

4.  **Customize Vagrant Configuration (config.rb)**
    *   Copy the sample configuration file:
        ```bash
        cp vagrant-config-sample.rb vagrant/config.rb
        ```
    *   Edit `vagrant/config.rb` to adjust parameters according to your needs. See the [Configuration Parameters](#configuration-parameters) section below for details.

5.  **Launch the Cluster**:
    ```bash
    vagrant up
    ```
    This command will download the specified VM image (if not already cached), create the virtual machines, and then run Ansible playbooks to deploy Kubernetes on them. This process can take a significant amount of time, especially on the first run.

6.  **Access the VMs**:
    You can SSH into any of the created VMs using:
    ```bash
    vagrant ssh <vm_name>
    ```
    VM names are typically prefixed with `$instance_name_prefix` (default `k8s`), so `k8s-1`, `k8s-2`, etc.
    For example, to SSH into the first node:
    ```bash
    vagrant ssh k8s-1
    ```

7.  **Destroy the Cluster**:
    To remove all VMs and associated resources created by Vagrant:
    ```bash
    vagrant destroy -f
    ```
    The `-f` flag forces destruction without prompting for confirmation.

## Configuration File (`vagrant/config.rb`)

The primary way to customize your Kubespray Vagrant setup is by creating and modifying `vagrant/config.rb`. This file is a Ruby script where you can set various global variables that the `Vagrantfile` uses.

The `Vagrantfile` first defines default values for these parameters. If `vagrant/config.rb` exists, it is loaded, and any variables defined within it will override the defaults.

**Example `vagrant/config.rb` entry**:
```ruby
# In vagrant/config.rb
$num_instances = 5  # Override the default number of VMs
$os = "ubuntu2204"  # Change the default OS for the VMs
```

## Configuration Parameters

Below is a detailed list of configurable parameters. You can set these in your `vagrant/config.rb` file. Each parameter's description includes its purpose, typical values, and default value if applicable.

### 1. Proxy Configuration

If your development environment is behind a corporate firewall, you may need to configure proxy settings for Vagrant and the guest VMs.

*   `$http_proxy` (String)
    *   **Purpose**: Specifies the URL of the HTTP proxy server.
    *   **Value**: A valid URL string, e.g., `"http://proxy.example.com:8080"`.
    *   **Default**: `""` (Empty string, meaning no HTTP proxy).
*   `$https_proxy` (String)
    *   **Purpose**: Specifies the URL of the HTTPS proxy server.
    *   **Value**: A valid URL string, e.g., `"https://proxy.example.com:8080"`.
    *   **Default**: `""` (Empty string, meaning no HTTPS proxy).
*   `$no_proxy` (String)
    *   **Purpose**: A comma-separated list of hostnames, IP addresses, or domains that should bypass the proxy.
    *   **Value**: A string like `"localhost,127.0.0.1,.internal.domain.com,192.168.0.0/16"`.
    *   **Default**: `ENV['NO_PROXY'] || ENV['no_proxy'] || "localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,::1"`. The `Vagrantfile` also automatically adds VM IPs and common private network ranges if the `vagrant-proxyconf` plugin is active.
*   `$additional_no_proxy` (String)
    *   **Purpose**: Allows you to append additional entries to the `$no_proxy` list without completely overriding the defaults.
    *   **Value**: A comma-separated string, e.g., `".mycorp,.k8s.local"`.
    *   **Default**: Not explicitly set in `Vagrantfile`, but can be defined in `vagrant-config-sample.rb`. Used for adding specific internal domains.

### 2. Ansible Configuration

These settings control how Vagrant executes Ansible to deploy the cluster.

*   `$ansible_verbosity` (Boolean or String)
    *   **Purpose**: Controls the verbosity of Ansible output during deployment.
    *   **Value**:
        *   `false`: Standard output.
        *   `true`: Basic verbose output (equivalent to `-v`).
        *   `"v"`, `"vv"`, `"vvv"` (debug), `"vvvv"` (connection debug): Increasingly verbose output levels.
    *   **Default**: `false`.
*   `$ansible_tags` (String)
    *   **Purpose**: Specifies a comma-separated list of Ansible tags. Only tasks with these tags (or `always`) will be run.
    *   **Value**: A string like `"etcd,network"` to run only etcd and network-related tasks, or `"download"` for download-only tasks.
    *   **Default**: `ENV['VAGRANT_ANSIBLE_TAGS'] || ""` (runs all tasks if environment variable is not set).
*   `$playbook` (String)
    *   **Purpose**: Defines the main Ansible playbook file to use for cluster setup.
    *   **Value**: Path to the playbook file, relative to the Kubespray root. E.g., `"cluster.yml"` for a full cluster, or `"remove-node.yml"` for node removal tasks.
    *   **Default**: `"cluster.yml"`.
*   `$extra_vars` (Hash)
    *   **Purpose**: A Ruby hash containing additional variables to pass to Ansible. These can override defaults in Kubespray or provide custom configurations.
    *   **Value**: A Ruby hash, e.g., `$extra_vars = {'kube_version' => 'v1.28.5', 'deploy_netchecker' => true}`.
    *   **Default**: `{}` (Empty hash).

### 3. Virtual Machine (VM) Configuration

General settings for the virtual machines that will form the Kubernetes cluster.

*   `$instance_name_prefix` (String)
    *   **Purpose**: Prefix for the hostnames of the VMs created by Vagrant.
    *   **Value**: Any string, e.g., `"k8s"` results in VMs named `k8s-1`, `k8s-2`, etc.
    *   **Default**: `"k8s"`.
*   `$vm_memory` (Integer)
    *   **Purpose**: Default memory allocation in MB for Kubernetes worker nodes.
    *   **Value**: An integer representing MB. Recommended minimum depends on workload, but typically `2048` (2GB) or higher.
    *   **Default**: `16384` (16GB). This is a generous default; adjust based on your host capacity and cluster needs.
*   `$vm_cpus` (Integer)
    *   **Purpose**: Default number of CPU cores allocated to Kubernetes worker nodes.
    *   **Value**: An integer. Recommended minimum is `2`.
    *   **Default**: `8`. Adjust based on host capacity.
*   `$kube_master_vm_memory` (Integer)
    *   **Purpose**: Memory allocation in MB for Kubernetes master/control-plane nodes.
    *   **Value**: An integer. Recommended minimum `2048` (2GB) for a single master, more for HA setups.
    *   **Default**: `4096` (4GB).
*   `$kube_master_vm_cpus` (Integer)
    *   **Purpose**: Number of CPU cores for Kubernetes master/control-plane nodes.
    *   **Value**: An integer. Recommended minimum is `2`.
    *   **Default**: `4`.
*   `$upm_control_plane_vm_memory` (Integer)
    *   **Purpose**: Memory in MB for UPM (User Provided Machine) control plane nodes, if you are using this specific UPM feature (less common for typical Vagrant setups).
    *   **Value**: An integer.
    *   **Default**: `32768` (32GB) in `Vagrantfile`, `8192` (8GB) in `vagrant-config-sample.rb`. This parameter is usually relevant for more advanced or specific UPM scenarios.
*   `$upm_control_plane_vm_cpus` (Integer)
    *   **Purpose**: Number of CPU cores for UPM control plane nodes.
    *   **Value**: An integer.
    *   **Default**: `8`.
*   `$vm_gui` (Boolean)
    *   **Purpose**: Enables or disables the graphical user interface (GUI) for the VMs. This primarily applies to the VirtualBox provider.
    *   **Value**: `true` (enable GUI) or `false` (headless mode).
    *   **Default**: `false`.
*   `$provider` (String)
    *   **Purpose**: Specifies the preferred Vagrant provider if multiple are installed (e.g., VirtualBox, VMware).
    *   **Value**: String, e.g., `"virtualbox"`, `"vmware_fusion"`, `"vmware_workstation"`, `"parallels"`.
    *   **Default**: `ENV['VAGRANT_DEFAULT_PROVIDER'] || ""` (If empty or env var not set, Vagrant attempts auto-selection, often defaulting to VirtualBox if available).

### 4. Storage Configuration

Configure additional virtual disks for worker nodes. This is useful for testing distributed storage solutions or applications requiring persistent local storage.

*   `$kube_node_instances_with_disks` (Boolean)
    *   **Purpose**: If `true`, additional virtual disks will be created and attached to worker nodes.
    *   **Value**: `true` or `false`.
    *   **Default**: `false` in `Vagrantfile`, but `true` in `vagrant-config-sample.rb` to highlight the feature.
*   `$kube_node_instances_with_disks_size` (String or Integer)
    *   **Purpose**: Specifies the size of each additional disk.
    *   **Value**: String with unit (e.g., `"20G"` for 20GB, `"500M"` for 500MB) or an integer representing size in MB (e.g., `20480` for 20GB).
    *   **Default**: `"20G"` in `Vagrantfile`, `204800` (200GB) in `vagrant-config-sample.rb`. The sample file shows a larger size, potentially for specific testing scenarios.
*   `$kube_node_instances_with_disks_number` (Integer)
    *   **Purpose**: The number of additional disks to attach to each eligible worker node.
    *   **Value**: Integer, e.g., `1`, `2`, `3`.
    *   **Default**: `2` in `Vagrantfile`, `1` in `vagrant-config-sample.rb`.
*   `$kube_node_instances_with_disk_dir` (String)
    *   **Purpose**: Directory on the host machine where virtual disk image files will be stored.
    *   **Value**: A valid path string, e.g., `ENV['HOME'] + "/.vagrant.d/my_disks"`.
    *   **Default**: `ENV['HOME']` in `Vagrantfile`, `ENV['HOME'] + "/.vagrant.d/upm_disks"` in `vagrant-config-sample.rb`. Ensure this directory exists and has sufficient space.
*   `$kube_node_instances_with_disk_suffix` (String)
    *   **Purpose**: Suffix for the disk image filenames, helping to identify them.
    *   **Value**: A string, e.g., `"disk"`, `"data"`.
    *   **Default**: `'xxxxxxxx'` (placeholder, suggesting it might be dynamically generated or require user input) in `Vagrantfile`, `"upm"` in `vagrant-config-sample.rb`.

### 5. Cluster Topology

Defines the number of VMs in your Kubernetes cluster and their roles (etcd, master, worker).

*   `$num_instances` (Integer)
    *   **Purpose**: Total number of VM instances to create for the cluster.
    *   **Value**: An integer. For a minimal HA setup, typically at least `3` (e.g., 3 etcd, 2 masters, 3 workers, with some nodes potentially sharing roles).
    *   **Default**: `3`.
*   `$etcd_instances` (Integer)
    *   **Purpose**: Specifies the number of VMs designated as etcd nodes. For High Availability (HA), this should be an odd number (e.g., 1, 3, 5).
    *   **Value**: An integer. `Vagrantfile` logic defaults this to `min($num_instances, 3)`.
    *   **Default**: `[$num_instances, 3].min`. For `$num_instances = 1`, it's 1. For `$num_instances = 2`, it's 2 (not HA for etcd). For `$num_instances >= 3`, it's 3.
*   `$kube_master_instances` (Integer)
    *   **Purpose**: Specifies the number of VMs designated as Kubernetes master/control-plane nodes.
    *   **Value**: An integer. `1` for single master, `2` or more for HA (typically `2` or `3` in Vagrant setups). `Vagrantfile` logic defaults this to `min($num_instances, 2)`.
    *   **Default**: `[$num_instances, 2].min`. For `$num_instances = 1`, it's 1. For `$num_instances >= 2`, it's 2.
*   `$kube_node_instances` (Integer)
    *   **Purpose**: Number of VMs that will act as Kubernetes worker nodes. These are the nodes where your application Pods will run.
    *   **Value**: An integer, up to `$num_instances`. Nodes can assume multiple roles (e.g., masters can also be workers if not tainted).
    *   **Default**: `$num_instances` (meaning all created VMs are initially considered potential worker nodes in the inventory).
*   `$upm_ctl_instances` (Integer)
    *   **Purpose**: Number of UPM (User Provided Machine) controller nodes. This is specific to the UPM feature.
    *   **Value**: An integer, typically `1` if using UPM.
    *   **Default**: `1`.

### 6. System Configuration

General system-level settings for the guest VMs.

*   `$time_zone` (String)
    *   **Purpose**: Sets the system timezone for all VMs.
    *   **Value**: A valid Olson timezone string, e.g., `"Asia/Shanghai"`, `"UTC"`, `"America/New_York"`.
    *   **Default**: `"Asia/Shanghai"`.
*   `$os` (String)
    *   **Purpose**: Specifies the operating system and Vagrant box to use for the VMs.
    *   **Value**: Must be one of the keys defined in the `SUPPORTED_OS` hash within the `Vagrantfile`. Examples:
        *   `"ubuntu2204"` (maps to `generic/ubuntu2204` box)
        *   `"ubuntu2404"` (maps to `bento/ubuntu-24.04` box)
        *   `"rockylinux8"` (maps to `bento/rockylinux-8` box)
        *   `"rockylinux9"` (maps to `bento/rockylinux-9` box)
        *   `"opensuse"` (maps to `opensuse/Leap-15.4.x86_64` box)
        *   `"oraclelinux8"` (maps to `generic/oracle8` box)
        *   Check the `Vagrantfile` for the full, up-to-date list and corresponding box names.
    *   **Default**: `"rockylinux9"`.
*   `$vagrant_pwd` (String)
    *   **Purpose**: Sets the password for the default `vagrant` user inside the VMs.
    *   **Value**: A password string. If not set, a random password is generated.
    *   **Default**: `ENV['VAGRANT_PASSWORD'] || SecureRandom.hex(8)` (uses environment variable if set, otherwise a random 16-character hex string).

### 7. Network Configuration

Defines the network settings for the VMs, including IP addressing and connectivity.

*   `$vm_network` (String)
    *   **Purpose**: Determines the type of network Vagrant will configure for the VMs.
    *   **Value**:
        *   `"private_network"`: Creates a host-only network. VMs can communicate with each other and the host, but are not directly accessible from the external network.
        *   `"public_network"`: Bridges the VM's network interface to one of the host's physical interfaces, making the VM appear as a separate device on the host's network.
    *   **Default**: `"private_network"`.
*   `$subnet` (String)
    *   **Purpose**: The first three octets of the IP address range for VMs when using `private_network`.
    *   **Value**: A string like `"172.18.8"` or `"192.168.56"`.
    *   **Default**: `"172.18.8"`.
*   `$subnet_split4` (Integer)
    *   **Purpose**: The starting value for the fourth octet of VM IP addresses. IPs will be assigned sequentially starting from `$subnet.$subnet_split4 + 1`.
    *   **Value**: An integer, typically between `1` and `254`. Ensure it doesn't conflict with other devices if using `public_network` or an existing host-only network.
    *   **Default**: `100` (so IPs start from `172.18.8.101`, `172.18.8.102`, etc.).
*   `$subnet_ipv6` (String)
    *   **Purpose**: IPv6 subnet prefix for the VMs. This is generally less critical for VirtualBox-based private networks unless specifically configured.
    *   **Value**: A valid IPv6 prefix, e.g., `"fd3c:b398:0698:0756"`.
    *   **Default**: `"fd3c:b398:0698:0756"`.
*   `$netmask` (String)
    *   **Purpose**: The netmask for the private network.
    *   **Value**: A string like `"255.255.255.0"` (for a /24 network).
    *   **Default**: `"255.255.255.0"`.
*   `$gateway` (String)
    *   **Purpose**: The default gateway IP address for the VMs on the private network. This is typically the `.1` address of the chosen subnet.
    *   **Value**: An IP address string, e.g., `"172.18.8.1"`.
    *   **Default**: `"172.18.8.1"`.
*   `$dns_server` (String)
    *   **Purpose**: DNS server IP address to be configured in the VMs.
    *   **Value**: An IP address string, e.g., `"8.8.8.8"` (Google Public DNS) or your internal DNS server.
    *   **Default**: `"8.8.8.8"`.
*   `$bridge_nic` (String)
    *   **Purpose**: Specifies the host network interface to use for bridging when `$vm_network` is set to `"public_network"`.
    *   **Value**: Name of a network interface on the host, e.g., `"en0"` (common Wi-Fi/Ethernet on macOS), `"eth0"` (common Ethernet on Linux).
    *   **Default**: `""` (Empty string, Vagrant will typically prompt for selection). You will likely need to change this based on your host OS and network configuration.
*   `$forward_ports` (Array)
    *   **Purpose**: An array of hashes defining port forwarding rules from the host to guest VMs.
    *   **Value**: E.g., `[{ guest: 80, host: 8080 }, { guest: 443, host: 8443, protocol: "tcp", auto_correct: true }]`.
    *   **Default**: `[]` (Empty array).

### 8. Kubernetes Configuration

Parameters that directly influence the Kubernetes cluster deployed by Kubespray.

*   `$network_plugin` (String)
    *   **Purpose**: Selects the CNI (Container Network Interface) plugin for Pod networking in Kubernetes.
    *   **Value**: A string identifying a supported CNI plugin. Common options:
        *   `"calico"` (Default, feature-rich, supports network policies)
        *   `"flannel"` (Simpler, VXLAN-based overlay network)
        *   `"cilium"` (eBPF-based, advanced networking and security)
        *   `"kube-ovn"` (OVN-based, provides advanced SDN capabilities)
        *   `"weave"` (Another alternative, offers encryption features)
    *   **Default**: `"calico"`.
*   `$multi_networking` (String)
    *   **Purpose**: Enables support for multiple CNI plugins via Multus CNI, allowing Pods to attach to multiple networks.
    *   **Value**: `"True"` or `"true"` to enable, `"False"` or `"false"` to disable.
    *   **Default**: `"False"`.
*   `$kube_version` (String)
    *   **Purpose**: Specifies the version of Kubernetes to deploy.
    *   **Value**: A valid Kubernetes version number, e.g., `"v1.28.5"`. Consult Kubespray documentation for supported versions.
    *   **Default**: `"latest"` (which usually resolves to the latest stable version supported by Kubespray, depending on Kubespray's version).
*   `$container_manager` (String)
    *   **Purpose**: Selects the container runtime to be used on Kubernetes nodes.
    *   **Value**:
        *   `"containerd"` (Recommended, lightweight and efficient)
        *   `"crio"` (CRI-O, another CRI implementation focused on Kubernetes)
        *   `"docker"` (Legacy option, but DockerShim is deprecated by Kubernetes, so not recommended for new clusters)
    *   **Default**: `"containerd"`.
*   `$etcd_deployment_type` (String)
    *   **Purpose**: Defines how etcd is deployed.
    *   **Value**:
        *   `"kubeadm"`: etcd as static Pods managed by kubelet (on control-plane nodes).
        *   `"host"`: etcd runs as systemd services directly on etcd nodes.
    *   **Default**: `"kubeadm"`.
*   `$kubelet_deployment_type` (String)
    *   **Purpose**: Specifies how the kubelet is deployed.
    *   **Value**:
        *   `"host"`: kubelet runs as a systemd service.
        *   `"docker"`: kubelet runs inside a Docker container (older or specific setups).
    *   **Default**: `"host"`.
*   `$override_system_hostname` (Boolean)
    *   **Purpose**: If `true`, Ansible will override the VM's system hostname to match the Vagrant-generated instance name (`$instance_name_prefix-N`). If `false`, the original hostname from the VM image is preserved.
    *   **Value**: `true` or `false`.
    *   **Default**: `true`.
*   `$enable_host_inventory_check` (Boolean)
    *   **Purpose**: If `true`, Ansible will check the validity of the host inventory before starting the deployment.
    *   **Value**: `true` or `false`.
    *   **Default**: `true`.

### 9. Download/Cache Configuration

Settings related to downloading Kubernetes components, container images, and other dependencies.

*   `$download_run_once` (Boolean)
    *   **Purpose**: If `true`, download tasks will only run on the first `vagrant up` or `vagrant provision`. Subsequent `provision` commands will skip download steps unless the `download` tag is explicitly used.
    *   **Value**: `true` or `false`.
    *   **Default**: `false`.
*   `$download_localhost` (Boolean)
    *   **Purpose**: If `true`, files are downloaded to the local machine running Vagrant (Ansible controller) first, then copied to the VMs. This is useful if VMs don't have direct internet access but the host does.
    *   **Value**: `true` or `false`.
    *   **Default**: `true`.
*   `$vagrant_box_version` (String)
    *   **Purpose**: Specifies the version of the Vagrant box to use. If not set, Vagrant will use the latest available version.
    *   **Value**: A valid box version string, e.g., `">= 0"` (any version) or a specific version like `"4.2.16"`.
    *   **Default**: `ENV['VAGRANT_BOX_VERSION'] || ">= 0"`.
*   `$ignore_box_version_mismatch` (Boolean)
    *   **Purpose**: If `true`, Vagrant will not attempt to update the box even if the version specified in the `Vagrantfile` doesn't match the locally cached box version.
    *   **Value**: `true` or `false`.
    *   **Default**: `false`.

### 10. Directory/Port Configuration

Settings related to directory sharing and port forwarding.

*   `$vagrant_dir_path` (String)
    *   **Purpose**: Specifies the path where the Vagrant project is mounted inside the guest VM.
    *   **Value**: A valid Unix path string.
    *   **Default**: `"/vagrant"`.
*   `$local_path` (String)
    *   **Purpose**: Path on the host machine to the directory that will be shared with the guest VMs.
    *   **Value**: A valid path on the host.
    *   **Default**: `.` (the current directory, i.e., the Kubespray root).
*   `$k8s_secure_api_port` (Integer)
    *   **Purpose**: The secure port (HTTPS) for the Kubernetes API server.
    *   **Value**: A port number.
    *   **Default**: `6443`.
*   `$k8s_dashboard_port` (Integer)
    *   **Purpose**: Port for the Kubernetes Dashboard service (if deployed).
    *   **Value**: A port number.
    *   **Default**: `8001` (often the port used by `kubectl proxy`).
*   `$forwarded_ports` (Hash)
    *   **Purpose**: Defines port forwarding rules from the host to the guest VMs. This allows you to access services running on the VMs from your host machine.
    *   **Value**: A Ruby hash where keys are descriptions and values are hashes containing `:host` (host port) and `:guest` (guest port). Example:
        ```ruby
        $forwarded_ports = {
          'k8s_api' => { host: 8080, guest: $k8s_secure_api_port }, # Forwards host 8080 to first master's 6443
          'dashboard' => { host: 8001, guest: $k8s_dashboard_port } # Forwards host 8001 to first master's 8001
        }
        ```
        Note: These ports are typically forwarded to the first master node (`k8s-1`).
    *   **Default**: `{}` (Empty hash, no ports forwarded by default). Examples are provided in `vagrant-config-sample.rb`.

## Advanced Usage

### Using Different Operating Systems

You can change the OS for your VMs by setting the `$os` variable in `vagrant/config.rb`. The `Vagrantfile` contains a `SUPPORTED_OS` hash listing available options and their corresponding Vagrant box names. Ensure the box you choose is available on Vagrant Cloud or you have added it locally.

Example, to use Ubuntu 22.04:
```ruby
# In vagrant/config.rb
$os = "ubuntu2204"
```

### Running Specific Ansible Tasks (Tags)

You can run specific parts of the Ansible playbook using the `$ansible_tags` variable or the `VAGRANT_ANSIBLE_TAGS` environment variable. This is useful for debugging or applying only certain changes.

Example, to run only etcd-related tasks:
```bash
VAGRANT_ANSIBLE_TAGS=etcd vagrant provision
```
Or set in `vagrant/config.rb`:
```ruby
$ansible_tags = "etcd"
```

### Custom Ansible Variables

The `$extra_vars` hash allows you to pass any custom variables to Ansible. This enables fine-tuning Kubespray's behavior without modifying its core roles or playbooks.

Example, to change the Kubernetes version and enable the netchecker:
```ruby
# In vagrant/config.rb
$extra_vars = {
  'kube_version' => 'v1.27.8',
  'deploy_netchecker' => true,
  'dns_min_replicas' => 1 # Adjust CoreDNS replicas for resource-constrained envs
}
```

### Managing Multiple Clusters or Configurations

If you need to manage multiple Vagrant environments with different configurations, you can use the `KUBESPRAY_VAGRANT_CONFIG` environment variable to point to different `config.rb` files.

```bash
export KUBESPRAY_VAGRANT_CONFIG=/path/to/my_cluster_config.rb
vagrant up

export KUBESPRAY_VAGRANT_CONFIG=/path/to/another_cluster_config.rb
vagrant up
```

## Troubleshooting

*   **Insufficient Resources (Memory/CPU)**:
    *   **Symptoms**: VMs run slowly, Ansible tasks time out, services fail to start.
    *   **Solution**: Increase `$vm_memory`, `$vm_cpus`, `$kube_master_vm_memory`, and `$kube_master_vm_cpus` in `vagrant/config.rb`. Ensure your host machine has enough free resources.
*   **Network Issues**:
    *   **Symptoms**: VMs cannot communicate with each other, cannot access the internet, DNS resolution fails.
    *   **Solution**:
        *   Check settings for `$vm_network`, `$subnet`, `$gateway`, `$dns_server`.
        *   If using `public_network`, ensure `$bridge_nic` is set correctly and your physical network allows bridging and additional IP addresses.
        *   Check firewall rules on both host and guest.
        *   If using a proxy, ensure `$http_proxy`, `$https_proxy`, and `$no_proxy` are correctly configured.
*   **Ansible Errors**:
    *   **Symptoms**: Ansible playbook fails during `vagrant up` or `vagrant provision`.
    *   **Solution**:
        *   Read the Ansible error output carefully. It usually points to the failing task and reason.
        *   Increase Ansible verbosity by setting `$ansible_verbosity = true` (or higher, like `"vvv"`) for more information.
        *   Check `$extra_vars` in `vagrant/config.rb` for typos or invalid values.
        *   Ensure your Ansible environment is set up correctly (Python version, Ansible version, dependencies).
*   **SSH Timeouts**:
    *   **Symptoms**: Vagrant cannot SSH into the VMs.
    *   **Solution**:
        *   Ensure the VMs have booted successfully. You can check this using the VirtualBox GUI (if `$vm_gui = true`) or your hypervisor's command-line tools.
        *   Check network configuration to ensure Vagrant can reach the VM's SSH port.
        *   Sometimes, on resource-constrained hosts, VMs may take longer to boot. You might try increasing Vagrant's SSH connection timeout (this is usually configured in the `Vagrantfile`, but for Kubespray's setup, ensuring adequate VM resources is the first step).
*   **Vagrant Box Download Failures**:
    *   **Symptoms**: `vagrant up` fails because it cannot download the box.
    *   **Solution**:
        *   Check your internet connection.
        *   Ensure the `$os` variable is set to a valid key defined in the `SUPPORTED_OS` hash.
        *   Try downloading the box manually: `vagrant box add generic/ubuntu2204` (replacing with your chosen box).

By following this guide and adjusting the configuration parameters to your specific needs, you should be able to successfully deploy and manage Kubernetes clusters using Vagrant and Kubespray.