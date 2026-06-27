#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; PLAIN='\033[0m'

clear
echo -e "${BLUE}================================================${PLAIN}"
echo -e "${BLUE}        AnyTLS v0.0.13 一键安装                  ${PLAIN}"
echo -e "${BLUE}        https://github.com/anytls/anytls-go       ${PLAIN}"
echo -e "${BLUE}================================================${PLAIN}"
echo ""

# 权限检查
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}请使用 root 运行此脚本${PLAIN}"
    exit 1
fi

# 架构检测
ARCH=$(uname -m)
case $ARCH in
    x86_64)     ASSET="anytls_0.0.13_linux_amd64.zip" ;;
    aarch64|arm64) ASSET="anytls_0.0.13_linux_arm64.zip" ;;
    *) echo -e "${RED}不支持的架构: $ARCH${PLAIN}"; exit 1 ;;
esac

# 端口选择
PORT=8443
while ss -tlnp 2>/dev/null | grep -q ":${PORT} "; do
    PORT=$((PORT + 1))
done

read -p "$(echo -e ${GREEN}"监听端口 [默认 ${PORT}]: "${PLAIN})" INPUT_PORT
PORT=${INPUT_PORT:-$PORT}

# 生成密码
PASSWORD=$(head -c 24 /dev/urandom | base64 | tr -d '=+/' | head -c 20)
read -p "$(echo -e ${GREEN}"密码 [默认随机: ${PASSWORD}]: "${PLAIN})" INPUT_PASS
PASSWORD=${INPUT_PASS:-$PASSWORD}

# 下载安装
echo -e "${BLUE}>>> 下载 AnyTLS v0.0.13...${PLAIN}"
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

DOWNLOAD_URL="https://github.com/anytls/anytls-go/releases/download/v0.0.13/${ASSET}"
if ! curl -sL --connect-timeout 10 "$DOWNLOAD_URL" -o "$ASSET"; then
    echo -e "${RED}下载失败，请检查网络${PLAIN}"
    rm -rf "$TMP_DIR"
    exit 1
fi

unzip -o "$ASSET" > /dev/null
chmod +x anytls-server
mv anytls-server /usr/local/bin/
rm -rf "$TMP_DIR"

echo -e "${GREEN}AnyTLS 安装完成: v0.0.13${PLAIN}"

# systemd 服务
echo -e "${BLUE}>>> 配置 systemd 服务...${PLAIN}"

cat > /etc/systemd/system/anytls.service << EOF
[Unit]
Description=AnyTLS Proxy Service
Documentation=https://github.com/anytls/anytls-go
After=network.target

[Service]
ExecStart=/usr/local/bin/anytls-server -l 0.0.0.0:${PORT} -p ${PASSWORD}
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable anytls
systemctl restart anytls

# 防火墙放行
if command -v ufw &> /dev/null && ufw status 2>/dev/null | grep -q "active"; then
    ufw allow ${PORT}/tcp > /dev/null 2>&1
elif command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    firewall-cmd --add-port=${PORT}/tcp --permanent > /dev/null 2>&1
    firewall-cmd --reload > /dev/null 2>&1
fi
iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT 2>/dev/null

# 获取 IP
IP=$(curl -s4 ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')
IP6=$(curl -s6 ifconfig.me 2>/dev/null || echo "")

sleep 1

# 输出结果
echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}         安装完成！${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""
echo -e "  协议:      ${YELLOW}AnyTLS${PLAIN}"
echo -e "  地址:      ${YELLOW}${IP}${PLAIN}"
[[ -n "$IP6" ]] && echo -e "  IPv6:      ${YELLOW}${IP6}${PLAIN}"
echo -e "  端口:      ${YELLOW}${PORT}${PLAIN}"
echo -e "  密码:      ${YELLOW}${PASSWORD}${PLAIN}"
echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}  客户端链接${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""
echo -e "  ${YELLOW}anytls://${PASSWORD}@${IP}:${PORT}${PLAIN}"
[[ -n "$IP6" ]] && echo -e "  ${YELLOW}anytls://${PASSWORD}@[${IP6}]:${PORT}${PLAIN}"
echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}  管理命令${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""
echo -e "  状态:      ${BLUE}systemctl status anytls${PLAIN}"
echo -e "  日志:      ${BLUE}journalctl -u anytls -f${PLAIN}"
echo -e "  重启:      ${BLUE}systemctl restart anytls${PLAIN}"
echo -e "  卸载:      ${BLUE}systemctl disable --now anytls${PLAIN}"
echo -e "             ${BLUE}rm /usr/local/bin/anytls-server /etc/systemd/system/anytls.service${PLAIN}"
echo ""

# 支持客户端检测
case "$(uname -s)" in
    Darwin) echo -e "  macOS 客户端: ${YELLOW}anytls_0.0.13_darwin_arm64.zip${PLAIN}" ;;
esac
