#!/bin/bash
# Nowhere v1 一键安装/卸载脚本
# 协议: https://github.com/NodePassProject/Nowhere
# 客户端: Anywhere (iOS/macOS)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; PLAIN='\033[0m'
NOWHERE_VER="v1.2.3"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/nowhere"
SERVICE_FILE="/etc/systemd/system/nowhere.service"

clear
echo -e "${BLUE}================================================${PLAIN}"
echo -e "${BLUE}     Nowhere ${NOWHERE_VER} 一键安装/卸载             ${PLAIN}"
echo -e "${BLUE}     https://github.com/NodePassProject/Nowhere    ${PLAIN}"
echo -e "${BLUE}================================================${PLAIN}"
echo ""

[[ $EUID -ne 0 ]] && echo -e "${RED}请用 root 运行${PLAIN}" && exit 1

# ---------- 卸载模式 ----------
if [[ "$1" == "uninstall" || "$1" == "--uninstall" || "$1" == "-u" ]]; then
    echo -e "${YELLOW}>>> 卸载 Nowhere...${PLAIN}"
    systemctl disable --now nowhere 2>/dev/null
    rm -f "$SERVICE_FILE"
    rm -rf "$CONFIG_DIR"
    rm -f "$INSTALL_DIR/nowhere"
    systemctl daemon-reload
    echo -e "${GREEN}已卸载完成${PLAIN}"
    exit 0
fi

# ---------- 架构检测 ----------
ARCH=$(uname -m)
case $ARCH in
    x86_64|amd64)   ASSET="nowhere-x86_64-unknown-linux-musl.tar.gz" ;;
    aarch64|arm64)  ASSET="nowhere-aarch64-unknown-linux-musl.tar.gz" ;;
    *) echo -e "${RED}不支持的架构: $ARCH${PLAIN}"; exit 1 ;;
esac

# ---------- 交互参数 ----------
PORT=2077
while ss -tlnp 2>/dev/null | grep -q ":${PORT} "; do PORT=$((PORT + 1)); done
read -p "$(echo -e ${GREEN}"监听端口 [默认 ${PORT}]: "${PLAIN})" INPUT_PORT
PORT=${INPUT_PORT:-$PORT}

KEY=$(head -c 32 /dev/urandom | base64 | tr -d '=+/' | head -c 24)
read -p "$(echo -e ${GREEN}"共享密钥 [默认随机: ${KEY}]: "${PLAIN})" INPUT_KEY
KEY=${INPUT_KEY:-$KEY}

read -p "$(echo -e ${GREEN}"spec [默认 nightfall]: "${PLAIN})" SPEC
SPEC=${SPEC:-nightfall}

echo -e "${YELLOW}网络模式:${PLAIN}"
echo -e "  1. mix (TLS/TCP + QUIC/UDP, 推荐)"
echo -e "  2. tcp (仅 TLS/TCP)"
echo -e "  3. udp (仅 QUIC/UDP)"
read -p "$(echo -e ${GREEN}"选择 [1]: "${PLAIN})" NET_CHOICE
case $NET_CHOICE in
    2) NET="tcp" ;;
    3) NET="udp" ;;
    *) NET="mix" ;;
esac

# ---------- 下载安装 ----------
echo -e "${BLUE}>>> 下载 Nowhere ${NOWHERE_VER}...${PLAIN}"
TMP=$(mktemp -d) && cd "$TMP"
URL="https://github.com/NodePassProject/Nowhere/releases/download/${NOWHERE_VER}/${ASSET}"
if ! curl -sL --connect-timeout 10 "$URL" -o "$ASSET"; then
    echo -e "${RED}下载失败${PLAIN}"; rm -rf "$TMP"; exit 1
fi
tar xzf "$ASSET" > /dev/null 2>&1
chmod +x nowhere && mv nowhere "$INSTALL_DIR/"
rm -rf "$TMP"
echo -e "${GREEN}Nowhere 安装完成: ${NOWHERE_VER}${PLAIN}"

# ---------- 配置 ----------
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/nowhere.env" << EOF
KEY=${KEY}
PORT=${PORT}
SPEC=${SPEC}
NET=${NET}
EOF

# ---------- systemd ----------
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Nowhere Portal Service
Documentation=https://github.com/NodePassProject/Nowhere
After=network.target

[Service]
ExecStart=${INSTALL_DIR}/nowhere 'portal://${KEY}@0.0.0.0:${PORT}?spec=${SPEC}&net=${NET}&tls=1'
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now nowhere

# ---------- 防火墙 ----------
iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT 2>/dev/null
iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT 2>/dev/null
ufw allow ${PORT}/tcp > /dev/null 2>&1
ufw allow ${PORT}/udp > /dev/null 2>&1

# ---------- 等待启动 ----------
sleep 2

# ---------- 输出 ----------
IP=$(curl -s4 ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')

echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}         安装完成！${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""
echo -e "  协议:      ${YELLOW}Nowhere${PLAIN}"
echo -e "  地址:      ${YELLOW}${IP}${PLAIN}"
echo -e "  端口:      ${YELLOW}${PORT}${PLAIN}"
echo -e "  密钥:      ${YELLOW}${KEY}${PLAIN}"
echo -e "  spec:      ${YELLOW}${SPEC}${PLAIN}"
echo -e "  网络:      ${YELLOW}${NET}${PLAIN}"
echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}  Anywhere 客户端订阅链接${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""

# 构造 nowhere:// 链接 (Anywhere 客户端格式)
# insecure=1 因为 tls=1 是自签证书
NOWHERE_URI="nowhere://${KEY}@${IP}:${PORT}?net=${NET}&spec=${SPEC}&sni=${IP}&insecure=1"
echo -e "  ${YELLOW}${NOWHERE_URI}${PLAIN}"
echo ""
echo -e "  ${BLUE}导入方式: 在 Anywhere app 中 Add Proxy -> 粘贴上方链接${PLAIN}"
echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}  管理命令${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""
echo -e "  状态:      ${BLUE}systemctl status nowhere${PLAIN}"
echo -e "  日志:      ${BLUE}journalctl -u nowhere -f${PLAIN}"
echo -e "  重启:      ${BLUE}systemctl restart nowhere${PLAIN}"
echo -e "  卸载:      ${BLUE}bash <(curl -sL https://raw.githubusercontent.com/carlleilzj/Xray-Auto/main/tools/nowhere.sh) uninstall${PLAIN}"
echo ""
echo -e "  或一键卸载:"
echo -e "  ${BLUE}bash \$(curl -sL https://raw.githubusercontent.com/carlleilzj/Xray-Auto/main/tools/nowhere.sh) uninstall${PLAIN}"
echo ""
