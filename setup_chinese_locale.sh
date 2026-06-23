#!/bin/bash
# ============================================================
#  One-click Chinese Locale Setup Script
#  For Ubuntu / Debian-based systems
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

# ---------- Permission check ----------
if [ "$EUID" -ne 0 ]; then
  err "Please run as root, or prefix with sudo: sudo bash $0"
fi

echo ""
echo "======================================"
echo "   Chinese Locale Setup Script"
echo "======================================"
echo ""

# ---------- 1. Install Chinese language pack ----------
log "Installing language-pack-zh-hans ..."
apt-get update -qq
apt-get install -y language-pack-zh-hans

# ---------- 2. Generate Chinese UTF-8 locales ----------
log "Generating zh_CN.UTF-8 locale ..."
locale-gen zh_CN.UTF-8

log "Generating zh_TW.UTF-8 locale ..."
locale-gen zh_TW.UTF-8

# ---------- 3. Set system default locale ----------
log "Setting system default locale to zh_CN.UTF-8 ..."
update-locale LANG=zh_CN.UTF-8

# ---------- 4. Write to /etc/profile (permanent, all users) ----------
PROFILE_LINE='export LANG="zh_CN.UTF-8"'

if grep -qF "$PROFILE_LINE" /etc/profile; then
  warn "LANG already set in /etc/profile, skipping."
else
  echo "$PROFILE_LINE" >> /etc/profile
  log "LANG written to /etc/profile (applies to all users)"
fi

# ---------- 5. Write to /etc/environment (recommended, login-level) ----------
if grep -q "^LANG=" /etc/environment 2>/dev/null; then
  sed -i 's/^LANG=.*/LANG="zh_CN.UTF-8"/' /etc/environment
  log "LANG updated in /etc/environment"
else
  echo 'LANG="zh_CN.UTF-8"' >> /etc/environment
  log "LANG written to /etc/environment"
fi

# ---------- 6. Apply to current terminal immediately ----------
export LANG="zh_CN.UTF-8"
log "Current terminal LANG is now: $LANG"

# ---------- Done ----------
echo ""
echo "======================================"
log "All done!"
echo "======================================"
echo ""
echo "  Verify with:  locale"
echo "  To apply now: source /etc/profile"
echo ""