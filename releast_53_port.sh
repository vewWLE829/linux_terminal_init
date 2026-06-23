#!/bin/bash

# ============================================================
#  释放 53 端口（解除 systemd-resolved 占用）
#  适用场景：Dnsmasq / Netflix DNS 解锁等需要监听 53 端口的服务
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── 权限检查 ──────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    error "请使用 root 权限运行此脚本：sudo bash $0"
fi

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}     释放 53 端口 / 禁用 DNS Stub 监听器   ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# ── 步骤 1：检查 53 端口占用情况 ─────────────────────────
info "步骤 1/4：检查 53 端口占用情况..."
if command -v netstat &>/dev/null; then
    PORT_INFO=$(netstat -tlunp 2>/dev/null | grep ':53 ' || true)
elif command -v ss &>/dev/null; then
    PORT_INFO=$(ss -tlunp 2>/dev/null | grep ':53 ' || true)
else
    warn "未找到 netstat 或 ss 命令，跳过端口检查。"
    PORT_INFO=""
fi

if [[ -z "$PORT_INFO" ]]; then
    warn "53 端口当前未被占用，脚本仍将继续完成配置。"
else
    echo -e "${YELLOW}当前 53 端口占用情况：${NC}"
    echo "$PORT_INFO"
    echo ""
fi

# ── 步骤 2：停止 systemd-resolved ────────────────────────
info "步骤 2/4：停止 systemd-resolved 服务..."
if systemctl is-active --quiet systemd-resolved; then
    systemctl stop systemd-resolved
    success "systemd-resolved 已停止。"
else
    warn "systemd-resolved 当前未在运行，跳过停止操作。"
fi

# ── 步骤 3：修改 resolved.conf ───────────────────────────
CONF="/etc/systemd/resolved.conf"
info "步骤 3/4：修改 ${CONF}..."

if [[ ! -f "$CONF" ]]; then
    error "配置文件 ${CONF} 不存在，请确认系统已安装 systemd-resolved。"
fi

# 备份原始配置
BACKUP="${CONF}.bak.$(date +%Y%m%d%H%M%S)"
cp "$CONF" "$BACKUP"
success "原始配置已备份至：${BACKUP}"

# 写入新配置（保留原有注释块，覆盖关键字段）
cat > "$CONF" << 'EOF'
[Resolve]
#DNS=
#FallbackDNS=
#Domains=
#LLMNR=no
#MulticastDNS=no
#DNSSEC=no
#Cache=yes
DNSStubListener=no
EOF

success "配置文件已更新： DNSStubListener=no"

# ── 步骤 4：更新 resolv.conf 软链接 ──────────────────────
info "步骤 4/4：将 /etc/resolv.conf 指向 systemd-resolved 的上游解析配置..."
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
success "/etc/resolv.conf -> /run/systemd/resolve/resolv.conf"

# ── 重启服务并设置开机禁用 Stub ───────────────────────────
info "重启 systemd-resolved（仅用于转发，不再占用 53 端口）..."
systemctl restart systemd-resolved
systemctl enable systemd-resolved &>/dev/null || true
success "systemd-resolved 已重启（Stub 监听器已关闭）。"

# ── 最终验证 ──────────────────────────────────────────────
echo ""
info "验证 53 端口是否已释放..."
sleep 1
if command -v netstat &>/dev/null; then
    REMAINING=$(netstat -tlunp 2>/dev/null | grep ':53 ' || true)
elif command -v ss &>/dev/null; then
    REMAINING=$(ss -tlunp 2>/dev/null | grep ':53 ' || true)
else
    REMAINING=""
fi

if [[ -z "$REMAINING" ]]; then
    success "53 端口已成功释放，现在可以启动 Dnsmasq 等服务了！"
else
    warn "53 端口仍有进程占用（可能是其他服务），请手动检查："
    echo "$REMAINING"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}            ✅ 脚本执行完毕                ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "  备份文件：${YELLOW}${BACKUP}${NC}"
echo -e "  如需恢复：${YELLOW}cp ${BACKUP} ${CONF} && systemctl restart systemd-resolved${NC}"
echo ""