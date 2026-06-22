<div align="center">

[🇨🇳 中文](#zh-version) | [🇺🇸 English](#en-version)

</div>


---

<a id="zh-version"></a>

# 🚀 Xray-Reality 一键脚本

**全自动、模块化的 Xray 部署脚本**

[![Powered by Xray](https://img.shields.io/badge/Powered%20by-Xray--core-blue.svg?style=flat-square)](https://github.com/XTLS/Xray-core) [![Internet Freedom](https://img.shields.io/badge/Internet-Freedom-0099ff.svg?style=flat-square)](https://github.com/carlleilzj/Xray-Auto) [![404 Not Found](https://img.shields.io/badge/Censorship-404%20Not%20Found-red.svg?style=flat-square)](https://github.com/carlleilzj/Xray-Auto)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ff69b4?style=flat-square)](https://github.com/carlleilzj/Xray-Auto#sponsor)

[![GitHub release](https://img.shields.io/github/v/release/carlleilzj/Xray-Auto?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/releases/latest) [![Downloads](https://img.shields.io/github/downloads/carlleilzj/Xray-Auto/total?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/releases) [![Last Commit](https://img.shields.io/github/last-commit/carlleilzj/Xray-Auto?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/commits/main) [![GitHub stars](https://img.shields.io/github/stars/carlleilzj/Xray-Auto?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/stargazers) 

[![OS](https://img.shields.io/badge/OS-Debian%20%7C%20Ubuntu-blue?style=flat-square&logo=linux&logoColor=white)](https://github.com/carlleilzj/Xray-Auto) [![Shell](https://img.shields.io/badge/Language-Shell-89E051?style=flat-square&logo=gnu-bash&logoColor=white)](https://github.com/carlleilzj/Xray-Auto/search?l=Shell) [![License](https://img.shields.io/github/license/carlleilzj/Xray-Auto?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/blob/main/LICENSE)



本项目是一个高度模块化的 Shell 脚本，用于在 Linux 服务器上快速部署基于 **Xray** 核心的代理服务。支持最新的 **Vision** 和 **XHTTP** 协议，并集成了由 Reality 驱动的 SNI 伪装技术。

---

## ✨ 功能特性 (Features)

* **📦 模块化设计**: 代码分为 Core、Lib、Tools 三大模块，逻辑清晰。
* **🔒 最新协议**: 支持 Vision 和 XHTTP 协议，集成 Reality 伪装。
* **🛡️ 安全加固**: 自动配置 Fail2ban 和防火墙。
* **🛠️ 丰富工具箱**: 内置 WARP、BBR、端口管理、SNI 优选等工具。


## 📋 环境要求 (Requirements)

* **操作系统**: Debian 10+, Ubuntu 20.04+ (推荐 Debian 11/12)
* **架构**: amd64, arm64
* **权限**: 需要 `root` 权限
* **端口**: 默认使用高位随机端口 (Vision) 和 (XHTTP)
* **客户端**: 请确保你的代理端支持该种协议（如 Shadowrocket, V2rayN...)


## 📥 快速安装 (Quick Start)

### 🚀 推荐：一键安装 (Bootstrap)

使用 `root` 用户运行以下命令即可。引导脚本会自动安装 Git、克隆仓库并启动安装程序。

```bash
bash <(curl -sL https://raw.githubusercontent.com/carlleilzj/Xray-Auto/main/bootstrap.sh)

```


### 🛠️ 备用：手动安装 (Manual)

如果你无法连接 GitHub Raw，可以尝试手动克隆：

```bash
# 1. 安装 Git
apt update && apt install -y git

# 2. 克隆仓库
git clone https://github.com/carlleilzj/Xray-Auto.git xray-install

# 3. 运行脚本
cd xray-install
chmod +x install.sh
./install.sh

```

## 🗑️ 卸载 (Uninstall)

如果你想彻底移除 Xray 及相关配置，请运行（或服务端输入`remove`）：

```bash
bash <(curl -sL https://raw.githubusercontent.com/carlleilzj/Xray-Auto/main/tools/remove.sh)

```


## 🎮 使用指南 (Usage)

安装完成后，脚本会将管理工具注册到系统路径。你可以直接在终端输入以下命令：

| 命令 | 功能 | 说明 |
| :--- | :--- | :--- |
| `info` | **主面板（Admin）** | 查看节点链接、二维码、服务状态及快捷菜单。 |
| `user` | **多用户管理（User）** | 查询、添加，删除用户。 |
| `ports` | **端口管理** | 修改 SSH、Vision、XHTTP 端口并自动放行防火墙。 |
| `net` | **网络策略** | 切换 IPv4/IPv6 优先策略，或强制单栈模式。 |
| `xw` | **WARP 管理** | 安装 Cloudflare WARP 用于 Netflix/ChatGPT 分流。 |
| `bbr` | **内核优化** | 开启/关闭 BBR 加速，调整队列算法 (FQ/FQ_CODEL)。 |
| `sni` | **伪装域管理** | 自动测速优选 SNI 域名，或手动指定。 |
| `bt` | **审计管理** | 一键开启/关闭 BT 下载拦截和私有 IP 拦截。 |
| `swap` | **内存管理** | 添加、删除 Swap 分区，调整 Swappiness 亲和度。 |
| `f2b` | **Fail2ban** | 查看封禁 IP、解封 IP、调整封禁策略。 |
| `backup` | **备份与恢复** | 查询、备份，恢复配置。 |
| `sniff` | **流量嗅探** | 开启/关闭 流量嗅探及其日志。 |
| `zone` | **时区管理** | 时区与时间设置。 |
| `update` | **更新** | 更新 Xray core 和 Geodata 数据库。 |
| `remove` | **一键卸载** | 移除Xray及全部安装。 |


### 📝 客户端配置参考
| 参数 | 值 (示例) | 说明 |
| :--- | :--- | :--- |
| **地址 (Address)** | `1.2.3.4` 或 `[2001::1]` | 服务器 IP |
| **端口 (Port)** | `443` | 安装时设置的端口 |
| **用户 ID (UUID)** | `de305d54-...` | 输入 `info` 获取 |
| **流控 (Flow)** | `xtls-rprx-vision` | **仅 Vision 节点填写** |
| **传输协议 (Network)**| `tcp` 或 `xhttp` | Vision 选 TCP，xhttp 选 xhttp |
| **伪装域名 (SNI)** | `www.microsoft.com` | 输入 `info` 获取 |
| **指纹 (Fingerprint)**| `chrome` | |
| **Public Key** | `B9s...` | 输入 `info` 获取 |
| **ShortId** | `a1b2...` | 输入 `info` 获取 |
| **路径 (Path)** | `/8d39f310` | **仅 xhttp 节点填写** |


## 📂 项目结构 (Structure)

本项目采用模块化架构，目录结构如下：

```text
.
├── bootstrap.sh       # 一键引导脚本 (下载、校验、启动)
├── install.sh         # 主安装入口 (流程编排、锁机制)
├── lib/
│   └── utils.sh       # 公共函数库 (UI、日志、颜色、Task执行器)
├── core/              # 核心安装流程
│   ├── 1_env.sh       # 环境检查与初始化
│   ├── 2_install.sh   # 依赖与 Xray 核心安装
│   ├── 3_system.sh    # 系统配置 (防火墙、内核)
│   └── 4_config.sh    # 生成配置与启动服务
└── tools/             # 独立管理工具 (安装后部署到 /usr/local/bin)
    ├── info.sh
    ├── ports.sh
    ├── net.sh
    ├── ...
```


## 🔄 如何保持 Fork 仓库更新

如果您 Fork 了本仓库，可以通过以下两种方式与上游原仓库保持同步：

### 方法一：手动同步（推荐，遇到冲突时可保留您的自定义修改）
1. 进入您在 GitHub 上的 Fork 仓库主页。
2. 找到并点击绿色的 "Code" 按钮下方的 **"Sync fork"**（同步分支）按钮。
3. 点击 **"Update branch"**（更新分支），即可拉取原仓库的最新更改。

### 方法二：自动同步（利用 GitHub Actions，注意：会强制覆盖您的本地修改）
本仓库已内置一个 GitHub Actions 工作流，可以每天自动帮您强制同步代码。**⚠️ 请注意：开启此功能后，上游的更新将直接覆盖您在默认分支上的所有独立修改。如果您需要进行自己的开发，请在新的分支上进行。**
1. 进入您 Fork 仓库的 **"Actions"** 标签页。
2. 点击 **"I understand my workflows, go ahead and enable them"**（我了解我的工作流，继续并启用它们）以激活 Actions 功能。
3. 激活后，`Auto Sync Upstream` 工作流将按计划自动运行（您也可以在左侧工作流列表中找到它并手动触发同步）。

<a id="sponsor"></a>
## 💖 赞助与支持 (Sponsor)

本项目完全免费开源。如果这个脚本为您节省了配置时间，并且您愿意支持后续的开发与测试服务器维护，欢迎使用我的aff购买链接！您的支持是我持续更新的最大动力。

### 🌐 服务器 (VPS) 选购建议

为了获得最佳的科学上网体验，建议您在选购 VPS 时注意以下几点：

* **线路质量 (Routing)**：
  * **电信用户**：优先选择 CN2 GIA 线路。
  * **联通用户**：优先选择 AS9929 或 AS4837 线路。
  * **移动用户**：优先选择 CMIN2 线路。
* **IP 纯净度**：尽量选择原生 IP (Native IP) 或未被滥用的机房。Reality 协议虽然能伪装流量，但如果目标 IP 已经被列入流媒体黑名单，您依然无法解锁 Netflix 或 Disney+。
* **虚拟化架构**：强烈建议选择 **KVM** 架构的服务器。OpenVZ (OVZ) 架构无法直接开启 BBR 加速，会严重影响晚高峰的吞吐速度。

## ⚖️ 免责声明 (Disclaimer)

**网络不是法外之地 (The internet is not a lawless place).**

1. **仅供科研与学习**: 本项目（Xray-Reality 脚本及相关配置）仅用于网络技术研究、学习交流及系统防御测试。请勿将本脚本用于任何违反国家法律法规的用途。
2. **法律合规**: 使用本脚本时，请务必严格遵守您所在国家/地区以及服务器运行所在地的法律法规。严禁将本项目用于涉及政治、宗教、色情、诈骗等非法内容的传播。一切因违规或滥用行为产生的法律后果及连带责任，均由使用者自行完全承担，本项目作者不承担任何连带责任。
3. **无担保条款**: 本软件按“原样” (AS IS) 提供，不提供任何形式的明示或暗示担保。作者不对因使用本脚本而导致的任何直接或间接损失（包括但不限于数据丢失、系统崩溃、IP 被封锁、服务器被服务商暂停或删除等）负责。
4. **第三方组件**: 本脚本集成了第三方开源程序（如 `Xray-core`），其版权和相关责任归原作者所有。本脚本作者不对第三方程序的安全性、合规性或稳定性做出任何保证。
5. **开源许可证**: 本项目遵循 GNU General Public License v3.0 (GPL-3.0) 开源协议，详细条款请参阅仓库内的 `LICENSE` 文件。一旦您下载、安装或使用本项目，即视为您已阅读并完全同意本免责声明及开源许可证的全部条款。

*版权所有 © ISFZY。本项目致力于提供最纯粹的网络路由体验。*

<br>

<div align="center">

[🇨🇳 中文](#zh-version) | [🇺🇸 English](#en-version)

</div>

---

<a id="en-version"></a>

# 🚀 Xray-Reality Installer

**Fully Automated, Modular Xray Deployment Script**

[![Powered by Xray](https://img.shields.io/badge/Powered%20by-Xray--core-blue.svg?style=flat-square)](https://github.com/XTLS/Xray-core) [![Internet Freedom](https://img.shields.io/badge/Internet-Freedom-0099ff.svg?style=flat-square)](https://github.com/carlleilzj/Xray-Auto) [![404 Not Found](https://img.shields.io/badge/Censorship-404%20Not%20Found-red.svg?style=flat-square)](https://github.com/carlleilzj/Xray-Auto)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ff69b4?style=flat-square)](https://github.com/carlleilzj/Xray-Auto#sponsor)

[![GitHub release](https://img.shields.io/github/v/release/carlleilzj/Xray-Auto?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/releases/latest) [![Downloads](https://img.shields.io/github/downloads/carlleilzj/Xray-Auto/total?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/releases) [![Last Commit](https://img.shields.io/github/last-commit/carlleilzj/Xray-Auto?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/commits/main) [![GitHub stars](https://img.shields.io/github/stars/carlleilzj/Xray-Auto?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/stargazers) 

[![OS](https://img.shields.io/badge/OS-Debian%20%7C%20Ubuntu-blue?style=flat-square&logo=linux&logoColor=white)](https://github.com/carlleilzj/Xray-Auto) [![Shell](https://img.shields.io/badge/Language-Shell-89E051?style=flat-square&logo=gnu-bash&logoColor=white)](https://github.com/carlleilzj/Xray-Auto/search?l=Shell) [![License](https://img.shields.io/github/license/carlleilzj/Xray-Auto?style=flat-square)](https://github.com/carlleilzj/Xray-Auto/blob/main/LICENSE)

This project is a highly modular Shell script designed for the rapid deployment of proxy services based on the **Xray** core on Linux servers. It supports the latest **Vision** and **XHTTP** protocols and integrates SNI masking technology powered by Reality.

---

## ✨ Features

* **📦 Modular Design**: The code is logically organized into three main modules: Core, Lib, and Tools.
* **🔒 Latest Protocols**: Supports Vision and XHTTP protocols with integrated Reality masking.
* **🛡️ Security Hardening**: Automatically configures Fail2ban and the Firewall.
* **🛠️ Rich Toolbox**: Built-in tools for WARP, BBR, port management, SNI optimization, and more.


## 📋 Requirements

* **OS**: Debian 10+, Ubuntu 20.04+ (Debian 11/12 recommended)
* **Architecture**: amd64, arm64
* **Permissions**: `root` access required
* **Ports**: Uses high random ports by default (for Vision and XHTTP).
* **Client**: Ensure your client supports these protocols (e.g., Shadowrocket, v2rayN, etc.)


## 📥 Quick Start

### 🚀 Recommended: One-Click Installation (Bootstrap)

Run the following command as the `root` user. The bootstrap script will automatically install Git, clone the repository, and start the installer.

```bash
bash <(curl -sL https://raw.githubusercontent.com/carlleilzj/Xray-Auto/main/bootstrap.sh)

```

### 🛠️ Alternative: Manual Installation
If you cannot connect to GitHub Raw, you can try cloning manually:

```bash
# 1. Install Git
apt update && apt install -y git

# 2. Clone the repository
git clone https://github.com/carlleilzj/Xray-Auto.git xray-install

# 3. Run the script
cd xray-install
chmod +x install.sh
./install.sh

```


## 🗑️ Uninstall

If you want to completely remove Xray and its related configurations, run the following (or type remove in the server terminal):

```bash
bash <(curl -sL https://raw.githubusercontent.com/carlleilzj/Xray-Auto/main/tools/remove.sh)

```

## 🎮 Usage Guide

After installation, the management tools are registered to the system path. You can enter the following commands directly in the terminal:

| Command | Function | Description |
| :--- | :--- | :--- |
| `info` | **Admin Dashboard** | View node links, QR codes, service status, and the shortcut menu. |
| `user` | **User Management** | Query, add, or delete users. |
| `ports` | **Port Management** | Modify SSH, Vision, or XHTTP ports and automatically update firewall rules. |
| `net` | **Network Policy** | Switch IPv4/IPv6 priority or force single-stack mode. |
| `xw` | **WARP Manager** | Install Cloudflare WARP for Netflix/ChatGPT routing. |
| `bbr` | **Kernel Optimization** | Enable/Disable BBR acceleration, adjust queue algorithms (FQ/FQ_CODEL). |
| `sni` | **SNI Management** | Automatically test and select optimal SNI domains, or specify manually. |
| `bt` | **Audit Management** | One-click toggle for blocking BitTorrent downloads and private IP access. |
| `swap` | **Memory Management** | Add/Remove Swap partitions and adjust Swappiness. |
| `f2b` | **Fail2ban** | View banned IPs, unban IPs, and adjust banning policies. |
| `backup` | **Backup & Restore** | Query, backup, and restore configurations. |
| `sniff` | **Traffic Sniffing** | Enable/Disable traffic sniffing and logging. |
| `zone` | **Timezone Manager** | Configure timezone and system time. |
| `update` | **Updata** | Updata Xray core and Geodata。 |
| `remove` | **Uninstall** | Remove Xray and all installed components. |


### 📝 Client Configuration Reference

| Parameter | Value (Example) | Description |
| :--- | :--- | :--- |
| **Address** | `1.2.3.4` or `[2001::1]` | Server IP |
| **Port** | `443` | Port set during installation |
| **UUID** | `de305d54-...` | Type `info` to retrieve |
| **Flow** | `xtls-rprx-vision` | **Required for Vision nodes only** |
| **Network**| `tcp` or `xhttp` | Select TCP for Vision, xhttp for XHTTP |
| **SNI** | `www.microsoft.com` | Type `info` to retrieve |
| **Fingerprint**| `chrome` | Recommended fingerprint |
| **Public Key** | `B9s...` | Type `info` to retrieve |
| **ShortId** | `a1b2...` | Type `info` to retrieve |
| **Path** | `/8d39f310` | **Required for XHTTP nodes only** |


## 📂 Project Structure

This project uses a modular architecture with the following directory structure:

```text
.
├── bootstrap.sh       # One-click bootstrap script (Download, verify, start)
├── install.sh         # Main installation entry (Orchestration, lock mechanism)
├── lib/
│   └── utils.sh       # Common function library (UI, Logs, Colors, Task executor)
├── core/              # Core installation process
│   ├── 1_env.sh       # Environment check and initialization
│   ├── 2_install.sh   # Dependency and Xray core installation
│   ├── 3_system.sh    # System configuration (Firewall, Kernel)
│   └── 4_config.sh    # Configuration generation and service startup
└── tools/             # Standalone tools (Deployed to /usr/local/bin after install)
    ├── info.sh
    ├── ports.sh
    ├── net.sh
    ├── ...
```


## 🔄 How to Keep Your Fork Updated

If you have forked this repository, you can keep it synced with the upstream repository using one of the following two methods:

### Method 1: Manual Sync (Recommended to preserve your own changes)
1. Go to your forked repository's homepage on GitHub.
2. Find and click the **"Sync fork"** button located under the green "Code" button.
3. Click **"Update branch"** to pull the latest changes from the upstream repository.

### Method 2: Auto Sync (Via GitHub Actions - WARNING: Overwrites local changes)
This repository includes a built-in GitHub Actions workflow that automatically forces synchronization every day. **⚠️ PLEASE NOTE: Enabling this feature will force-overwrite any independent modifications you have made on the default branch with upstream updates. If you plan to do your own development, please create a new branch.**
1. Go to the **"Actions"** tab of your forked repository.
2. Click **"I understand my workflows, go ahead and enable them"** to activate GitHub Actions.
3. Once enabled, the `Auto Sync Upstream` workflow will run automatically on schedule (you can also find it in the left sidebar to trigger it manually).


## 💖 Sponsor & Support

This project is completely free and open-source. If you find this script helpful, if it saves you time, and you'd like to support ongoing development and server maintenance, consider use my aff! Your support is my greatest motivation.

### 🌐 VPS Purchasing Recommendations

To ensure the best proxy experience, please consider the following points when selecting a VPS:

* **Routing Quality**:
    * **China Telecom Users**: Priority should be given to **CN2 GIA** lines.
    * **China Unicom Users**: Priority should be given to **AS9929** or **AS4837** lines.
    * **China Mobile Users**: Priority should be given to **CMIN2** lines.
* **IP Purity**: Choose **Native IPs** or data centers with low abuse rates. While Reality protocols mask traffic, blacklisted IPs will still fail to unlock streaming services like Netflix or Disney+.
* **Virtualization Architecture**: **KVM** is strongly recommended. OpenVZ (OVZ) does not support BBR acceleration, which severely limits speeds during peak hours.

## ⚖️ Legal Disclaimer

**The internet is not a lawless place.**

1. **Educational & Research Purposes Only:** This project (Xray-Reality scripts and configurations) is intended solely for network technology research, academic exchange, and system testing. Do not use this script for any purposes that violate national laws and regulations.
2. **Legal Compliance:** When using this script, you must strictly comply with the laws and regulations of your country/region and the jurisdiction where your server is located. It is strictly forbidden to use this project to distribute illegal content, including but not limited to politics, religion, pornography, or fraud. The user bears full responsibility for any legal consequences and joint liabilities arising from illegal use or abuse. The author of this project assumes no responsibility whatsoever.
3. **No Warranty (AS IS):** This software is provided "AS IS", without warranty of any kind, express or implied. The author is not liable for any direct or indirect damages caused by the use of this script (including but not limited to data loss, system crashes, IP blocking, or server suspension/termination by hosting providers).
4. **Third-Party Components:** This script integrates third-party open-source programs (such as `Xray-core`). Their copyrights and liabilities belong to their respective original authors. The author of this script makes no guarantees regarding the security, compliance, or stability of these third-party programs.
5. **License:** This project is licensed under the GNU General Public License v3.0 (GPL-3.0). Please refer to the `LICENSE` file in the repository for detailed terms. By downloading, installing, or using this project, you acknowledge that you have read and fully agreed to all terms of this disclaimer and the open-source license.

*Copyright © ISFZY. Dedicated to the purest network routing experience.*

