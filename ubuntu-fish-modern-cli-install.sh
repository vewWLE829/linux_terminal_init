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

apt install software-properties-common -y

add-apt-repository ppa:fish-shell/release-4 -y
apt update
apt install fish -y

step "设置默认 shell 为 fish"
chsh -s "$(which fish)"


# =========================
# 2. fisher
# =========================
step "安装 Fisher 插件管理器"
if ! command -v fisher >/dev/null 2>&1; then
    echo "👉 fisher 未安装，开始安装"
    fish -c '
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
        fisher install jorgebucaran/fisher
    '
else
    echo "👉 fisher 已存在，跳过"
fi


# =========================
# 3. CLI tools
# =========================
step "安装现代命令行工具"

apt install -y \
    fontconfig \
    eza \
    bat \
    zoxide \
    ripgrep \
    fd-find


# =========================
# 4. fd compatibility
# =========================
step "配置 fd 命令兼容性"

if [ ! -f /usr/local/bin/fd ]; then
    ln -sf "$(which fdfind)" /usr/local/bin/fd
fi


# =========================
# 5. fonts
# =========================
step "安装 Nerd Font 字体"

mkdir -p /usr/share/fonts/MesloLGS

wget -q -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Regular.ttf

wget -q -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold.ttf

wget -q -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Italic.ttf

wget -q -P /usr/share/fonts/MesloLGS \
https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold%20Italic.ttf

fc-cache -fv


# =========================
# 6. delta install
# =========================
step "安装 Delta diff 工具"
DELTA_VERSION="0.19.2"
if ! command -v delta &> /dev/null; then
    wget -q -O /tmp/delta.deb \
    https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb

    dpkg -i /tmp/delta.deb || apt -f install -y
else
    echo "delta already installed: $(delta --version)"
fi

# =========================
# 7. fish config
# =========================
step "生成 fish 配置文件"

mkdir -p ~/.config/fish

cat > ~/.config/fish/config.fish << 'EOF'
if status is-interactive
    
    alias cat='bat'
    
    alias diff='delta --side-by-side'

    # eza
    alias ls='eza --icons'
    alias ll='eza -la --icons'
    alias la='eza -a --icons'
    alias lt='eza --tree --level=2 --icons'

    # zoxide
    zoxide init fish | source

end
EOF


# =========================
# 8. fish feature flag
# =========================
step "设置 Fish prompt 兼容模式"

fish -c "set -Ua fish_features no-mark-prompt" || true

echo "执行完毕"
