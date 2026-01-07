#!/bin/bash
# ==============================================================
# Project: Xray Auto Installer
# Author: accforeve
# Repository: https://github.com/accforeve/Xray-Auto
# Version: v0.2 VLESS+reality-Vision/xhttp
# ==============================================================

# --- 1. 系统环境强制检查 ---
if [ ! -f /etc/debian_version ]; then
    echo -e "\033[31mError: 本脚本仅支持 Debian 或 Ubuntu 系统！CentOS/RedHat 请勿运行。\033[0m"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root!"
    exit 1
fi

# 颜色定义
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
PLAIN="\033[0m"

clear
echo -e "${GREEN}🚀 开始部署 ...${PLAIN}"

# --- 0. 强制解锁 ---
echo "🔄 检测并清理后台 apt 进程..."
killall apt apt-get 2>/dev/null
rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock*
dpkg --configure -a

# --- 1. 系统初始化 ---
timedatectl set-timezone Asia/Shanghai
export DEBIAN_FRONTEND=noninteractive

echo "📦 更新系统并安装依赖 (此过程可能需要几分钟)..."
# 系统升级：遇到配置冲突自动保留旧配置
apt-get update -qq
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# 安装核心依赖
DEPENDENCIES="curl wget sudo nano git htop tar unzip socat fail2ban rsyslog chrony iptables qrencode iptables-persistent"
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" $DEPENDENCIES

# 二次检查
if ! command -v fail2ban-client &> /dev/null; then
    echo -e "\033[31m❌ 严重错误：软件安装失败。可能是网络源问题，请重试。\033[0m"
    exit 1
fi

# 预先设置 iptables-persistent 的配置选项
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

# 安装基础工具
apt-get install -y debconf-utils psmisc curl wget sudo nano git htop tar unzip socat fail2ban rsyslog chrony qrencode iptables-persistent netfilter-persistent ipset ca-certificates || { echo -e "${RED}依赖安装失败。${PLAIN}"; exit 1; }

# --- 2. 系统优化 ---
echo "⚙️ 执行系统优化..."
# 检测内存，如果小于2GB且没有Swap，则创建1G虚拟内存
if [ "$(free -m | grep Mem | awk '{print $2}')" -lt 2048 ] && [ "$(swapon --show | wc -l)" -lt 2 ]; then
    echo "  - 检测到小内存机器，正在创建 Swap..."
    fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024 status=none
    chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "  - Swap 创建完成"
fi

# 开启 BBR
if ! grep -q "tcp_congestion_control=bbr" /etc/sysctl.conf; then
    echo "  - 开启 BBR..."
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

# 限制 systemd 日志
if ! grep -q "SystemMaxUse=200M" /etc/systemd/journald.conf; then
    echo "SystemMaxUse=200M" >> /etc/systemd/journald.conf
    systemctl restart systemd-journald
fi

# --- 3. 安装 Xray ---
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
mkdir -p /usr/local/share/xray/
wget -q -O /usr/local/share/xray/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget -q -O /usr/local/share/xray/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

# --- 4. 配置生成 ---
XRAY_BIN="/usr/local/bin/xray"
echo "🔍 正在进行 SNI 优选 (寻找连接微软/苹果最快的域名作为伪装)..."
DOMAINS=("www.icloud.com" "www.apple.com" "itunes.apple.com" "learn.microsoft.com" "www.microsoft.com" "www.bing.com")
BEST_MS=9999
BEST_DOMAIN="www.icloud.com"

# === 智能 SNI 优选逻辑 ===
echo "🔍 正在进行智能 SNI 优选..."
DOMAINS=("www.icloud.com" "www.apple.com" "itunes.apple.com" "learn.microsoft.com" "www.microsoft.com" "www.bing.com")
BEST_MS=9999
BEST_DOMAIN=""

