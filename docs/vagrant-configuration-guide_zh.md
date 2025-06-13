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

# Kubespray Vagrant 配置指南

[//]: # (Language Selector)
[English](./vagrant-configuration-guide.md) | [中文](./vagrant-configuration-guide_zh.md)
</p>

# Kubespray Vagrant 配置指南

本指南详细介绍了如何配置和使用 Vagrant 配合 Kubespray 来搭建 Kubernetes 集群。Vagrant 允许您创建和管理轻量级、可复现且可移植的开发环境。

## 概述

Kubespray 在仓库的根目录使用一个 `Vagrantfile` 文件来定义虚拟机 (VM) 的设置。您可以通过在 `vagrant/config.rb` 创建一个配置文件来自定义 Vagrant 环境。如果此文件存在，`Vagrantfile` 将加载它，允许您覆盖默认设置。

或者，您可以使用 `KUBESPRAY_VAGRANT_CONFIG` 环境变量指定自定义配置文件的路径。

## 开始使用

1. **安装先决条件**：

    * **Vagrant**: 从 [Vagrant 官方网站](https://www.vagrantup.com/downloads.html) 下载并安装。
        *   **验证**: 打开终端或命令提示符并运行 `vagrant --version`。您应该能看到已安装的 Vagrant 版本。
    *   **Vagrant Provider (Hypervisor)**: 这是底层的虚拟化软件。**VirtualBox** 是本指南的主要推荐 provider。
        *   **VirtualBox (推荐)**:
            *   **安装**: 从 [VirtualBox 官方网站](https://www.virtualbox.org/wiki/Downloads) 下载并安装。建议同时安装 VirtualBox Extension Pack 以获得完整功能。
            *   **验证**: 安装后，您应该可以在终端运行 `VBoxManage --version`，或者直接打开 VirtualBox 应用程序。
        *   **VMware Fusion** (macOS) / **VMware Workstation** (Windows/Linux) (高级): 商业产品，从 [VMware 官方网站](https://www.vmware.com/) 下载。
            *   **验证**: 确保应用程序可以启动，并且您可以通过其 UI 手动创建虚拟机。
    *   **Vagrant 插件 (可选但推荐)**:
        *   `vagrant-proxyconf`: 管理客户虚拟机内的代理设置。使用 `vagrant plugin install vagrant-proxyconf` 安装。
            *   **验证**: 运行 `vagrant plugin list` 查看 `vagrant-proxyconf` 是否已列出。

2.  **克隆 Kubespray 仓库**：
    ```bash
    git clone https://github.com/upmio/kubespray.git
    cd kubespray
    ```

3.  **准备 Ansible 环境**

    Vagrant 使用 Ansible 在创建的虚拟机上配置 Kubernetes 集群。因此，您需要在运行 `vagrant up` 的主机上设置 Ansible 环境。

    **a. 克隆 Kubespray 仓库 (如果尚未克隆):**

    如果您尚未克隆 Kubespray 仓库，请立即克隆。`Vagrantfile` 和 Ansible playbooks 是此仓库的一部分。

    ```bash
    # 如果您尚未在 kubespray 目录中
    # git clone https://github.com/upmio/kubespray.git
    # cd kubespray
    ```

    **b. 安装 Ansible 及依赖:**

    强烈建议使用 Python 虚拟环境来安装 Ansible 及其依赖，以避免与系统范围的软件包冲突。

    1.  **创建并激活 Python 虚拟环境:**

        ```bash
        # 导航到您的 Kubespray 目录 (例如 Vagrantfile 所在的目录)
        # cd /path/to/kubespray
        python3 -m venv venv
        source venv/bin/activate
        ```
        激活后，您的 shell 提示符通常会更改以指示您处于虚拟环境中 (例如 `(venv) your-prompt$`)。

    2.  **安装 Ansible 和所需的 Python 包:**

        Kubespray 提供了一个 `requirements.txt` 文件，其中列出了兼容的 Ansible 版本和其他必需的 Python 库。

        ```bash
        # 确保您在 Kubespray 根目录中
        pip install -U -r requirements.txt
        ```

        此命令将安装 Kubespray 测试过的特定 Ansible 版本以及其他依赖项，如 `jinja2`、`netaddr` 等。

        *   **Python 版本兼容性**: Kubespray 和 Ansible 有特定的 Python 版本要求。如果在安装过程中遇到错误，请参阅 [Kubespray 官方 Ansible 文档](../ansible/ansible.md#installing-ansible) 以获取有关兼容的 Python 和 Ansible 版本的详细信息。

    完成这些步骤后，您的 Ansible 环境就准备好了，Vagrant 将能够使用它来执行 Kubespray playbooks。

4.  **自定义 Vagrant 配置 (config.rb)**
    *   复制示例配置文件：
        ```bash
        cp vagrant-config-sample.rb vagrant/config.rb
        ```
    *   编辑 `vagrant/config.rb` 以根据您的需求调整参数。详情请参阅下面的 [配置参数](#配置参数) 部分。

5.  **启动集群**:
    ```bash
    vagrant up
    ```
    此命令将下载指定的虚拟机镜像 (如果尚未缓存)，创建虚拟机，然后运行 Ansible playbooks 以在其上部署 Kubernetes。此过程可能需要相当长的时间，尤其是在首次运行时。

6.  **访问虚拟机**:
    您可以使用以下命令通过 SSH 连接到任何创建的虚拟机：
    ```bash
    vagrant ssh <vm_name>
    ```
    虚拟机名称通常以 `$instance_name_prefix` (默认为 `k8s`) 为前缀，因此是 `k8s-1`、`k8s-2` 等。
    例如，要 SSH 连接到第一个节点：
    ```bash
    vagrant ssh k8s-1
    ```

7.  **销毁集群**:
    要移除 Vagrant 创建的所有虚拟机和相关资源：
    ```bash
    vagrant destroy -f
    ```
    `-f` 标志强制销毁而不提示确认。

## 配置文件 (`vagrant/config.rb`)

自定义 Kubespray Vagrant 设置的主要方法是创建和修改 `vagrant/config.rb`。此文件是一个 Ruby 脚本，您可以在其中设置 `Vagrantfile` 使用的各种全局变量。

`Vagrantfile` 首先为这些参数定义默认值。如果 `vagrant/config.rb` 存在，它将被加载，并且其中定义的任何变量都将覆盖默认值。

**`vagrant/config.rb` 条目示例**：

```ruby
# 在 vagrant/config.rb 中
$num_instances = 5  # 覆盖默认的虚拟机数量
$os = "ubuntu2204"  # 更改虚拟机的默认操作系统
```

Kubespray 的 Vagrant 配置主要通过 `vagrant/config.rb` 文件进行管理。此文件包含各种参数，允许您自定义虚拟机的规格、网络设置、集群拓扑等。

## 配置参数

以下是可配置参数的详细列表。您可以在 `vagrant/config.rb` 文件中设置这些参数。每个参数的描述包括其用途、典型值和默认值 (如果适用)。

### 1. 代理配置

如果您的开发环境位于企业防火墙之后，您可能需要为 Vagrant 和客户虚拟机配置代理设置。

* `$http_proxy` (字符串)
  * **用途**：指定 HTTP 代理服务器的 URL。
  * **值**：有效的 URL 字符串，例如 `"http://proxy.example.com:8080"`。
  * **默认值**：`""` (空字符串，表示无 HTTP 代理)。
* `$https_proxy` (字符串)
  * **用途**：指定 HTTPS 代理服务器的 URL。
  * **值**：有效的 URL 字符串，例如 `"https://proxy.example.com:8080"`。
  * **默认值**：`""` (空字符串，表示无 HTTPS 代理)。
* `$no_proxy` (字符串)
* **用途**：一个逗号分隔的主机名、IP 地址或域列表，这些地址应绕过代理。

  * **值**：类似 `"localhost,127.0.0.1,.internal.domain.com,192.168.0.0/16"` 的字符串。
  * **默认值**：`ENV['NO_PROXY'] || ENV['no_proxy'] || "localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,::1"`。如果 `vagrant-proxyconf` 插件处于活动状态，`Vagrantfile` 还会自动添加虚拟机 IP 和常见的私有网络范围。
* `$additional_no_proxy` (字符串)
  * **用途**：允许您向 `$no_proxy` 列表追加额外的条目，而无需完全覆盖默认值。
  * **值**：逗号分隔的字符串，例如 `".mycorp,.k8s.local"`。
  * **默认值**：在 `Vagrantfile` 中未明确设置，但可以在 `vagrant-config-sample.rb` 中定义。用于添加特定的内部域。

### 2. Ansible 配置

这些设置控制 Vagrant 如何执行 Ansible 来部署集群。

* `$ansible_verbosity` (布尔值或字符串)
  * **用途**：控制部署期间 Ansible 输出的详细程度。
  * **值**：
    * `false`：标准输出。
    * `true`：基本详细输出 (相当于 `-v`)。
    * `"v"`, `"vv"`, `"vvv"` (调试), `"vvvv"` (连接调试)：逐渐增加的详细输出级别。
  * **默认值**：`false`。
* `$ansible_tags` (字符串)
  * **用途**：指定一个逗号分隔的 Ansible 标签列表。只有带有这些标签 (或 `always`) 的任务才会被运行。
  * **值**：类似 `"etcd,network"` 的字符串，用于仅运行 etcd 和网络相关的任务，或 `"download"` 用于仅运行下载任务。
  * **默认值**：`ENV['VAGRANT_ANSIBLE_TAGS'] || ""` (如果未设置环境变量，则运行所有任务)。
* `$playbook` (字符串)
  * **用途**：定义用于集群设置的主要 Ansible playbook 文件。
  * **值**：playbook 文件的路径，相对于 Kubespray 根目录。例如，`"cluster.yml"` 用于完整集群，或 `"remove-node.yml"` 用于节点移除任务。
  * **默认值**：`"cluster.yml"`。
* `$extra_vars` (哈希)
  * **用途**：一个包含要传递给 Ansible 的附加变量的 Ruby 哈希。这些变量可以覆盖 Kubespray 中的默认值或提供自定义配置。
  * **值**：一个 Ruby 哈希，例如 `$extra_vars = {'kube_version' => 'v1.28.5', 'deploy_netchecker' => true}`。
  * **默认值**：`{}` (空哈希)。

### 3. 虚拟机 (VM) 配置

构成 Kubernetes 集群的虚拟机的一般设置。

* `$instance_name_prefix` (字符串)
  * **用途**：Vagrant 创建的虚拟机主机名的前缀。
  * **值**：任何字符串，例如 `"k8s"` 会导致虚拟机命名为 `k8s-1`、`k8s-2` 等。
  * **默认值**：`"k8s"`。
* `$vm_memory` (整数)
  * **用途**：Kubernetes 工作节点的默认内存分配 (MB)。
  * **值**：表示 MB 的整数。推荐的最小值取决于工作负载，但通常为 `2048` (2GB) 或更高。
  * **默认值**：`16384` (16GB)。这是一个慷慨的默认值；请根据您的主机容量和集群需求进行调整。
* `$vm_cpus` (整数)
  * **用途**：分配给 Kubernetes 工作节点的默认 CPU核心数。
  * **值**：一个整数。推荐最小值为 `2`。
  * **默认值**：`8`。请根据主机容量进行调整。
* `$kube_master_vm_memory` (整数)
  * **用途**：Kubernetes 主节点/控制平面节点的内存分配 (MB)。
  * **值**：一个整数。单主节点推荐最小 `2048` (2GB)，HA 设置则需要更多。
  * **默认值**：`4096` (4GB)。
* `$kube_master_vm_cpus` (整数)
  * **用途**：Kubernetes 主节点/控制平面节点的 CPU 核心数。
  * **值**：一个整数。推荐最小值为 `2`。
  * **默认值**：`4`。
* `$upm_control_plane_vm_memory` (整数)
  * **用途**：UPM (User Provided Machine) 控制平面节点的内存 (MB)，如果您使用此特定的 UPM 功能 (对于典型的 Vagrant 设置不太常见)。
  * **值**：一个整数。
  * **默认值**：`Vagrantfile` 中为 `32768` (32GB)，`vagrant-config-sample.rb` 中为 `8192` (8GB)。此参数通常与更高级或特定的 UPM 场景相关。
* `$upm_control_plane_vm_cpus` (整数)
  * **用途**：UPM 控制平面节点的 CPU 核心数。
  * **值**：一个整数。
  * **默认值**：`8`。
* `$vm_gui` (布尔值)
  * **用途**：启用或禁用虚拟机的图形用户界面 (GUI)。这主要适用于 VirtualBox provider。
  * **值**：`true` (启用 GUI) 或 `false` (无头模式)。
  * **默认值**：`false`。
* `$provider` (字符串)
  * **用途**：指定首选的 Vagrant provider（如果安装了多个，例如 VirtualBox, VMware）。
  * **值**：字符串，例如 `"virtualbox"`, `"vmware_fusion"`, `"vmware_workstation"`, `"parallels"`。
  * **默认值**：`ENV['VAGRANT_DEFAULT_PROVIDER'] || ""` (如果为空或未设置环境变量，Vagrant 会尝试自动选择，通常在可用时默认为 VirtualBox)。

### 4. 存储配置

为工作节点配置额外的虚拟磁盘。这对于测试分布式存储解决方案或需要持久本地存储的应用程序非常有用。

* `$kube_node_instances_with_disks` (布尔值)
  * **用途**：如果为 `true`，将为工作节点创建并附加额外的虚拟磁盘。
  * **值**：`true` 或 `false`。
  * **默认值**：在 `Vagrantfile` 中为 `false`，但在 `vagrant-config-sample.rb` 中为 `true` 以突出显示该功能。
* `$kube_node_instances_with_disks_size` (字符串或整数)
  * **用途**：指定每个额外磁盘的大小。
  * **值**：带单位的字符串 (例如 `"20G"` 表示 20GB, `"500M"` 表示 500MB) 或表示 MB 大小的整数 (例如 `20480` 表示 20GB)。
  * **默认值**：在 `Vagrantfile` 中为 `"20G"`，在 `vagrant-config-sample.rb` 中为 `204800` (200GB)。示例文件显示了更大的尺寸，可能用于特定的测试场景。
* `$kube_node_instances_with_disks_number` (整数)
  * **用途**：要附加到每个符合条件的工作节点的额外磁盘数量。
  * **值**：整数，例如 `1`, `2`, `3`。
  * **默认值**：在 `Vagrantfile` 中为 `2`，在 `vagrant-config-sample.rb` 中为 `1`。
* `$kube_node_instances_with_disk_dir` (字符串)
  * **用途**：主机上存储虚拟磁盘镜像文件的目录。
  * **值**：有效的路径字符串，例如 `ENV['HOME'] + "/.vagrant.d/my_disks"`。
  * **默认值**：`Vagrantfile` 中为 `ENV['HOME']`，`vagrant-config-sample.rb` 中为 `ENV['HOME'] + "/.vagrant.d/upm_disks"`。确保此目录存在且有足够空间。
* `$kube_node_instances_with_disk_suffix` (字符串)
  * **用途**：磁盘镜像文件名的后缀，有助于识别它们。
  * **值**：一个字符串，例如 `"disk"`、`"data"`。
  * **默认值**：`Vagrantfile` 中为 `'xxxxxxxx'` (占位符，表示可能动态生成或需要用户输入)，`vagrant-config-sample.rb` 中为 `"upm"`。

### 5. 集群拓扑

定义 Kubernetes 集群中虚拟机的数量及其角色 (etcd、master、worker)。

* `$num_instances` (整数)
  * **用途**：为集群创建的虚拟机实例总数。
  * **值**：一个整数。对于最小的 HA 设置，通常至少为 `3` (例如，3 个 etcd，2 个 master，3 个 worker，某些节点可以共享角色)。
  * **默认值**：`3`。
* `$etcd_instances` (整数)
  * **用途**：指定为 etcd 节点的虚拟机数量。为了实现高可用性 (HA)，这应该是一个奇数 (例如 1、3、5)。
  * **值**：一个整数。`Vagrantfile` 逻辑默认将其限制为 `min($num_instances, 3)`。
  * **默认值**：`[$num_instances, 3].min`。对于 `$num_instances = 1`，它是 1。对于 `$num_instances = 2`，它是 2 (不适用于 HA etcd)。对于 `$num_instances >= 3`，它是 3。
* `$kube_master_instances` (整数)
  * **用途**：指定为 Kubernetes 主节点/控制平面节点的虚拟机数量。
  * **值**：一个整数。`1` 表示单主节点，`2` 或更多表示 HA (Vagrant 设置中通常为 `2` 或 `3`)。`Vagrantfile` 逻辑默认将其限制为 `min($num_instances, 2)`。
  * **默认值**：`[$num_instances, 2].min`。对于 `$num_instances = 1`，它是 1。对于 `$num_instances >= 2`，它是 2。
* `$kube_node_instances` (整数)
  * **用途**：将充当 Kubernetes 工作节点的虚拟机数量。这些是运行应用程序 Pod 的节点。
  * **值**：一个整数，最多为 `$num_instances`。节点可以承担多种角色 (例如，如果没有污点，主节点也可以是工作节点)。
  * **默认值**：`$num_instances` (表示所有创建的虚拟机最初都被视为清单中潜在的工作节点)。
* `$upm_ctl_instances` (整数)
  * **用途**：UPM (User Provided Machine) 控制器节点的数量。这特定于 UPM 功能。
  * **值**：一个整数，如果使用 UPM，通常为 `1`。
    * **默认值**：`1`。

### 6. 系统配置

客户虚拟机的一般系统级设置。

* `$time_zone` (字符串)
  * **用途**：设置所有虚拟机的系统时区。
  * **值**：有效的 Olson 时区字符串，例如 `"Asia/Shanghai"`、`"UTC"`、`"America/New_York"`。
  * **默认值**：`"Asia/Shanghai"`。
* `$os` (字符串)
  * **用途**：指定用于虚拟机的操作系统和 Vagrant box。
  * **值**：必须是 `Vagrantfile` 中 `SUPPORTED_OS` 哈希中定义的键之一。示例：
    * `"ubuntu2204"` (映射到 `generic/ubuntu2204` box)
    * `"ubuntu2404"` (映射到 `bento/ubuntu-24.04` box)
    * `"rockylinux8"` (映射到 `bento/rockylinux-8` box)
    * `"rockylinux9"` (映射到 `bento/rockylinux-9` box)
        *   `"opensuse"` (映射到 `opensuse/Leap-15.4.x86_64` box)
        *   `"oraclelinux8"` (映射到 `generic/oracle8` box)
        *   查看 `Vagrantfile` 以获取完整、最新的列表和相应的 box 名称。
    *   **默认值**：`"rockylinux9"`。
*   `$vagrant_pwd` (字符串)
    *   **用途**：设置虚拟机内默认 `vagrant` 用户的密码。
    *   **值**：密码字符串。如果未设置，则生成一个随机密码。
    *   **默认值**：`ENV['VAGRANT_PASSWORD'] || SecureRandom.hex(8)` (如果设置了环境变量则使用它，否则使用一个随机的 16 位十六进制字符串)。

### 7. 网络配置

定义虚拟机的网络设置，包括 IP 地址和连接性。

*   `$vm_network` (字符串)
    *   **用途**：确定 Vagrant 将为虚拟机配置的网络类型。
    *   **值**：
        *   `"private_network"`：创建一个仅主机的网络。虚拟机可以相互通信并与主机通信，但不能从外部网络直接访问。
        *   `"public_network"`：将虚拟机的网络接口桥接到主机的物理接口之一，使虚拟机在主机网络上显示为独立的设备。
    *   **默认值**：`"private_network"`。
*   `$subnet` (字符串)
    *   **用途**：使用 `private_network` 时虚拟机 IP 地址范围的前三个八位字节。
    *   **值**：类似 `"172.18.8"` 或 `"192.168.56"` 的字符串。
    *   **默认值**：`"172.18.8"`。
*   `$subnet_split4` (整数)
    *   **用途**：虚拟机 IP 地址第四个八位字节的起始值。IP 将从 `$subnet.$subnet_split4 + 1` 开始顺序分配。
    *   **值**：一个整数，通常在 `1` 到 `254` 之间。如果使用 `public_network` 或现有的仅主机网络，请确保它不与其它设备冲突。
    *   **默认值**：`100` (因此 IP 从 `172.18.8.101`、`172.18.8.102` 等开始)。
*   `$subnet_ipv6` (字符串)
    *   **目的**: 虚拟机的 IPv6 子网前缀。除非特别配置，否则这对于基于 VirtualBox 的私有网络通常不那么重要。
    *   **值**: 有效的 IPv6 前缀，例如 `"fd3c:b398:0698:0756"`。
    *   **默认值**: `"fd3c:b398:0698:0756"`。
*   `$netmask` (字符串)
    *   **用途**：私有网络的网络掩码。
    *   **值**：类似 `"255.255.255.0"` (对于 /24 网络) 的字符串。
    *   **默认值**：`"255.255.255.0"`。
*   `$gateway` (字符串)
    *   **用途**：私有网络上虚拟机的默认网关 IP 地址。这通常是所选子网的 `.1` 地址。
    *   **值**：IP 地址字符串，例如 `"172.18.8.1"`。
    *   **默认值**：`"172.18.8.1"`。
*   `$dns_server` (字符串)
    *   **用途**：要在虚拟机中配置的 DNS 服务器 IP 地址。
    *   **值**：IP 地址字符串，例如 `"8.8.8.8"` (Google 公共 DNS) 或您的内部 DNS 服务器。
    *   **默认值**：`"8.8.8.8"`。
*   `$bridge_nic` (字符串)
    *   **用途**：当 `$vm_network` 设置为 `"public_network"` 时，此参数指定主机上要桥接到的网络接口。
    *   **值**：主机网络接口的名称，例如 `"en0"` (macOS 上常见的 Wi-Fi/以太网)、`"eth0"` (Linux 上常见的以太网)。
    *   **默认值**：`""` (空字符串，Vagrant 通常会提示选择)。您可能需要根据您的主机操作系统和网络配置更改此值。
*   `$forward_ports` (数组)
    *   **用途**：定义从主机到客户虚拟机的端口转发规则的哈希数组。
    *   **值**：例如，`[{ guest: 80, host: 8080 }, { guest: 443, host: 8443, protocol: "tcp", auto_correct: true }]`。
    *   **默认值**：`[]` (空数组)。

### 8. Kubernetes 配置

直接影响 Kubespray 部署的 Kubernetes 集群的参数。

*   `$network_plugin` (字符串)
    *   **用途**：选择用于 Kubernetes 中 Pod 网络的 CNI (容器网络接口) 插件。
    *   **值**：标识受支持的 CNI 插件的字符串。常见选项：
        *   `"calico"` (默认，功能丰富，支持网络策略)
        *   `"flannel"` (更简单，基于 VXLAN 的覆盖网络)
        *   `"cilium"` (基于 eBPF，高级网络和安全)
        *   `"kube-ovn"` (基于 OVN，提供高级 SDN 功能)
        *   `"weave"` (另一种选择，提供加密功能)
    *   **默认值**：`"calico"`。
*   `$multi_networking` (字符串)
    *   **用途**：通过 Multus CNI 启用对多个 CNI 插件的支持，允许 Pod 连接到多个网络。
    *   **值**：`"True"` 或 `"true"` 表示启用，`"False"` 或 `"false"` 表示禁用。
    *   **默认值**：`"False"`。
*   `$kube_version` (字符串)
    *   **用途**：指定要部署的 Kubernetes 版本。
    *   **值**：有效的 Kubernetes 版本号，例如 `"v1.28.5"`。请查阅 Kubespray 文档以获取支持的版本列表。
    *   **默认值**：`"latest"` (通常会解析为 Kubespray 支持的最新稳定版，具体取决于 Kubespray 的版本)。
*   `$container_manager` (字符串)
    *   **用途**：选择 Kubernetes 节点上使用的容器运行时。
    *   **值**：
        *   `"containerd"` (推荐，轻量级且高效)
        *   `"crio"` (CRI-O，另一个专注于 Kubernetes 的 CRI 实现)
        *   `"docker"` (传统选项，但 Kubernetes 已弃用 DockerShim，因此不推荐用于新集群)
    *   **默认值**：`"containerd"`。
*   `$etcd_deployment_type` (字符串)
    *   **用途**：定义 etcd 的部署方式。
    *   **值**：
        *   `"kubeadm"`：etcd 作为静态 Pod 由 kubelet 管理 (在控制平面节点上)。
        *   `"host"`：etcd 作为 systemd 服务直接在 etcd 节点上运行。
    *   **默认值**：`"kubeadm"`。
*   `$kubelet_deployment_type` (字符串)
    *   **用途**：指定 kubelet 的部署方式。
    *   **值**：
        *   `"host"`：kubelet 作为 systemd 服务运行。
        *   `"docker"`：kubelet 在 Docker 容器内运行 (较旧或特定的设置)。
    *   **默认值**：`"host"`。
*   `$override_system_hostname` (布尔值)
    *   **用途**：如果为 `true`，则 Ansible 将覆盖虚拟机的系统主机名，使其与 Vagrant 生成的实例名称 (`$instance_name_prefix-N`) 匹配。如果为 `false`，则保留虚拟机镜像的原始主机名。
    *   **值**：`true` 或 `false`。
    *   **默认值**：`true`。
*   `$enable_host_inventory_check` (布尔值)
    *   **用途**：如果为 `true`，Ansible 将在部署开始前检查主机清单的有效性。
    *   **值**：`true` 或 `false`。
    *   **默认值**：`true`。

### 9. 下载/缓存配置

与下载 Kubernetes 组件、容器镜像和其他依赖项相关的设置。

*   `$download_run_once` (布尔值)
    *   **用途**：如果为 `true`，下载任务将仅在第一次 `vagrant up` 或 `vagrant provision` 时运行。后续的 `provision` 命令将跳过下载步骤，除非显式使用 `download` 标签。
    *   **值**：`true` 或 `false`。
    *   **默认值**：`false`。
*   `$download_localhost` (布尔值)
    *   **用途**：如果为 `true`，文件将首先下载到运行 Vagrant 的本地计算机 (Ansible 控制器)，然后复制到虚拟机。这在虚拟机无法直接访问互联网但主机可以访问时很有用。
    *   **值**：`true` 或 `false`。
    *   **默认值**：`true`。
*   `$vagrant_box_version` (字符串)
    *   **用途**：指定要使用的 Vagrant box 的版本。如果未设置，Vagrant 将使用最新的可用版本。
    *   **值**：有效的 box 版本字符串，例如 `">= 0"` (任何版本) 或特定版本如 `"4.2.16"`。
    *   **默认值**：`ENV['VAGRANT_BOX_VERSION'] || ">= 0"`。
*   `$ignore_box_version_mismatch` (布尔值)
    *   **用途**：如果为 `true`，即使 `Vagrantfile` 中指定的 box 版本与本地缓存的 box 版本不匹配，Vagrant 也不会尝试更新 box。
    *   **值**：`true` 或 `false`。
    *   **默认值**：`false`。

### 10. 目录/端口配置

与目录共享和端口转发相关的设置。

*   `$vagrant_dir_path` (字符串)
    *   **用途**：指定 Vagrant 项目在客户虚拟机内的挂载点路径。
    *   **值**：有效的 Unix 路径字符串。
    *   **默认值**：`"/vagrant"`。
*   `$local_path` (字符串)
    *   **用途**：主机上要与客户虚拟机共享的目录的路径。
    *   **值**：主机上的有效路径。
    *   **默认值**：`.` (当前目录，即 Kubespray 根目录)。
*   `$k8s_secure_api_port` (整数)
    *   **用途**：Kubernetes API 服务器的安全端口 (HTTPS)。
    *   **值**：端口号。
    *   **默认值**：`6443`。
*   `$k8s_dashboard_port` (整数)
    *   **用途**：Kubernetes Dashboard 服务的端口 (如果已部署)。
    *   **值**：端口号。
    *   **默认值**：`8001` (通常是 `kubectl proxy` 使用的端口)。
*   `$forwarded_ports` (哈希)
    *   **用途**：定义从主机到客户虚拟机的端口转发规则。这允许您从主机访问虚拟机上运行的服务。
    *   **值**：一个 Ruby 哈希，其中键是描述，值是包含 `:host` (主机端口) 和 `:guest` (客户机端口) 的哈希。例如：
        ```ruby
        $forwarded_ports = {
          'k8s_api' => { host: 8080, guest: $k8s_secure_api_port }, # 将主机的 8080 转发到第一个主节点的 6443
          'dashboard' => { host: 8001, guest: $k8s_dashboard_port } # 将主机的 8001 转发到第一个主节点的 8001
        }
        ```
        注意：这些端口通常转发到第一个主节点 (`k8s-1`)。
    *   **默认值**：`{}` (空哈希，不转发任何端口)。`vagrant-config-sample.rb` 中提供了示例。

## 高级用法

### 使用不同的操作系统

您可以通过在 `vagrant/config.rb` 中设置 `$os` 变量来更改虚拟机的操作系统。`Vagrantfile` 包含一个 `SUPPORTED_OS` 哈希，列出了可用的选项及其对应的 Vagrant box 名称。确保您选择的 box 在 Vagrant Cloud 上可用，或者您已在本地添加它。

例如，要使用 Ubuntu 22.04：
```ruby
# In vagrant/config.rb
$os = "ubuntu2204"
```

### 运行特定的 Ansible 任务 (标签)

您可以使用 `$ansible_tags` 变量或 `VAGRANT_ANSIBLE_TAGS` 环境变量来运行 Ansible playbook 的特定部分。这对于调试或仅应用某些更改非常有用。

例如，仅运行与 etcd 相关的任务：
```bash
VAGRANT_ANSIBLE_TAGS=etcd vagrant provision
```
或者在 `vagrant/config.rb` 中设置：
```ruby
$ansible_tags = "etcd"
```

### 自定义 Ansible 变量

通过 `$extra_vars` 哈希，您可以将任何自定义变量传递给 Ansible。这允许您微调 Kubespray 的行为，而无需修改其核心角色或 playbook。

例如，更改 Kubernetes 版本并启用网络检查器：
```ruby
# In vagrant/config.rb
$extra_vars = {
  'kube_version' => 'v1.27.8',
  'deploy_netchecker' => true,
  'dns_min_replicas' => 1 # 针对资源有限的环境调整 CoreDNS 副本数
}
```

### 管理多个集群或配置

如果您需要管理多个具有不同配置的 Vagrant 环境，可以使用 `KUBESPRAY_VAGRANT_CONFIG` 环境变量指向不同的 `config.rb` 文件。

```bash
export KUBESPRAY_VAGRANT_CONFIG=/path/to/my_cluster_config.rb
vagrant up

export KUBESPRAY_VAGRANT_CONFIG=/path/to/another_cluster_config.rb
vagrant up
```

## 故障排除

*   **资源不足 (内存/CPU)**：
    *   **症状**：虚拟机运行缓慢，Ansible 任务超时，服务无法启动。
    *   **解决方案**：增加 `vagrant/config.rb` 中的 `$vm_memory`、`$vm_cpus`、`$kube_master_vm_memory` 和 `$kube_master_vm_cpus`。确保您的主机有足够的可用资源。
*   **网络问题**：
    *   **症状**：虚拟机无法相互通信，无法访问互联网，DNS 解析失败。
    *   **解决方案**：
        *   检查 `$vm_network`、`$subnet`、`$gateway`、`$dns_server` 的设置。
        *   如果使用 `public_network`，请确保 `$bridge_nic` 设置正确，并且您的物理网络允许桥接和额外的 IP 地址。
        *   检查主机和客户机上的防火墙规则。
        *   如果使用代理，请确保 `$http_proxy`、`$https_proxy` 和 `$no_proxy` 配置正确。
*   **Ansible 错误**：
    *   **症状**：`vagrant up` 或 `vagrant provision` 期间 Ansible playbook 失败。
    *   **解决方案**：
        *   仔细阅读 Ansible 的错误输出。它通常会指出失败的任务和原因。
        *   通过设置 `$ansible_verbosity = true` (或更高，如 `"vvv"`) 来增加 Ansible 的详细程度，以获取更多信息。
        *   检查 `vagrant/config.rb` 中的 `$extra_vars` 是否有拼写错误或无效值。
        *   确保您的 Ansible 环境已正确设置 (Python 版本、Ansible 版本、依赖项)。
*   **SSH 超时**：
    *   **症状**：Vagrant 无法通过 SSH 连接到虚拟机。
    *   **解决方案**：
        *   确保虚拟机已成功启动。您可以使用 VirtualBox GUI (如果 `$vm_gui = true`) 或 hypervisor 的命令行工具进行检查。
        *   检查网络配置，确保 Vagrant 可以访问虚拟机的 SSH 端口。
        *   有时，在资源受限的主机上，虚拟机启动可能需要更长时间。您可以尝试增加 Vagrant SSH 连接的超时时间 (这通常在 `Vagrantfile` 中配置，但对于 Kubespray 的设置，首先应确保 VM 资源充足)。
*   **Vagrant Box 下载失败**：
    *   **症状**：`vagrant up` 因无法下载 box 而失败。
    *   **解决方案**：
        *   检查您的互联网连接。
        *   确保 `$os` 变量设置为 `SUPPORTED_OS` 哈希中定义的有效键。
        *   尝试手动下载 box：`vagrant box add generic/ubuntu2204` (替换为您选择的 box)。

## 高级配置

### 自定义 Ansible 变量

通过 `$extra_vars` 哈希，您可以将任何自定义变量传递给 Ansible。这允许您微调 Kubespray 的行为，而无需修改其核心角色或 playbook。

例如，更改 Kubernetes 版本并启用网络检查器：
```ruby
# In vagrant/config.rb
$extra_vars = {
  'kube_version' => 'v1.27.8',
  'deploy_netchecker' => true,
  'dns_min_replicas' => 1 # 针对资源有限的环境调整 CoreDNS 副本数
}
```

### 网络插件选择

支持多种网络插件：

```ruby
$network_plugin = "calico"  # 默认
# $network_plugin = "flannel"
# $network_plugin = "weave"
# $network_plugin = "cilium"
```

### 多节点集群配置

配置一个 3 节点集群的示例：

```ruby
$num_instances = 3
$kube_master_instances = 1
$etcd_instances = 3
$vm_memory = 2048
$vm_cpus = 2
```

## 最佳实践

1.  **资源规划**: 根据您的硬件资源合理配置虚拟机数量和规格。

2.  **网络隔离**: 使用不同的子网来避免与现有网络冲突。

3.  **备份配置**: 保存您的 `vagrant/config.rb` 配置文件以便重复使用。

4.  **监控资源**: 在部署过程中监控主机的 CPU、内存和磁盘使用情况。

5.  **版本控制**: 使用特定的 box 版本以确保环境的一致性。

## 相关文档

-   [Kubespray 官方文档](../README.md)
-   [Ansible 配置指南](../ansible/ansible.md)
-   [网络插件配置](../network_plugins.md)
-   [故障排除指南](../troubleshooting.md)

通过遵循本指南并根据您的特定需求调整配置参数，您应该能够使用 Vagrant 和 Kubespray 成功部署和管理 Kubernetes 集群。
