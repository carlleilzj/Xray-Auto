#!/bin/bash
# =========================================
# Snell v5 + ShadowTLS v3 一键安装
# =========================================
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; PLAIN='\033[0m'
clear
echo -e "${BLUE}================================================${PLAIN}"
echo -e "${BLUE}     Snell v5 + ShadowTLS v3 一键安装             ${PLAIN}"
echo -e "${BLUE}================================================${PLAIN}"
echo ""

[[ $EUID -ne 0 ]] && echo -e "${RED}请用 root 运行${PLAIN}" && exit 1

# ---------- 架构检测 ----------
ARCH=$(uname -m)
case $ARCH in
    x86_64|amd64)  SNELL_ARCH="amd64"; STLS_ARCH="x86_64-unknown-linux-musl" ;;
    aarch64|arm64) SNELL_ARCH="aarch64"; STLS_ARCH="aarch64-unknown-linux-musl" ;;
    armv7l)        SNELL_ARCH="armv7l"; STLS_ARCH="armv7-unknown-linux-musleabihf" ;;
    *) echo -e "${RED}不支持的架构: $ARCH${PLAIN}"; exit 1 ;;
esac

# ---------- 依赖安装 ----------
echo -e "${BLUE}>>> 安装依赖...${PLAIN}"
apt-get update -qq > /dev/null 2>&1
apt-get install -y -qq curl unzip jq iptables > /dev/null 2>&1

# ---------- 端口选择 ----------
SNELL_PORT=6160
while ss -tlnp 2>/dev/null | grep -q ":${SNELL_PORT} "; do SNELL_PORT=$((SNELL_PORT+1)); done

STLS_PORT=8989
while ss -tlnp 2>/dev/null | grep -q ":${STLS_PORT} "; do STLS_PORT=$((STLS_PORT+1)); done

read -p "$(echo -e ${GREEN}"Snell 内网端口 [默认 ${SNELL_PORT}]: "${PLAIN})" INPUT
SNELL_PORT=${INPUT:-$SNELL_PORT}

read -p "$(echo -e ${GREEN}"ShadowTLS 对外端口 [默认 ${STLS_PORT}]: "${PLAIN})" INPUT
STLS_PORT=${INPUT:-$STLS_PORT}

read -p "$(echo -e ${GREEN}"伪装 SNI [默认 www.microsoft.com]: "${PLAIN})" TLS_SNI
TLS_SNI=${TLS_SNI:-www.microsoft.com}

# ---------- Snell v5 ----------
echo -e "${BLUE}>>> 安装 Snell v5...${PLAIN}"
SNELL_VER=$(curl -s "https://manual.nssurge.com/others/snell.html" 2>/dev/null | grep -oP 'snell-server-v\K5\.[0-9]+\.[0-9]+[a-z0-9]*' | grep -v 'b[0-9]' | head -1)
SNELL_VER=${SNELL_VER:-5.0.0}
echo -e "  Snell 版本: v${SNELL_VER}"

TMP=$(mktemp -d) && cd "$TMP"
curl -sLO "https://dl.nssurge.com/snell/snell-server-v${SNELL_VER}-linux-${SNELL_ARCH}.zip"
unzip -o snell-server-*.zip > /dev/null && chmod +x snell-server && mv snell-server /usr/local/bin/
rm -rf "$TMP"

mkdir -p /etc/snell
SNELL_PSK=$(head -c 24 /dev/urandom | base64 | tr -d '=+/' | head -c 20)

cat > /etc/snell/snell-server.conf << EOF
listen = ::0:${SNELL_PORT}
psk=${SNELL_PSK}
obfs=off
dns=1.1.1.1,8.8.8.8
EOF

cat > /etc/systemd/system/snell.service << EOF
[Unit]
Description=Snell Proxy Service
After=network.target
[Service]
ExecStart=/usr/local/bin/snell-server -c /etc/snell/snell-server.conf
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

# ---------- ShadowTLS v3 ----------
echo -e "${BLUE}>>> 安装 ShadowTLS v3...${PLAIN}"
STLS_VER="v0.2.25"

