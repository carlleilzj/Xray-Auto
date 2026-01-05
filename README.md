# Xray Auto Installer

![GitHub release (latest by date)](https://img.shields.io/github/v/release/accforeve/Xray-Auto?style=flat-square)
![License](https://img.shields.io/github/license/accforeve/Xray-Auto?style=flat-square)

> A lightweight, robust, and interactive installer for Xray (VLESS + Reality + Vision).
> 支持 IPv4/IPv6 双栈，智能防卡死，自动修复系统时间与依赖。

## ✨ Features (功能特性)

- 🚀 **VLESS + Reality + Vision**：目前最先进的抗封锁协议组合。
- 🛡️ **安全加固**：自动配置双栈防火墙 (IPv4/IPv6)，仅放行必要端口，屏蔽暴力破解。
- 🌐 **智能优选**：根据网络环境自动识别 v4/v6 IP，自动优选低延迟大厂 SNI。
- 🔧 **高度健壮**：
  - 自动解决 `dpkg` 锁占用与数据库损坏问题。
  - 强制时间同步，解决因时间偏差导致的证书错误。
  - 内存不足时自动创建 Swap。
- 🐳 **纯净安装**：移除冗余依赖，采用系统原生指令 (`ss`, `fuser`, `ip`)。

## 📥 Installation (一键安装)

**系统要求**：Debian 10+ / Ubuntu 20.04+ (推荐 Debian 12)
**权限要求**：root 用户

```bash
bash <(curl -Ls [https://raw.githubusercontent.com/accforeve/Xray-Auto/main/install.sh](https://raw.githubusercontent.com/accforeve/Xray-Auto/main/install.sh))


📜 License
本项目基于 MIT License 开源。