echo -ne "\033[?25l"
for domain in "${DOMAINS[@]}"; do
    echo -ne "  👉 测试: $domain...\r"
    time_cost=$(LC_NUMERIC=C curl -4 -w "%{time_connect}" -o /dev/null -s --connect-timeout 2 "https://$domain")
    if [ -n "$time_cost" ] && [ "$time_cost" != "0.000" ]; then
        ms=$(LC_NUMERIC=C awk -v t="$time_cost" 'BEGIN { printf "%.0f", t * 1000 }')
        if [ "$ms" -lt "$BEST_MS" ]; then
            BEST_MS=$ms
            BEST_DOMAIN=$domain
        fi
    fi
done
echo -ne "\033[?25h"
echo ""

if [ -z "$BEST_DOMAIN" ]; then BEST_DOMAIN="www.icloud.com"; fi
SNI_HOST="$BEST_DOMAIN"
echo -e "✅ 优选结果: \033[36m$SNI_HOST\033[0m (延迟: ${BEST_MS}ms)"

echo "🔑 生成身份密钥..."
UUID=$($XRAY_BIN uuid)
KEYS=$($XRAY_BIN x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private" | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEYS" | grep -E "Public|Password" | awk '{print $2}')
SHORT_ID=$(openssl rand -hex 8)
XHTTP_PATH="/req"

# 写入配置文件 (Block CN 版 - 默认)
mkdir -p /usr/local/etc/xray/
cat > /usr/local/etc/xray/config.json <<CONFIG_EOF
{
  "log": { "loglevel": "warning" },
  "dns": { "servers": [ "1.1.1.1", "8.8.8.8", "localhost" ] },
  "inbounds": [
    {
      "tag": "vision_node",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "${UUID}", "flow": "xtls-rprx-vision" } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${SNI_HOST}:443",
          "serverNames": [ "${SNI_HOST}" ],
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": [ "${SHORT_ID}" ],
          "fingerprint": "chrome"
        }
      },
      "sniffing": { "enabled": true, "destOverride": [ "http", "tls", "quic" ], "routeOnly": true }
    },
    {
      "tag": "xhttp_node",
      "port": 8443,
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "${UUID}", "flow": "" } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "xhttpSettings": { "path": "${XHTTP_PATH}" },
        "realitySettings": {
          "show": false,
          "dest": "${SNI_HOST}:443",
          "serverNames": [ "${SNI_HOST}" ],
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": [ "${SHORT_ID}" ],
          "fingerprint": "chrome"
        }
      },
      "sniffing": { "enabled": true, "destOverride": [ "http", "tls", "quic" ], "routeOnly": true }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "block" }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      { "type": "field", "ip": [ "geoip:private", "geoip:cn" ], "outboundTag": "block" },
      { "type": "field", "protocol": [ "bittorrent" ], "outboundTag": "block" }
    ]
  }
}
CONFIG_EOF

# --- 5. 服务与 GeoIP 更新 ---
echo "🛠 配置 systemd 服务..."
mkdir -p /etc/systemd/system/xray.service.d
echo -e "[Service]\nLimitNOFILE=infinity\nLimitNPROC=infinity\nTasksMax=infinity\nRestart=on-failure\nRestartSec=5" > /etc/systemd/system/xray.service.d/override.conf
systemctl daemon-reload

# 生成自动更新 GeoIP 脚本
echo -e "#!/bin/bash\nwget -q -O /usr/local/share/xray/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat\nwget -q -O /usr/local/share/xray/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat\nsystemctl restart xray" > /usr/local/bin/update_geoip.sh && chmod +x /usr/local/bin/update_geoip.sh
(crontab -l 2>/dev/null; echo "0 4 * * 2 /usr/local/bin/update_geoip.sh >/dev/null 2>&1") | sort -u | crontab -

# --- 6. 防火墙配置 ---
echo "🛡️ 配置防火墙 (IPv4 & IPv6)..."

SSH_PORT_CONFIG=$(grep "^Port" /etc/ssh/sshd_config | head -n 1 | awk '{print $2}')
SSH_PORT_PROCESS=$(ss -tlnp | grep sshd | grep LISTEN | head -n 1 | awk '{print $4}' | sed 's/.*://')