TMP=$(mktemp -d) && cd "$TMP"
curl -sL "https://github.com/ihciah/shadow-tls/releases/download/${STLS_VER}/shadow-tls-${STLS_ARCH}" -o shadow-tls
chmod +x shadow-tls && mv shadow-tls /usr/local/bin/
rm -rf "$TMP"

STLS_PASS=$(head -c 16 /dev/urandom | base64 | tr -d '=+/' | head -c 12)
mkdir -p /etc/shadowtls

cat > /etc/shadowtls/shadowtls.toml << EOF
fastopen = true
strict = true
wildcard_sni = "authed"
server_listen = "0.0.0.0:${STLS_PORT}"
server_tls = "${TLS_SNI}:443"
password = "${STLS_PASS}"
server = "127.0.0.1:${SNELL_PORT}"
EOF

cat > /etc/systemd/system/shadowtls.service << EOF
[Unit]
Description=ShadowTLS V3 Service
After=network.target
[Service]
ExecStart=/usr/local/bin/shadow-tls server --listen 0.0.0.0:${STLS_PORT} --server 127.0.0.1:${SNELL_PORT} --tls ${TLS_SNI}:443 --password ${STLS_PASS} --wildcard-sni authed --strict --fastopen
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

# ---------- 启动服务 ----------
echo -e "${BLUE}>>> 启动服务...${PLAIN}"
systemctl daemon-reload
systemctl enable --now snell shadowtls

# ---------- 防火墙 ----------
iptables -I INPUT -p tcp --dport ${STLS_PORT} -j ACCEPT 2>/dev/null
ufw allow ${STLS_PORT}/tcp > /dev/null 2>&1

# ---------- 输出 ----------
IP=$(curl -s4 ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')

echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}         安装完成！${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""
echo -e "  Snell 端口:   ${YELLOW}${SNELL_PORT}${PLAIN} (内网)"
echo -e "  ShadowTLS:    ${YELLOW}${STLS_PORT}${PLAIN} (对外，带伪装)"
echo -e "  Snell PSK:    ${YELLOW}${SNELL_PSK}${PLAIN}"
echo -e "  ShadowTLS PS: ${YELLOW}${STLS_PASS}${PLAIN}"
echo -e "  伪装 SNI:     ${YELLOW}${TLS_SNI}${PLAIN}"
echo -e "  Snell 版本:   ${YELLOW}v${SNELL_VER}${PLAIN}"
echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}  Surge / 客户端配置${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""
echo -e "  ${YELLOW}Snell 直连:${PLAIN}"
echo -e "  ${GREEN}HK = snell, ${IP}, ${SNELL_PORT}, psk = ${SNELL_PSK}, version = 5, reuse = true, tfo = true${PLAIN}"
echo ""
echo -e "  ${YELLOW}Snell + ShadowTLS:${PLAIN}"
echo -e "  ${GREEN}HK = snell, ${IP}, ${STLS_PORT}, psk = ${SNELL_PSK}, version = 5, reuse = true, tfo = true, shadow-tls-password = ${STLS_PASS}, shadow-tls-sni = ${TLS_SNI}, shadow-tls-version = 3${PLAIN}"
echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}  Shadowrocket / 通用 URI${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""
echo -e "  直连:"
echo -e "  ${YELLOW}snell://${SNELL_PSK}@${IP}:${SNELL_PORT}?version=5&reuse=true&tfo=true${PLAIN}"
echo ""
echo -e "  ShadowTLS:"
echo -e "  ${YELLOW}snell://${SNELL_PSK}@${IP}:${STLS_PORT}?version=5&reuse=true&tfo=true&shadow-tls-password=${STLS_PASS}&shadow-tls-sni=${TLS_SNI}&shadow-tls-version=3${PLAIN}"
echo ""
echo -e "${GREEN}================================================${PLAIN}"
echo -e "${GREEN}  管理命令${PLAIN}"
echo -e "${GREEN}================================================${PLAIN}"
echo ""
echo -e "  状态:       ${BLUE}systemctl status snell shadowtls${PLAIN}"
echo -e "  日志 Snell:  ${BLUE}journalctl -u snell -f${PLAIN}"
echo -e "  日志 STLS:   ${BLUE}journalctl -u shadowtls -f${PLAIN}"
echo -e "  重启:       ${BLUE}systemctl restart snell shadowtls${PLAIN}"
echo ""
