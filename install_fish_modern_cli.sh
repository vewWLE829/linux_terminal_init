#!/usr/bin/env bash
set -e

step() {
    echo "👉 $1"
    sleep 1.5
}

# =========================
# 0. system update
# =========================
step "更新系统软件源"
apt update 


# =========================
# 1. install fish 4
# =========================
step "安装 Fish 4.0+"
FISH_NEED_INSTALL=false

if ! command -v fish &>/dev/null; then
    echo "👉 fish 未安装，开始安装"
    FISH_NEED_INSTALL=true
else
    FISH_VERSION=$(fish --version 2>&1 | grep -oP '\d+' | head -1)
    if [ "$FISH_VERSION" -lt 4 ]; then
        echo " fish 版本低于 4.0（当前版本: $(fish --version)），升级安装"
        FISH_NEED_INSTALL=true
    else
        echo "✅ fish（$(fish --version)） 已安装，跳过"
    fi
fi

if [ "$FISH_NEED_INSTALL" = true ]; then
    apt install software-properties-common -y
    add-apt-repository ppa:fish-shell/release-4 -y
    apt update
    apt install fish -y

    step "设置默认 shell 为 fish"
    chsh -s "$(which fish)"
fi


# =========================
# 1.1. fish feature flag, 关闭 OSC 133 提示标记
# =========================
step "设置 Fish prompt 兼容模式, 关闭 OSC 133 提示标记"

fish -c "set -Ua fish_features no-mark-prompt" || true


# =========================
# 2. CLI tools
# =========================
step "安装现代命令行工具"

apt install -y \
    eza \
    bat \
    zoxide \
    ripgrep \
    fd-find


# =========================
# 3. fd compatibility
# =========================
step "配置 fd 命令兼容性"

if [ ! -f /usr/local/bin/fd ]; then
    ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# =========================
# 3.1 bat compatibility
# =========================
step "配置 bat 命令兼容性"

if [ ! -f /usr/local/bin/fd ]; then
    ln -sf "$(which batcat)" /usr/local/bin/bat
fi


# =========================
# 4. fonts
# =========================
step "安装 Nerd Font 字体"

echo "安装fontconfig"
apt install -y fontconfig 

mkdir -p /usr/share/fonts/MesloLGS

wget -q --show-progress -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Regular.ttf

wget -q --show-progress -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold.ttf

wget -q --show-progress -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Italic.ttf

wget -q --show-progress -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold%20Italic.ttf

fc-cache -fv


# =========================
# 5. delta install
# =========================
step "安装 Delta 对比工具"
DELTA_VERSION="0.19.2"
if ! command -v delta &> /dev/null; then
    wget -q -O /tmp/delta.deb \
    https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb

    dpkg -i /tmp/delta.deb || apt -f install -y
else
    echo "✅ delta already installed: $(delta --version)"
fi

# =========================
# 6. 安装tldr
# =========================
TLDR_URL="https://github.com/tealdeer-rs/tealdeer/releases/download/v1.8.1/tealdeer-linux-x86_64-musl"
wget -O tealdeer-linux-x86_64-musl $TLDR_URL
chmod +x tealdeer-linux-x86_64-musl
mv tealdeer-linux-x86_64-musl /usr/local/bin/tldr

# =========================
# 7. fish config
# =========================
step "生成 fish 配置文件"

mkdir -p ~/.config/fish/conf.d

cat > ~/.config/fish/conf.d/aliases.fish << 'EOF'
alias cat='bat'
alias diff='delta --side-by-side'
alias ls='eza --icons'
alias ll='eza -la --icons'
alias la='eza -a --icons'
alias lt='eza --tree --level=2 --icons'
EOF

cat > ~/.config/fish/conf.d/zoxide.fish << 'EOF'
zoxide init fish | source
EOF

echo "✅ 执行完毕"