if [ -n "$SSH_PORT_PROCESS" ] && [[ "$SSH_PORT_PROCESS" =~ ^[0-9]+$ ]]; then
    SSH_PORT="$SSH_PORT_PROCESS"
elif [ -n "$SSH_PORT_CONFIG" ] && [[ "$SSH_PORT_CONFIG" =~ ^[0-9]+$ ]]; then
    SSH_PORT="$SSH_PORT_CONFIG"
else
    SSH_PORT=22
fi

echo -e "==========================================================="
echo -e "${YELLOW}⚠️  即将应用防火墙规则${PLAIN}"
echo -e "SSH 端口: ${RED}${SSH_PORT}${PLAIN} (同时放行 22 以防失联)"
echo -e "==========================================================="
sleep 3

# IPv4 Rules
iptables -F
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -p tcp --dport "$SSH_PORT" -j ACCEPT
if [ "$SSH_PORT" != "22" ]; then iptables -A INPUT -p tcp --dport 22 -j ACCEPT; fi
iptables -A INPUT -p tcp -m multiport --dports 443,8443 -j ACCEPT
iptables -A INPUT -p udp -m multiport --dports 443,8443 -j ACCEPT
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# IPv6 Rules
if [ -f /proc/net/if_inet6 ]; then
    ip6tables -F
    ip6tables -A INPUT -i lo -j ACCEPT
    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A INPUT -p ipv6-icmp -j ACCEPT
    ip6tables -A INPUT -p tcp --dport "$SSH_PORT" -j ACCEPT
    if [ "$SSH_PORT" != "22" ]; then ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT; fi
    ip6tables -A INPUT -p tcp -m multiport --dports 443,8443 -j ACCEPT
    ip6tables -A INPUT -p udp -m multiport --dports 443,8443 -j ACCEPT
    ip6tables -P INPUT DROP
    ip6tables -P FORWARD DROP
    ip6tables -P OUTPUT ACCEPT
fi

netfilter-persistent save

# 配置 Fail2Ban
echo "🔒 配置 Fail2Ban 保护 SSH..."
mkdir -p /etc/fail2ban
cat > /etc/fail2ban/jail.local << FAIL2BAN_EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
findtime  = 1d
maxretry = 3
bantime  = 24h
bantime.increment = true
backend = systemd
banaction = iptables-multiport
[sshd]
enabled = true
port    = $SSH_PORT,22
mode    = aggressive
FAIL2BAN_EOF
systemctl restart rsyslog
systemctl enable fail2ban
systemctl restart fail2ban

# --- 7. Mode 切换脚本 ---
cp /usr/local/etc/xray/config.json /usr/local/etc/xray/config_block.json
sed 's/, "geoip:cn"//g' /usr/local/etc/xray/config_block.json > /usr/local/etc/xray/config_allow.json

cat > /usr/local/bin/mode << 'MODE_EOF'
#!/bin/bash
GREEN='\033[32m'
RED='\033[31m'
WHITE='\033[37m'
YELLOW='\033[33m'
PLAIN='\033[0m'
CONFIG="/usr/local/etc/xray/config.json"
BLOCK_CFG="/usr/local/etc/xray/config_block.json"
ALLOW_CFG="/usr/local/etc/xray/config_allow.json"

set_block() { cp "$BLOCK_CFG" "$CONFIG"; systemctl restart xray; echo -e "✅ 已切换为: ${GREEN}阻断回国 (Block CN)${PLAIN}"; }
set_allow() { cp "$ALLOW_CFG" "$CONFIG"; systemctl restart xray; echo -e "✅ 已切换为: ${RED}允许回国 (Allow CN)${PLAIN}"; }

if grep -q "geoip:cn" "$CONFIG"; then
    OPT_1="${GREEN} 1. 阻断回国 (Block CN) [当前]${PLAIN}"
    OPT_2="${WHITE} 2. 允许回国 (Allow CN)${PLAIN}"
else
    OPT_1="${WHITE} 1. 阻断回国 (Block CN)${PLAIN}"
    OPT_2="${GREEN} 2. 允许回国 (Allow CN) [当前]${PLAIN}"
