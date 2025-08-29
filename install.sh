#!/bin/bash

# Stream Weaver 一键安装脚本
# 该脚本会下载sw.sh并立即启动交互式菜单

# 设置严格模式
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要root权限来安装Stream Weaver"
        error "请使用: sudo $0"
        exit 1
    fi
}

# 检查系统类型
detect_system() {
    if command -v apt-get >/dev/null 2>&1; then
        SYSTEM_TYPE="debian"
    elif command -v dnf >/dev/null 2>&1; then
        SYSTEM_TYPE="fedora"
    elif command -v yum >/dev/null 2>&1; then
        SYSTEM_TYPE="centos"
    else
        error "不支持的操作系统类型"
        exit 1
    fi
}

# 安装依赖
install_dependencies() {
    log "正在安装必要的依赖..."
    
    case "$SYSTEM_TYPE" in
        debian)
            apt-get update
            apt-get install -y curl wget redsocks iptables ipset
            ;;
        fedora)
            dnf install -y curl wget redsocks iptables ipset
            ;;
        centos)
            yum install -y curl wget redsocks iptables ipset
            ;;
    esac
    
    # 检查安装是否成功
    for cmd in curl wget redsocks iptables ipset; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "依赖 $cmd 安装失败"
            exit 1
        fi
    done
    
    success "依赖安装完成"
}

# 下载sw.sh脚本
download_script() {
    log "正在下载Stream Weaver脚本..."
    
    # 尝试从GitHub下载
    if curl -fsSL "https://raw.githubusercontent.com/MisonL/Stream-Weaver/master/sw.sh" -o /tmp/sw.sh; then
        success "脚本下载成功"
    else
        error "脚本下载失败，请检查网络连接"
        exit 1
    fi
    
    # 验证脚本
    if ! bash -n /tmp/sw.sh; then
        error "下载的脚本存在语法错误"
        exit 1
    fi
    
    # 移动脚本到系统目录
    mv /tmp/sw.sh /usr/local/bin/sw
    chmod +x /usr/local/bin/sw
    
    success "脚本已安装到 /usr/local/bin/sw"
}

# 启动交互式菜单
start_interactive_menu() {
    log "启动交互式菜单..."
    exec /usr/local/bin/sw menu
}

# 主函数
main() {
    # 检查是否有no-menu参数
    local no_menu=false
    if [[ "${1:-}" == "--no-menu" || "${1:-}" == "no-menu" ]]; then
        no_menu=true
    fi
    
    log "开始安装Stream Weaver..."
    
    # 检查权限
    check_root
    
    # 检测系统类型
    detect_system
    
    # 安装依赖
    install_dependencies
    
    # 下载脚本
    download_script
    
    # 根据参数决定是否启动交互式菜单
    if [ "$no_menu" = true ]; then
        success "安装完成！使用 'sw menu' 启动交互式菜单"
    else
        # 启动交互式菜单
        start_interactive_menu
    fi
}

# 执行主函数
main "$@"