fi

clear
echo "=============================="
echo "    Xray 模式切换 (Mode)"
echo "=============================="
echo -e "$OPT_1"
echo -e "$OPT_2"
echo "------------------------------"
read -p "请选择 [1-2] (输入其他任意键退出): " choice
case "$choice" in
    1) set_block ;;
    2) set_allow ;;
    *) echo "已退出模式切换。"; exit 0 ;;
esac
MODE_EOF
chmod +x /usr/local/bin/mode
systemctl enable xray && systemctl restart xray

# --- 8. 结果回显 ---
# 使用 Cloudflare 获取 IP，防止 ip.sb 出现 403 错误
IPV4=$(curl -s4m 5 https://1.1.1.1/cdn-cgi/trace | grep "ip=" | cut -d= -f2)
if [ -z "$IPV4" ]; then IPV4=$(curl -s4m 5 https://api.ipify.org); fi

HOST_TAG=$(hostname | tr ' ' '.')
[ -z "$HOST_TAG" ] && HOST_TAG="XrayServer"

LINK_VISION="vless://${UUID}@${IPV4}:443?security=reality&encryption=none&pbk=${PUBLIC_KEY}&headerType=none&fp=chrome&type=tcp&flow=xtls-rprx-vision&sni=${SNI_HOST}&sid=${SHORT_ID}#${HOST_TAG}_Vision"
LINK_XHTTP="vless://${UUID}@${IPV4}:8443?security=reality&encryption=none&pbk=${PUBLIC_KEY}&headerType=none&fp=chrome&type=xhttp&path=${XHTTP_PATH}&sni=${SNI_HOST}&sid=${SHORT_ID}#${HOST_TAG}_xhttp"

echo -e ""
echo -e "${GREEN}部署成功 (Deployment Success)${PLAIN}"
echo "=========================================================="
echo -e "${YELLOW}服务器详细配置:${PLAIN}"
echo "----------------------------------------------------------"
echo -e "  地址 (IP)       : ${BLUE}${IPV4}${PLAIN}"
echo -e "  优选 SNI        : ${YELLOW}${SNI_HOST}${PLAIN}"
echo -e "  UUID            : ${BLUE}${UUID}${PLAIN}"
echo -e "  Short ID        : ${BLUE}${SHORT_ID}${PLAIN}"
echo -e "  Public Key      : ${BLUE}${PUBLIC_KEY}${PLAIN}"
echo "----------------------------------------------------------"
echo -e "  节点 1 (主力)   : 端口 ${BLUE}443${PLAIN}   流控: ${BLUE}xtls-rprx-vision${PLAIN}"
echo -e "  节点 2 (备用)   : 端口 ${BLUE}8443${PLAIN}  协议: ${BLUE}xhttp${PLAIN}  路径: ${BLUE}${XHTTP_PATH}${PLAIN}"
echo "----------------------------------------------------------"
echo -e "  当前模式        : ${GREEN}阻断回国 (Block CN)${PLAIN} (输入 ${GREEN}mode${PLAIN} 切换)"
echo -e "  防火墙          : 已放行端口 ${SSH_PORT} 和 22 (SSH)"
echo "----------------------------------------------------------"
echo -e "${RED}注意: xhttp 节点需要 Xray-core v1.8.24+ 才能连接！${PLAIN}"
echo "----------------------------------------------------------"
echo -e "${YELLOW}👇 节点1 链接 (Vision - 推荐):${PLAIN}"
echo -e "${GREEN}${LINK_VISION}${PLAIN}"
echo ""
echo -e "${YELLOW}👇 节点2 链接 (xhttp - 备用):${PLAIN}"
echo -e "${GREEN}${LINK_XHTTP}${PLAIN}"
echo ""
echo -e "${YELLOW}👇 节点1 二维码:${PLAIN}"
qrencode -t ANSIUTF8 "${LINK_VISION}"
echo ""
echo -e "${YELLOW}👇 节点2 二维码:${PLAIN}"
qrencode -t ANSIUTF8 "${LINK_XHTTP}"
echo ""
