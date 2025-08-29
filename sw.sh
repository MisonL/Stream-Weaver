
#!/bin/bash

# Stream Weaver (流织者) - Linux系统流量转发到远程Clash Verge代理服务器工具
# 作者: Mison
# 版本: 1.0
# 描述: 将本地系统流量通过redsocks转发到远程Clash Verge代理服务器，像织布一样巧妙地编织和引导网络流

# 检查是否通过管道运行（没有脚本文件名参数）
if [[ "${BASH_SOURCE[0]}" == "" || "${BASH_SOURCE[0]}" == "bash" ]]; then
    # 管道运行模式 - 保存脚本并执行一键安装
    
    # 设置严格模式
    if [[ "${1:-}" == "test" ]]; then
        set -uo pipefail  # 禁用-e选项，允许命令失败
    else
        set -euo pipefail  # 严格模式
    fi
    
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
        # 在管道模式下，我们使用sudo来执行需要root权限的操作，所以不需要这个检查
        # 只在非管道模式下检查
        # 管道模式下BASH_SOURCE[0]通常是空字符串或"bash"
        if [[ "${BASH_SOURCE[0]}" != "" && "${BASH_SOURCE[0]}" != "bash" ]]; then
            if [[ $EUID -eq 0 ]]; then
                error "此脚本不应以root权限运行"
                exit 1
            fi
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
                sudo apt-get update
                sudo apt-get install -y curl wget redsocks iptables ipset
                ;;
            fedora)
                sudo dnf install -y curl wget redsocks iptables ipset
                ;;
            centos)
                sudo yum install -y curl wget redsocks iptables ipset
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
    
    # 保存脚本到系统目录
    save_script() {
        log "正在保存Stream Weaver脚本..."
        
        # 创建临时文件
        local temp_script=$(mktemp)
        
        # 添加正确的 shebang 行，确保脚本使用 bash 执行
        echo "#!/bin/bash" > "$temp_script"
        
        # 从标准输入读取脚本内容并追加到临时文件
        cat >> "$temp_script"
        
        # 检查保存是否成功
        if [ ! -f "$temp_script" ]; then
            error "脚本保存到临时文件失败"
            exit 1
        fi
        
        # 移动到系统目录
        sudo mkdir -p /usr/local/bin
        sudo mv "$temp_script" /usr/local/bin/sw
        sudo chmod +x /usr/local/bin/sw
        
        # 检查最终保存是否成功
        if [ ! -f /usr/local/bin/sw ]; then
            error "脚本保存到系统目录失败"
            exit 1
        fi
        
        success "脚本已安装到 /usr/local/bin/sw"
    }
    
    # 安装为系统服务
    install_service() {
        log "正在安装为系统服务..."
        sudo /usr/local/bin/sw install-service
        success "系统服务安装完成"
    }
    
    # 启动交互式菜单
    start_interactive_menu() {
        log "启动交互式菜单..."
        # 确保在交互式终端中运行菜单
        exec sudo /usr/local/bin/sw menu </dev/tty >/dev/tty 2>&1
    }
    
    # 管道运行主函数
    main() {
        # 检查是否有数据可以通过管道读取
        if [ ! -t 0 ]; then
            # 检查参数决定行为
            local install_service_flag=false
            local no_menu=false
            
            # 解析参数
            while [[ $# -gt 0 ]]; do
                case $1 in
                    install-service)
                        install_service_flag=true
                        shift
                        ;;
                    no-menu|--no-menu)
                        no_menu=true
                        shift
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            
            # 保存脚本
            save_script
            
            # 在管道模式下，我们使用sudo来执行需要root权限的操作，所以不需要这个检查
            # 检查权限（仅在非管道模式下）
            # check_root
            
            # 检测系统类型
            detect_system
            
            # 安装依赖
            install_dependencies
            
            # 根据参数决定行为
            if [ "$install_service_flag" = true ]; then
                install_service
                if [ "$no_menu" = false ]; then
                    start_interactive_menu
                else
                    success "安装完成！使用 'sudo sw menu' 启动交互式菜单"
                fi
            elif [ "$no_menu" = false ]; then
                # 不带参数时直接进入交互式菜单
                start_interactive_menu
            else
                success "安装完成！使用 'sudo sw menu' 启动交互式菜单"
            fi
        else
            error "脚本未通过管道运行，无法执行一键安装"
            exit 1
        fi
    }
    
    # 执行主函数
    main "$@"
    
    # 退出以避免执行脚本的其余部分
    exit 0
fi

# 对于测试功能，我们暂时禁用严格模式
if [[ "${1:-}" == "test" ]]; then
    set -uo pipefail  # 禁用-e选项，允许命令失败
else
    set -euo pipefail  # 严格模式
fi

# 全局变量
export DEBIAN_FRONTEND=noninteractive
LAST_RULES="/etc/iptables/backup/rules.v4.last"
TEMP_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_CHECK_PASSED=false
PROXY_STARTED=false

# 配置文件路径
CONFIG_FILE="/etc/clash_forward/config"
CUSTOM_EXEMPTION_FILE="/etc/clash_forward/exemptions"

# 系统类型检测
SYSTEM_TYPE=""
USE_SYSTEMD=true
detect_system() {
    if command -v apt-get &>/dev/null; then
        SYSTEM_TYPE="debian"
    elif command -v yum &>/dev/null; then
        SYSTEM_TYPE="redhat"
    elif command -v dnf &>/dev/null; then
        SYSTEM_TYPE="redhat"
    else
        error "不支持的操作系统类型"
        exit 1
    fi
    
    # 检查systemd是否可用
    if ! command -v systemctl &>/dev/null; then
        USE_SYSTEMD=false
        log "警告: systemd不可用，将使用传统服务管理方式"
    fi
    
    log "检测到系统类型: $SYSTEM_TYPE, systemd支持: $USE_SYSTEMD"
}

# 默认配置 - 远程Clash Verge代理服务器地址
DEFAULT_PROXY_IP="192.168.1.100"  # 远程Clash Verge服务器IP
DEFAULT_PROXY_PORT="7890"         # Clash Verge默认SOCKS5端口
LOCAL_REDIR_PORT="12345"          # 本地redsocks监听端口

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 错误日志
error() {
    echo -e "\e[31m[错误] $1\e[0m" >&2
}

# 重置系统到默认状态
reset_system() {
    local reset_exemptions="${1:-yes}"  # 默认重置豁免规则
    local uninstall_service="${2:-no}"   # 默认不卸载服务
    
    log "开始重置系统到默认状态..."
    
    # 停止redsocks服务
    log "停止 redsocks 服务..."
    systemctl stop redsocks.service 2>/dev/null || true
    systemctl disable redsocks.service 2>/dev/null || true
    
    # 如果用户选择卸载服务，则卸载Stream Weaver服务
    if [ "$uninstall_service" = "yes" ]; then
        log "卸载 Stream Weaver 服务..."
        # 停止服务
        systemctl stop stream-weaver.service 2>/dev/null || true
        
        # 禁用服务
        systemctl disable stream-weaver.service 2>/dev/null || true
        
        # 删除服务文件
        local service_file="/etc/systemd/system/stream-weaver.service"
        if [ -f "$service_file" ]; then
            rm -f "$service_file"
            log "已删除服务文件: $service_file"
        fi
        
        # 删除系统级命令链接
        local system_bin="/usr/local/bin/sw"
        if [ -L "$system_bin" ] || [ -f "$system_bin" ]; then
            rm -f "$system_bin"
            log "已删除系统级命令链接: $system_bin"
        fi
    fi
    
    # 清理iptables规则
    log "清理 iptables 规则..."
    cleanup_iptables
    
    # 禁用IP转发
    log "禁用 IP 转发..."
    disable_ip_forward
    
    # 删除配置文件和目录
    log "删除配置文件..."
    rm -f "/etc/redsocks.conf"
    rm -f "/etc/systemd/system/redsocks.service"
    
    # 根据参数决定是否删除豁免规则文件
    if [ "$reset_exemptions" = "yes" ]; then
        log "删除所有配置文件和目录..."
        rm -rf "/etc/clash_forward"
    else
        log "保留豁免规则文件..."
        # 只删除代理配置，保留豁免规则
        rm -f "/etc/clash_forward/config"
    fi
    
    # 删除iptables备份文件
    log "删除 iptables 备份文件..."
    rm -rf "/etc/iptables/backup"
    
    # 重新加载systemd
    systemctl daemon-reload 2>/dev/null || true
    
    log "系统重置完成"
    if [ "$reset_exemptions" = "yes" ]; then
        echo "✅ 系统已重置到默认状态（包括豁免规则）"
    else
        echo "✅ 系统已重置到默认状态（保留豁免规则）"
    fi
    
    if [ "$uninstall_service" = "yes" ]; then
        echo "✅ Stream Weaver服务已卸载"
        echo "✅ 系统级命令 'sw' 已移除"
    fi
}

# 基础初始化函数（不需要root权限）
basic_init() {
    log "开始基础初始化..."
    
    # 创建临时目录
    if TEMP_DIR=$(mktemp -d 2>/dev/null); then
        chmod 700 "$TEMP_DIR"
        log "临时目录创建成功: $TEMP_DIR"
    else
        TEMP_DIR="/tmp/clash_forward_$$"
        mkdir -p "$TEMP_DIR" 2>/dev/null || {
            error "无法创建临时目录"
            exit 1
        }
        chmod 700 "$TEMP_DIR"
    fi
    
    log "基础初始化完成"
}

# 清理函数
cleanup() {
    local exit_code=$?
    log "开始清理操作... (退出码: $exit_code)"
    
    # 只有在root权限检查通过且代理已启动的情况下才进行系统级清理
    # 并且只有在真正出错时才显示错误信息（排除正常的命令执行）
    if [ $exit_code -ne 0 ] && [ "$ROOT_CHECK_PASSED" = true ] && [ "$PROXY_STARTED" = true ]; then
        error "脚本执行失败（错误码: $exit_code）"
        
        # 只有在代理启动过程中失败才需要恢复规则
        if [ "$PROXY_STARTED" = true ]; then
            if [ -f "$LAST_RULES" ]; then
                log "正在恢复之前的 iptables 规则..."
                if iptables-restore < "$LAST_RULES" 2>/dev/null; then
                    log "规则恢复成功"
                else
                    error "规则恢复失败"
                fi
            else
                log "没有找到备份规则文件"
            fi

            log "正在停止 redsocks 服务..."
            systemctl stop redsocks.service 2>/dev/null || true
            
            # 确保清理所有转发规则
            iptables -t nat -F OUTPUT 2>/dev/null || true
        fi
    elif [ $exit_code -ne 0 ] && [ "$ROOT_CHECK_PASSED" = true ] && [ "$PROXY_STARTED" = false ]; then
        # 对于非代理启动的命令，只在真正出错时记录日志
        log "命令执行完成，退出码: $exit_code"
    elif [ $exit_code -ne 0 ] && [ "$ROOT_CHECK_PASSED" = false ]; then
        # 权限检查失败时的简化清理
        log "权限检查失败，跳过系统级清理操作"
    fi

    # 清理临时文件（这个操作不需要root权限）
    if [ -d "$TEMP_DIR" ]; then
        log "清理临时目录: $TEMP_DIR"
        rm -rf "$TEMP_DIR" 2>/dev/null || error "清理临时目录失败"
    fi

    # 重置信号处理
    trap - EXIT ERR INT TERM

    # 写入最后的日志
    log "清理完成"
}

# 错误处理函数
error_handler() {
    local line_no=$1
    local command=$2
    local error_code=$3
    echo "错误发生在第 $line_no 行"
    echo "命令: $command"
    echo "错误码: $error_code"
}

# 设置陷阱
trap 'error_handler ${LINENO} "${BASH_COMMAND}" $?' ERR
trap cleanup EXIT INT TERM

# 基础初始化（不需要root权限）
basic_init

# 权限检查函数
check_root_permission() {
    if [[ $EUID -ne 0 ]]; then
        echo ""
        echo "❌ 权限不足"
        echo ""
        echo "此脚本需要root权限来执行以下操作："
        echo "  • 修改 iptables 规则"
        echo "  • 管理 systemd 服务"
        echo "  • 修改系统网络配置"
        echo "  • 安装必要的软件包"
        echo ""
        echo "请使用以下命令重新运行："
        echo "  sudo $0 $*"
        echo ""
        exit 1
    fi
    ROOT_CHECK_PASSED=true
    log "root权限检查通过"
}

# 系统检查函数（需要root权限）
check_system() {
    log "开始系统检查..."
    
    # 检测系统类型
    detect_system
    
    # 确保所需目录存在
    for dir in "/etc/iptables/backup" "/etc/clash_forward"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            error "无法创建目录: $dir"
            exit 1
        fi
    done
    log "系统目录检查/创建成功"

    # 检查必要的系统命令
    local required_cmds=(iptables curl systemctl lsof grep sed)
    local missing_cmds=()
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_cmds+=("$cmd")
        fi
    done
    
    if [ ${#missing_cmds[@]} -gt 0 ]; then
        error "缺少必要的命令: ${missing_cmds[*]}"
        exit 1
    fi
    
    log "系统命令检查完成"

    # 检查并安装必要的软件包（仅在缺失时安装）
    local packages_debian=(iptables iptables-persistent redsocks curl lsof netcat-openbsd)
    local packages_redhat=(iptables iptables-services redsocks curl lsof nc)
    local missing_packages=()

    # 根据系统类型选择包列表
    local packages=()
    if [ "$SYSTEM_TYPE" = "debian" ]; then
        packages=("${packages_debian[@]}")
    else
        packages=("${packages_redhat[@]}")
    fi

    for pkg in "${packages[@]}"; do
        case $pkg in
            iptables|curl|lsof)
                if ! command -v $pkg &>/dev/null; then
                    log "检查软件包: $pkg 未安装，将添加到安装列表"
                    missing_packages+=($pkg)
                else
                    log "检查软件包: $pkg 已安装"
                fi
                ;;
            iptables-persistent|iptables-services)
                if [ "$SYSTEM_TYPE" = "debian" ]; then
                    # 改进iptables-persistent的检测，多种方式验证是否已安装
                    if dpkg -l iptables-persistent &>/dev/null || [ -f /usr/share/doc/iptables-persistent ] || apt list --installed 2>/dev/null | grep -q "iptables-persistent"; then
                        log "检查软件包: iptables-persistent 已安装"
                    else
                        log "检查软件包: iptables-persistent 未安装，将添加到安装列表"
                        missing_packages+=($pkg)
                    fi
                else
                    if rpm -q iptables-services &>/dev/null || [ -f /etc/sysconfig/iptables-config ]; then
                        log "检查软件包: iptables-services 已安装"
                    else
                        log "检查软件包: iptables-services 未安装，将添加到安装列表"
                        missing_packages+=($pkg)
                    fi
                fi
                ;;
            redsocks)
                if ! command -v $pkg &>/dev/null && ! dpkg -l 2>/dev/null | grep -q "redsocks" && ! rpm -q redsocks &>/dev/null; then
                    log "检查软件包: redsocks 未安装，将添加到安装列表"
                    missing_packages+=($pkg)
                else
                    log "检查软件包: redsocks 已安装"
                fi
                ;;
            netcat-openbsd|nc)
                if ! command -v nc &>/dev/null; then
                    log "检查软件包: nc 未安装，将添加到安装列表"
                    missing_packages+=($pkg)
                else
                    log "检查软件包: nc 已安装"
                fi
                ;;
        esac
    done

    # 只有在确实需要安装包时才安装
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log "正在安装缺失的软件包: ${missing_packages[*]}"
        if [ "$SYSTEM_TYPE" = "debian" ]; then
            apt-get update >/dev/null 2>&1 || log "apt-get update完成"
            apt-get install -y "${missing_packages[@]}" || {
                error "软件包安装失败"
                exit 1
            }
        else
            if command -v dnf &>/dev/null; then
                dnf install -y "${missing_packages[@]}" || {
                    error "软件包安装失败"
                    exit 1
                }
            else
                yum install -y "${missing_packages[@]}" || {
                    error "软件包安装失败"
                    exit 1
                }
            fi
        fi
    else
        log "所有必需的软件包已安装，无需重复安装"
    fi
    
    # 检查ip6tables是否可用
    if ! command -v ip6tables &>/dev/null; then
        log "警告: ip6tables 不可用，IPv6支持将受限"
    else
        log "检测到 ip6tables，IPv6支持已启用"
    fi

    # 确认redsocks已正确安装
    if ! command -v redsocks &>/dev/null && ! [ -f "/usr/sbin/redsocks" ] && ! [ -f "/usr/bin/redsocks" ]; then
        error "redsocks安装失败或未找到可执行文件"
        log "尝试手动安装: sudo $([ "$SYSTEM_TYPE" = "debian" ] && echo "apt-get" || echo "yum") install -y redsocks"
        exit 1
    fi
    
    # 创建redsocks systemd服务文件
    create_redsocks_service
    
    log "系统检查和软件包安装完成"
}

# 启用IP转发（IPv4和IPv6）
enable_ip_forward() {
    # 启用IPv4转发
    sysctl -w net.ipv4.ip_forward=1 >/dev/null
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    
    # 启用IPv6转发
    sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null
    if ! grep -q "net.ipv6.conf.all.forwarding=1" /etc/sysctl.conf; then
        echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    fi
    
    # 应用设置
    sysctl -p >/dev/null
    
    log "IP转发(IPv4/IPv6)已启用"
}

# 禁用IP转发（IPv4和IPv6）
disable_ip_forward() {
    # 禁用IPv4转发
    sysctl -w net.ipv4.ip_forward=0 >/dev/null
    sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
    
    # 禁用IPv6转发
    sysctl -w net.ipv6.conf.all.forwarding=0 >/dev/null
    sed -i '/net.ipv6.conf.all.forwarding=1/d' /etc/sysctl.conf
    
    # 应用设置
    sysctl -p >/dev/null
    
    log "IP转发(IPv4/IPv6)已禁用"
}

# 读取配置
load_config() {
    # 首先检查配置文件是否存在
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        log "从配置文件读取代理信息: $CONFIG_FILE"
    else
        log "未找到配置文件，将使用默认值"
    fi
    
    # 设置默认值
    PROXY_IP="${PROXY_IP:-$DEFAULT_PROXY_IP}"
    PROXY_PORT="${PROXY_PORT:-$DEFAULT_PROXY_PORT}"
    
    log "使用远程Clash Verge代理配置: $PROXY_IP:$PROXY_PORT"
}

# 配置redsocks（支持IPv4和IPv6）
setup_redsocks() {
    log "配置 redsocks（IPv4和IPv6支持）..."
    
    # 创建redsocks配置
    cat > /etc/redsocks.conf <<EOF
base {
    log_debug = off;
    log_info = on;
    log = "stderr";
    daemon = off;
    redirector = iptables;
}

redsocks {
    local_ip = 127.0.0.1;
    local_port = $LOCAL_REDIR_PORT;
    ip = $PROXY_IP;
    port = $PROXY_PORT;
    type = socks5;
}
EOF

    # 注意：redsocks本身主要支持IPv4，IPv6支持通过iptables规则实现
    # 我们不在redsocks配置中添加IPv6块，而是通过ip6tables规则处理IPv6流量
    if command -v ip6tables >/dev/null 2>&1 && [ -f /proc/net/if_inet6 ]; then
        log "IPv6支持通过ip6tables规则实现"
    else
        log "IPv6不可用，仅使用IPv4"
    fi

    log "redsocks 配置完成（IPv4/IPv6支持）"
}

# 备份当前iptables规则（IPv4和IPv6）
backup_iptables() {
    log "备份当前 iptables 规则..."
    local backup_file_v4="/etc/iptables/backup/rules.v4.$(date +%Y%m%d_%H%M%S)"
    local backup_file_v6="/etc/iptables/backup/rules.v6.$(date +%Y%m%d_%H%M%S)"
    
    # 备份IPv4规则
    if iptables-save > "$backup_file_v4" 2>/dev/null; then
        # 创建最新备份的符号链接
        ln -sf "$backup_file_v4" "$LAST_RULES"
        log "IPv4 iptables 规则备份成功: $backup_file_v4"
    else
        error "IPv4 iptables 规则备份失败"
        return 1
    fi
    
    # 备份IPv6规则（如果ip6tables可用）
    if command -v ip6tables >/dev/null 2>&1; then
        if ip6tables-save > "$backup_file_v6" 2>/dev/null; then
            # 创建IPv6备份的符号链接
            ln -sf "$backup_file_v6" "${LAST_RULES/v4/v6}"
            log "IPv6 ip6tables 规则备份成功: $backup_file_v6"
        else
            log "IPv6 ip6tables 规则备份失败（可能没有IPv6规则）"
        fi
    else
        log "ip6tables 不可用，跳过IPv6规则备份"
    fi
}

# 设置iptables规则以重定向流量到redsocks（IPv4和IPv6）
setup_iptables() {
    log "设置 iptables 规则（IPv4和IPv6）..."
    
    # 备份当前规则
    backup_iptables || return 1
    
    # === IPv4 规则设置 ===
    log "配置IPv4 iptables规则..."
    
    # 创建新的链
    iptables -t nat -N CLASH_FORWARD 2>/dev/null || true
    
    # 跳过本地和私有网络
    iptables -t nat -A CLASH_FORWARD -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH_FORWARD -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH_FORWARD -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH_FORWARD -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A CLASH_FORWARD -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A CLASH_FORWARD -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A CLASH_FORWARD -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A CLASH_FORWARD -d 240.0.0.0/4 -j RETURN
    
    # 跳过远程Clash Verge服务器地址，避免循环
    iptables -t nat -A CLASH_FORWARD -d $PROXY_IP -j RETURN
    
    # 添加自定义豁免规则
    if [ -f "$CUSTOM_EXEMPTION_FILE" ]; then
        log "添加自定义豁免规则..."
        while IFS= read -r line || [[ -n "$line" ]]; do
            # 跳过注释和空行
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            
            # 解析豁免规则
            local exemption_type=$(echo "$line" | cut -d'=' -f1)
            local exemption_value=$(echo "$line" | cut -d'=' -f2)
            
            case "$exemption_type" in
                ip)
                    iptables -t nat -A CLASH_FORWARD -d "$exemption_value" -j RETURN
                    log "添加IP豁免规则: $exemption_value"
                    ;;
                port)
                    iptables -t nat -A CLASH_FORWARD -p tcp --dport "$exemption_value" -j RETURN
                    iptables -t nat -A CLASH_FORWARD -p udp --dport "$exemption_value" -j RETURN
                    log "添加端口豁免规则: $exemption_value"
                    ;;
                domain)
                    # 域名豁免需要解析为IP地址
                    local domain_ips=$(getent ahosts "$exemption_value" 2>/dev/null | awk '{print $1}' | sort -u)
                    if [ -n "$domain_ips" ]; then
                        while IFS= read -r ip; do
                            [[ -z "$ip" ]] && continue
                            iptables -t nat -A CLASH_FORWARD -d "$ip" -j RETURN
                            log "添加域名豁免规则: $exemption_value -> $ip"
                        done <<< "$domain_ips"
                    else
                        log "警告: 无法解析域名 $exemption_value"
                    fi
                    ;;
                *)
                    log "警告: 未知的豁免类型: $exemption_type"
                    ;;
            esac
        done < "$CUSTOM_EXEMPTION_FILE"
    fi
    
    # 重定向TCP流量到redsocks
    iptables -t nat -A CLASH_FORWARD -p tcp -j REDIRECT --to-ports $LOCAL_REDIR_PORT
    
    # 应用规则到OUTPUT链
    iptables -t nat -A OUTPUT -p tcp -j CLASH_FORWARD
    
    log "IPv4 iptables 规则设置完成"
    
    # === IPv6 规则设置 ===
    if command -v ip6tables >/dev/null 2>&1; then
        log "配置IPv6 ip6tables规则..."
        
        # 创建新的链
        ip6tables -t nat -N CLASH_FORWARD6 2>/dev/null || true
        
        # 跳过本地和私有网络（IPv6）
        ip6tables -t nat -A CLASH_FORWARD6 -d ::1/128 -j RETURN          # 回环地址
        ip6tables -t nat -A CLASH_FORWARD6 -d ::/128 -j RETURN           # 未指定地址
        ip6tables -t nat -A CLASH_FORWARD6 -d fe80::/10 -j RETURN        # 链路本地地址
        ip6tables -t nat -A CLASH_FORWARD6 -d fc00::/7 -j RETURN         # 唯一本地地址
        ip6tables -t nat -A CLASH_FORWARD6 -d ff00::/8 -j RETURN         # 多播地址
        
        # 跳过远程Clash Verge服务器地址，避免循环
        # 注意：这里假设远程服务器也有IPv6地址
        # ip6tables -t nat -A CLASH_FORWARD6 -d <IPv6地址> -j RETURN
        
        # 添加自定义豁免规则（IPv6）
        if [ -f "$CUSTOM_EXEMPTION_FILE" ]; then
            while IFS= read -r line || [[ -n "$line" ]]; do
                # 跳过注释和空行
                [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
                
                # 解析豁免规则
                local exemption_type=$(echo "$line" | cut -d'=' -f1)
                local exemption_value=$(echo "$line" | cut -d'=' -f2)
                
                case "$exemption_type" in
                    ip)
                        # 检查是否为IPv6地址
                        if [[ "$exemption_value" =~ : ]]; then
                            ip6tables -t nat -A CLASH_FORWARD6 -d "$exemption_value" -j RETURN
                            log "添加IPv6豁免规则: $exemption_value"
                        fi
                        ;;
                    port)
                        ip6tables -t nat -A CLASH_FORWARD6 -p tcp --dport "$exemption_value" -j RETURN
                        ip6tables -t nat -A CLASH_FORWARD6 -p udp --dport "$exemption_value" -j RETURN
                        log "添加IPv6端口豁免规则: $exemption_value"
                        ;;
                    domain)
                        # 域名豁免需要解析为IPv6地址
                        local domain_ips=$(getent ahostsv6 "$exemption_value" 2>/dev/null | awk '{print $1}' | sort -u)
                        if [ -n "$domain_ips" ]; then
                            while IFS= read -r ip; do
                                [[ -z "$ip" ]] && continue
                                ip6tables -t nat -A CLASH_FORWARD6 -d "$ip" -j RETURN
                                log "添加域名IPv6豁免规则: $exemption_value -> $ip"
                            done <<< "$domain_ips"
                        fi
                        ;;
                esac
            done < "$CUSTOM_EXEMPTION_FILE"
        fi
        
        # 重定向TCP流量到redsocks（使用相同端口，redsocks会处理）
        ip6tables -t nat -A CLASH_FORWARD6 -p tcp -j REDIRECT --to-ports $LOCAL_REDIR_PORT
        
        # 应用规则到OUTPUT链
        ip6tables -t nat -A OUTPUT -p tcp -j CLASH_FORWARD6
        
        log "IPv6 ip6tables 规则设置完成"
    else
        log "ip6tables 不可用，跳过IPv6规则设置"
    fi
    
    log "iptables 规则设置完成（IPv4/IPv6）"
}

# 清理iptables规则（IPv4和IPv6）
cleanup_iptables() {
    log "清理 iptables 规则（IPv4和IPv6）..."
    
    # === 清理IPv4规则 ===
    log "清理IPv4 iptables规则..."
    
    # 删除OUTPUT链中的CLASH_FORWARD规则
    iptables -t nat -D OUTPUT -p tcp -j CLASH_FORWARD 2>/dev/null || true
    
    # 清空并删除CLASH_FORWARD链
    iptables -t nat -F CLASH_FORWARD 2>/dev/null || true
    iptables -t nat -X CLASH_FORWARD 2>/dev/null || true
    
    log "IPv4 iptables 规则清理完成"
    
    # === 清理IPv6规则 ===
    if command -v ip6tables >/dev/null 2>&1; then
        log "清理IPv6 ip6tables规则..."
        
        # 删除OUTPUT链中的CLASH_FORWARD6规则
        ip6tables -t nat -D OUTPUT -p tcp -j CLASH_FORWARD6 2>/dev/null || true
        
        # 清空并删除CLASH_FORWARD6链
        ip6tables -t nat -F CLASH_FORWARD6 2>/dev/null || true
        ip6tables -t nat -X CLASH_FORWARD6 2>/dev/null || true
        
        log "IPv6 ip6tables 规则清理完成"
    else
        log "ip6tables 不可用，跳过IPv6规则清理"
    fi
    
    log "iptables 规则清理完成（IPv4/IPv6）"
}

# 检查是否存在配置文件，如果不存在则提示用户先进行配置
check_config_exists() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ 未找到代理配置文件"
        echo "请先配置远程代理服务器信息:"
        echo "sudo $0 config <远程服务器IP> <端口>"
        echo "例如: sudo $0 config 192.168.1.100 7890"
        echo "或使用交互式菜单中的配置选项"
        return 1
    fi
    return 0
}

# 启动代理
start_proxy() {
    log "启动流量转发到远程Clash Verge代理..."
    PROXY_STARTED=true  # 标记代理启动过程开始
    
    # 首先检查是否存在配置文件
    if ! check_config_exists; then
        return 1
    fi
    
    # 执行系统检查
    check_system
    
    # 加载配置
    load_config
    
    # 显示正在使用的配置信息
    echo "ℹ️ 正在使用配置: $PROXY_IP:$PROXY_PORT"
    if [ -f "$CONFIG_FILE" ] && [ -n "$LAST_CONFIG_TIME" ]; then
        echo "   配置时间: $LAST_CONFIG_TIME"
    fi
    
    # 检查远程代理是否可用
    if ! check_proxy_connectivity; then
        error "远程Clash Verge代理服务器不可达: $PROXY_IP:$PROXY_PORT"
        return 1
    fi
    
    # 配置redsocks
    setup_redsocks || return 1
    
    # 启用IP转发
    enable_ip_forward
    
    # 设置iptables规则
    setup_iptables || return 1
    
    # 启动redsocks服务
    log "启动 redsocks 服务..."
    
    if [ "$USE_SYSTEMD" = true ]; then
        systemctl daemon-reload
        
        # 先停止可能存在的服务
        systemctl stop redsocks.service 2>/dev/null || true
        
        # 启用并启动服务
        systemctl enable redsocks.service 2>/dev/null || true
        if systemctl start redsocks.service; then
            # 等待服务启动
            sleep 3
            if systemctl is-active --quiet redsocks.service; then
                log "流量转发启动成功"
                echo "✅ 流量转发状态: 已启用 (转发到 $PROXY_IP:$PROXY_PORT)"
                # 显示服务状态
                systemctl status redsocks.service --no-pager -l | head -n 5
            else
                error "redsocks 服务启动后立即停止"
                log "查看详细错误: sudo journalctl -u redsocks -n 20"
                # 显示错误日志
                journalctl -u redsocks.service -n 10 --no-pager >&2
                cleanup_iptables
                return 1
            fi
        else
            error "redsocks 服务启动失败"
            log "查看详细错误: sudo journalctl -u redsocks -n 20"
            # 显示错误日志
            journalctl -u redsocks.service -n 10 --no-pager >&2
            cleanup_iptables
            return 1
        fi
    else
        # 使用传统方式启动redsocks
        # 先停止可能存在的服务
        pkill redsocks 2>/dev/null || true
        
        # 启动redsocks
        redsocks -c /etc/redsocks.conf -p /var/run/redsocks.pid &
        local pid=$!
        
        # 等待服务启动
        sleep 3
        
        # 检查进程是否仍在运行
        if kill -0 $pid 2>/dev/null; then
            log "流量转发启动成功"
            echo "✅ 流量转发状态: 已启用 (转发到 $PROXY_IP:$PROXY_PORT)"
            echo "ℹ️  redsocks PID: $pid"
        else
            error "redsocks 启动失败"
            cleanup_iptables
            return 1
        fi
    fi
}

# 停止代理
stop_proxy() {
    log "停止流量转发..."
    
    # 不需要执行完整的系统检查，只需确保必要的命令可用
    if ! command -v iptables &>/dev/null || ! command -v systemctl &>/dev/null; then
        error "缺少必要的系统命令"
        return 1
    fi
    
    if [ "$USE_SYSTEMD" = true ]; then
        # 停止redsocks服务
        log "停止 redsocks 服务..."
        systemctl stop redsocks.service 2>/dev/null || true
        
        # 确保服务真的停止了
        if systemctl is-active --quiet redsocks.service; then
            log "服务仍在运行，尝试强制停止..."
            systemctl kill redsocks.service 2>/dev/null || true
            sleep 1
        fi
    else
        # 使用传统方式停止redsocks
        log "停止 redsocks 进程..."
        pkill redsocks 2>/dev/null || true
        sleep 1
    fi
    
    # 清理iptables规则
    cleanup_iptables
    
    # 禁用IP转发
    disable_ip_forward
    
    if [ "$USE_SYSTEMD" = true ]; then
        # 强制刷新systemd状态
        systemctl daemon-reload
        
        # 再次检查服务状态
        if systemctl is-active --quiet redsocks.service; then
            error "无法停止redsocks服务，请尝试手动停止: sudo systemctl stop redsocks.service"
        else
            log "流量转发已停止"
            echo "✅ 流量转发状态: 已禁用"
        fi
    else
        log "流量转发已停止"
        echo "✅ 流量转发状态: 已禁用"
    fi
}

# 重启代理
restart_proxy() {
    log "重启流量转发..."
    
    # 执行系统检查（重启需要完整检查）
    check_system
    
    # 停止服务
    if [ "$USE_SYSTEMD" = true ]; then
        # 停止redsocks服务
        log "停止 redsocks 服务..."
        systemctl stop redsocks.service 2>/dev/null || true
        
        # 确保服务真的停止了
        if systemctl is-active --quiet redsocks.service; then
            log "服务仍在运行，尝试强制停止..."
            systemctl kill redsocks.service 2>/dev/null || true
            sleep 1
        fi
    else
        # 使用传统方式停止redsocks
        log "停止 redsocks 进程..."
        pkill redsocks 2>/dev/null || true
        sleep 1
    fi
    
    # 清理iptables规则
    cleanup_iptables
    
    # 加载配置
    load_config
    
    # 检查远程代理是否可用
    if ! check_proxy_connectivity; then
        error "远程Clash Verge代理服务器不可达: $PROXY_IP:$PROXY_PORT"
        return 1
    fi
    
    # 配置redsocks
    setup_redsocks || return 1
    
    # 启用IP转发
    enable_ip_forward
    
    # 设置iptables规则
    setup_iptables || return 1
    
    # 启动redsocks服务
    log "启动 redsocks 服务..."
    
    if [ "$USE_SYSTEMD" = true ]; then
        systemctl daemon-reload
        
        # 先停止可能存在的服务
        systemctl stop redsocks.service 2>/dev/null || true
        
        # 启用并启动服务
        systemctl enable redsocks.service 2>/dev/null || true
        if systemctl start redsocks.service; then
            # 等待服务启动
            sleep 3
            if systemctl is-active --quiet redsocks.service; then
                log "流量转发重启成功"
                echo "✅ 流量转发状态: 已启用 (转发到 $PROXY_IP:$PROXY_PORT)"
                # 显示服务状态
                systemctl status redsocks.service --no-pager -l | head -n 5
            else
                error "redsocks 服务启动后立即停止"
                log "查看详细错误: sudo journalctl -u redsocks -n 20"
                # 显示错误日志
                journalctl -u redsocks.service -n 10 --no-pager >&2
                cleanup_iptables
                return 1
            fi
        else
            error "redsocks 服务启动失败"
            log "查看详细错误: sudo journalctl -u redsocks -n 20"
            # 显示错误日志
            journalctl -u redsocks.service -n 10 --no-pager >&2
            cleanup_iptables
            return 1
        fi
    else
        # 使用传统方式启动redsocks
        # 先停止可能存在的服务
        pkill redsocks 2>/dev/null || true
        
        # 启动redsocks
        redsocks -c /etc/redsocks.conf -p /var/run/redsocks.pid &
        local pid=$!
        
        # 等待服务启动
        sleep 3
        
        # 检查进程是否仍在运行
        if kill -0 $pid 2>/dev/null; then
            log "流量转发重启成功"
            echo "✅ 流量转发状态: 已启用 (转发到 $PROXY_IP:$PROXY_PORT)"
            echo "ℹ️  redsocks PID: $pid"
        else
            error "redsocks 启动失败"
            cleanup_iptables
            return 1
        fi
    fi
}

# 检查代理连通性
check_proxy_connectivity() {
    log "检查远程Clash Verge代理连通性: $PROXY_IP:$PROXY_PORT"
    
    # 使用nc或telnet检查端口连通性
    if command -v nc >/dev/null 2>&1; then
        if timeout 5 nc -z "$PROXY_IP" "$PROXY_PORT" 2>/dev/null; then
            return 0
        fi
    elif command -v telnet >/dev/null 2>&1; then
        if timeout 5 bash -c "echo '' | telnet $PROXY_IP $PROXY_PORT" 2>/dev/null | grep -q "Connected"; then
            return 0
        fi
    fi
    
    return 1
}

# 检查代理状态（不需要root权限）
check_status() {
    echo "=== 流量转发状态检查 ==="
    
    # 检查服务安装状态
    local service_installed=false
    local system_command_installed=false
    
    # 检查systemd服务是否安装
    if [ -f "/etc/systemd/system/stream-weaver.service" ]; then
        echo "✅ Stream Weaver服务: 已安装"
        service_installed=true
    else
        echo "❌ Stream Weaver服务: 未安装"
    fi
    
    # 检查系统级命令是否安装
    if [ -L "/usr/local/bin/sw" ] || [ -f "/usr/local/bin/sw" ]; then
        echo "✅ 系统级命令 'sw': 已安装"
        system_command_installed=true
    else
        echo "❌ 系统级命令 'sw': 未安装"
    fi
    
    local service_running=false
    
    if [ "$USE_SYSTEMD" = true ]; then
        # 检查redsocks服务状态
        if systemctl is-active --quiet redsocks.service 2>/dev/null; then
            echo "✅ redsocks 服务: 运行中"
            service_running=true
        else
            echo "❌ redsocks 服务: 未运行"
        fi
    else
        # 检查redsocks进程
        if pgrep redsocks >/dev/null 2>&1; then
            echo "✅ redsocks 进程: 运行中 (PID: $(pgrep redsocks))"
            service_running=true
        else
            echo "❌ redsocks 进程: 未运行"
        fi
    fi
    
    if [ "$service_running" = true ]; then
        # 检查iptables规则（需要root权限）
        if [[ $EUID -eq 0 ]]; then
            local ipv4_rules=false
            local ipv6_rules=false
            
            # 检查IPv4规则
            if iptables -t nat -L OUTPUT 2>/dev/null | grep -q "CLASH_FORWARD"; then
                echo "✅ IPv4 iptables 规则: 已配置"
                ipv4_rules=true
            else
                echo "❌ IPv4 iptables 规则: 未配置"
            fi
            
            # 检查IPv6规则
            if command -v ip6tables >/dev/null 2>&1; then
                if ip6tables -t nat -L OUTPUT 2>/dev/null | grep -q "CLASH_FORWARD6"; then
                    echo "✅ IPv6 ip6tables 规则: 已配置"
                    ipv6_rules=true
                else
                    echo "❌ IPv6 ip6tables 规则: 未配置"
                fi
            else
                echo "⚠️  IPv6 ip6tables: 不可用"
            fi
            
            # 综合状态判断
            if $ipv4_rules || $ipv6_rules; then
                echo "✅ 流量转发状态: 已启用"
                if $ipv4_rules && $ipv6_rules; then
                    echo "🌐 协议支持: IPv4 + IPv6"
                elif $ipv4_rules; then
                    echo "🌐 协议支持: 仅IPv4"
                else
                    echo "🌐 协议支持: 仅IPv6"
                fi
            else
                echo "⚠️  流量转发状态: 配置异常"
            fi
            
            # 显示当前配置
            load_config
            echo "📡 远程代理服务器: $PROXY_IP:$PROXY_PORT"
            
            # 检查连通性
            if check_proxy_connectivity; then
                echo "🌐 代理连通性: 正常"
            else
                echo "⚠️  代理连通性: 异常"
            fi
        else
            echo "⚠️  iptables 规则: 需要root权限检查"
            echo "ℹ️  流量转发状态: 服务运行中（详细状态需要root权限）"
        fi
    else
        echo "❌ 流量转发状态: 已禁用"
        
        # 如果有root权限，显示服务失败原因
        if [[ $EUID -eq 0 ]] && [ "$USE_SYSTEMD" = true ]; then
            echo ""
            echo "📋 服务状态详情:"
            systemctl status redsocks.service | head -n 10 || true
            echo ""
            echo "📋 最近日志:"
            journalctl -u redsocks.service -n 5 --no-pager || true
        elif [[ $EUID -eq 0 ]] && [ "$USE_SYSTEMD" = false ]; then
            echo ""
            echo "ℹ️  提示: 使用 'ps aux | grep redsocks' 查看进程信息"
        else
            echo ""
            if [ "$USE_SYSTEMD" = true ]; then
                echo "ℹ️  提示: 使用 'sudo journalctl -u redsocks -n 10' 查看详细错误"
            else
                echo "ℹ️  提示: 使用 'ps aux | grep redsocks' 查看进程信息"
            fi
        fi
    fi
    
    # 显示IP转发状态
    local ipv4_forward=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)
    local ipv6_forward=$(cat /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null)
    
    echo ""
    echo "📡 IP转发状态:"
    if [ "$ipv4_forward" = "1" ]; then
        echo "   ✅ IPv4转发: 已启用"
    else
        echo "   ❌ IPv4转发: 已禁用"
    fi
    
    if [ "$ipv6_forward" = "1" ]; then
        echo "   ✅ IPv6转发: 已启用"
    else
        echo "   ❌ IPv6转发: 已禁用"
    fi
    
    # 检查redsocks配置文件
    if [ -f "/etc/redsocks.conf" ]; then
        echo "✅ redsocks配置文件: 存在"
        
        if [[ $EUID -eq 0 ]]; then
            echo ""
            echo "📋 redsocks配置内容:"
            cat /etc/redsocks.conf | grep -v "^#" | grep -v "^$"
        fi
    else
        echo "❌ redsocks配置文件: 不存在"
    fi
    
    # 检查redsocks可执行文件
    local redsocks_path=$(which redsocks 2>/dev/null || echo "")
    if [ -n "$redsocks_path" ]; then
        echo "✅ redsocks可执行文件: $redsocks_path"
    else
        echo "❌ redsocks可执行文件: 未找到"
    fi
}

# 创建redsocks systemd服务文件
create_redsocks_service() {
    # 如果systemd不可用，则不创建服务文件
    if [ "$USE_SYSTEMD" = false ]; then
        log "systemd不可用，跳过服务文件创建"
        return 0
    fi
    
    local service_file="/etc/systemd/system/redsocks.service"
    local redsocks_path
    local force_update="${1:-no}"
    
    # 查找redsocks可执行文件的实际路径
    redsocks_path=$(which redsocks 2>/dev/null || echo "/usr/sbin/redsocks")
    
    if [ ! -f "$redsocks_path" ] && [ ! -x "$redsocks_path" ]; then
        # 尝试其他常见路径
        for path in "/usr/sbin/redsocks" "/usr/bin/redsocks" "/usr/local/sbin/redsocks" "/usr/local/bin/redsocks"; do
            if [ -f "$path" ] && [ -x "$path" ]; then
                redsocks_path="$path"
                break
            fi
        done
        
        # 如果仍然找不到，尝试重新安装
        if [ ! -f "$redsocks_path" ] && [ ! -x "$redsocks_path" ]; then
            log "重新安装redsocks..."
            if [ "$SYSTEM_TYPE" = "debian" ]; then
                apt-get install -y redsocks || {
                    error "redsocks重新安装失败"
                    return 1
                }
            else
                if command -v dnf &>/dev/null; then
                    dnf install -y redsocks || {
                        error "redsocks重新安装失败"
                        return 1
                    }
                else
                    yum install -y redsocks || {
                        error "redsocks重新安装失败"
                        return 1
                    }
                fi
            fi
            redsocks_path=$(which redsocks 2>/dev/null || echo "/usr/sbin/redsocks")
        fi
    fi
    
    if [ ! -f "$redsocks_path" ] && [ ! -x "$redsocks_path" ]; then
        error "找不到redsocks可执行文件，请确保已正确安装"
        return 1
    fi
    
    log "找到redsocks路径: $redsocks_path"
    
    # 只有在服务文件不存在或强制更新时才创建
    if [ ! -f "$service_file" ] || [ "$force_update" = "force" ]; then
        log "创建 redsocks systemd 服务文件..."
        cat > "$service_file" <<EOF
[Unit]
Description=Redsocks transparent SOCKS proxy redirector
After=network.target

[Service]
Type=simple
ExecStart=$redsocks_path -c /etc/redsocks.conf
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
Restart=on-failure
RestartSec=5
User=root
Group=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        log "redsocks 服务文件创建完成"
    fi
}

# 创建配置文件
create_config() {
    local proxy_ip="$1"
    local proxy_port="$2"
    
    if [ -z "$proxy_ip" ] || [ -z "$proxy_port" ]; then
        echo "❌ 用法: $0 config <proxy_ip> <proxy_port>"
        exit 1
    fi
    
    # 只创建配置文件，不执行系统检查
    log "创建配置文件..."
    
    # 确保配置目录存在
    mkdir -p "/etc/clash_forward" 2>/dev/null || {
        error "无法创建配置目录"
        exit 1
    }
    
    cat > "$CONFIG_FILE" <<EOF
# 远程Clash Verge代理配置文件
PROXY_IP="$proxy_ip"
PROXY_PORT="$proxy_port"
LAST_CONFIG_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
EOF
    
    chmod 600 "$CONFIG_FILE"
    log "配置文件已创建: $CONFIG_FILE"
    echo "✅ 远程代理配置已保存: $proxy_ip:$proxy_port"
}

# 添加自定义豁免规则
add_exemption() {
    local exemption_type="$1"
    local exemption_value="$2"
    
    if [ -z "$exemption_type" ] || [ -z "$exemption_value" ]; then
        echo "❌ 用法: $0 add-exemption <ip|domain|port> <value>"
        echo "   支持使用逗号分隔添加多个目标，例如: 192.168.1.100,192.168.1.101"
        return 1
    fi
    
    # 确保配置目录存在
    mkdir -p "/etc/clash_forward" 2>/dev/null || {
        error "无法创建配置目录"
        exit 1
    }
    
    # 创建豁免配置文件（如果不存在）
    if [ ! -f "$CUSTOM_EXEMPTION_FILE" ]; then
        cat > "$CUSTOM_EXEMPTION_FILE" <<EOF
# 自定义豁免规则配置文件
# 格式: 类型=值
# 类型: ip, domain, port
# 示例:
# ip=192.168.1.100
# domain=example.com
# port=8080
EOF
        chmod 600 "$CUSTOM_EXEMPTION_FILE"
    fi
    
    # 处理逗号分隔的多个值
    # 使用更简单的方法分割字符串
    local values=()
    local temp_value=""
    
    # 遍历每个字符来分割逗号分隔的值
    for (( i=0; i<${#exemption_value}; i++ )); do
        char="${exemption_value:$i:1}"
        if [[ "$char" == "," ]]; then
            # 去除空格并添加到数组
            temp_value=$(echo "$temp_value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$temp_value" ]; then
                values+=("$temp_value")
            fi
            temp_value=""
        else
            temp_value+="$char"
        fi
    done
    
    # 添加最后一个值
    temp_value=$(echo "$temp_value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$temp_value" ]; then
        values+=("$temp_value")
    fi
    
    local added_count=0
    local error_count=0
    
    log "开始处理批量添加，总共 ${#values[@]} 个值"
    
    for value in "${values[@]}"; do
        # 去除空格（额外保险）
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [ -n "$value" ]; then
            # 检查是否已存在相同的规则
            if grep -q "^$exemption_type=$value$" "$CUSTOM_EXEMPTION_FILE" 2>/dev/null; then
                log "豁免规则已存在: $exemption_type=$value"
                echo "⚠️  豁免规则已存在: $exemption_type=$value"
            else
                # 添加新的豁免规则
                # 使用 || true 确保即使命令失败也不会导致脚本退出
                echo "$exemption_type=$value" >> "$CUSTOM_EXEMPTION_FILE" || true
                local result=$?
                if [ $result -eq 0 ]; then
                    log "已添加自定义豁免规则: $exemption_type=$value"
                    echo "✅ 已添加自定义豁免规则: $exemption_type=$value"
                    # 使用更安全的方式增加计数器
                    added_count=$((added_count + 1))
                else
                    log "添加豁免规则失败: $exemption_type=$value"
                    echo "❌ 添加豁免规则失败: $exemption_type=$value"
                    # 使用更安全的方式增加计数器
                    error_count=$((error_count + 1))
                fi
            fi
        fi
    done
    
    log "批量添加完成，成功添加: $added_count，失败: $error_count"
    
    if [ $added_count -gt 0 ]; then
        echo "ℹ️  重启服务以使豁免规则生效"
    fi
    
    # 如果有错误，返回非零退出码
    if [ $error_count -gt 0 ]; then
        return 1
    fi
    
    return 0
}

# 删除自定义豁免规则
remove_exemption() {
    local exemption_type="$1"
    local exemption_value="$2"
    
    if [ -z "$exemption_type" ] || [ -z "$exemption_value" ]; then
        echo "❌ 用法: $0 remove-exemption <ip|domain|port> <value>"
        exit 1
    fi
    
    if [ ! -f "$CUSTOM_EXEMPTION_FILE" ]; then
        echo "❌ 没有找到自定义豁免配置文件"
        exit 1
    fi
    
    # 删除指定的豁免规则
    local temp_file=$(mktemp)
    grep -v "^$exemption_type=$exemption_value$" "$CUSTOM_EXEMPTION_FILE" > "$temp_file"
    
    if cmp -s "$CUSTOM_EXEMPTION_FILE" "$temp_file"; then
        echo "❌ 未找到指定的豁免规则: $exemption_type=$exemption_value"
        rm -f "$temp_file"
        exit 1
    else
        mv "$temp_file" "$CUSTOM_EXEMPTION_FILE"
        chmod 600 "$CUSTOM_EXEMPTION_FILE"
        log "已删除自定义豁免规则: $exemption_type=$exemption_value"
        echo "✅ 已删除自定义豁免规则: $exemption_type=$exemption_value"
        echo "ℹ️  重启服务以使更改生效"
    fi
}

# 删除所有自定义豁免规则
remove_all_exemptions() {
    if [ ! -f "$CUSTOM_EXEMPTION_FILE" ]; then
        echo "ℹ️  没有配置自定义豁免规则"
        return 0
    fi
    
    # 创建新的空配置文件
    cat > "$CUSTOM_EXEMPTION_FILE" <<EOF
# 自定义豁免规则配置文件
# 格式: 类型=值
# 类型: ip, domain, port
# 示例:
# ip=192.168.1.100
# domain=example.com
# port=8080
EOF
    
    chmod 600 "$CUSTOM_EXEMPTION_FILE"
    log "已删除所有自定义豁免规则"
    echo "✅ 已删除所有自定义豁免规则"
    echo "ℹ️  重启服务以使更改生效"
}

# 列出所有自定义豁免规则
list_exemptions() {
    if [ ! -f "$CUSTOM_EXEMPTION_FILE" ]; then
        echo "ℹ️  没有配置自定义豁免规则"
        return 0
    fi
    
    echo "📋 自定义豁免规则列表:"
    grep -v "^#" "$CUSTOM_EXEMPTION_FILE" | grep -v "^$" | while read -r line; do
        echo "   $line"
    done
    
    if ! grep -v "^#" "$CUSTOM_EXEMPTION_FILE" | grep -v "^$" >/dev/null; then
        echo "   (无自定义豁免规则)"
    fi
}

# 等待用户按回车键继续
wait_for_enter() {
    echo ""
    echo "按回车键继续..."
    # 等待用户按回车键
    if [ -t 0 ]; then
        # 交互式终端，等待回车键
        read -r </dev/tty
    else
        # 非交互式环境，等待一小段时间
        sleep 2
    fi
    echo ""
}

# 刷新状态函数
refresh_status() {
    # 强制刷新systemd状态
    systemctl daemon-reload >/dev/null 2>&1 || true
    
    # 显示当前状态
    echo "📊 当前状态:"
    # 强制重新检查服务状态，不使用缓存
    if systemctl is-active --quiet redsocks.service 2>/dev/null; then
        echo "   ✅ 流量转发服务: 运行中"
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE" 2>/dev/null || true
            echo "   📡 远程代理服务器: ${PROXY_IP:-未配置}:${PROXY_PORT:-未配置}"
        fi
    else
        echo "   ❌ 流量转发服务: 未运行"
    fi
}

# 交互式菜单
interactive_menu() {
    # 检测是否在交互式终端中运行
    local is_interactive=0
    if [ -t 0 ]; then
        is_interactive=1
    fi
    
    while true; do
        # 只在交互式终端中清屏
        if [ $is_interactive -eq 1 ]; then
            clear
        fi
        
        echo "🔧 流量转发到远程Clash Verge代理工具 - 交互式菜单"
        echo "=================================================="
        echo ""
        
        # 显示当前状态
        refresh_status
        echo ""
        
        echo "📋 可用操作:"
        echo "   1) 📊 检查详细状态"
        echo "   2) ⚙️  配置远程代理服务器"
        echo "   3) 🚀 启动流量转发"
        echo "   4) 🛑 停止流量转发"
        echo "   5) 🔄 重启流量转发"
        echo "   6) ➕ 添加自定义豁免规则"
        echo "   7) ➖ 删除自定义豁免规则"
        echo "   8) 📋 列出自定义豁免规则"
        echo "   9) 🌐 测试境外网站访问"
        echo "   10) 📦 安装为系统服务"
        echo "   11) 🗑️  卸载系统服务"
        echo "   12) 🗑️  重置系统到默认状态"
        echo "   13) 📖 显示帮助"
        echo "   0) 🚪 退出"
        echo ""
        
        # 使用不同的方式读取输入，取决于是否在交互式终端中
        if [ $is_interactive -eq 1 ]; then
            read -p "请选择操作 [0-13]: " choice
        else
            # 非交互式环境，从终端读取输入
            read -p "请选择操作 [0-13]: " choice </dev/tty
        fi
        echo ""
        
        case $choice in
            1)
                echo "📊 检查流量转发状态..."
                echo ""
                check_status
                wait_for_enter
                ;;
            2)
                echo "⚙️  配置远程代理服务器"
                echo ""
                
                # 读取上次的配置
                local last_proxy_ip="$DEFAULT_PROXY_IP"
                local last_proxy_port="$DEFAULT_PROXY_PORT"
                local last_config_time="无"
                
                if [ -f "$CONFIG_FILE" ]; then
                    source "$CONFIG_FILE" 2>/dev/null || true
                    last_proxy_ip="${PROXY_IP:-$DEFAULT_PROXY_IP}"
                    last_proxy_port="${PROXY_PORT:-$DEFAULT_PROXY_PORT}"
                    last_config_time="${LAST_CONFIG_TIME:-无}"
                    
                    echo "当前配置信息:"
                    echo "  IP: $last_proxy_ip"
                    echo "  端口: $last_proxy_port"
                    echo "  上次配置时间: $last_config_time"
                    echo ""
                fi
                
                read -p "请输入远程Clash Verge服务器IP [默认: $last_proxy_ip]: " proxy_ip
                proxy_ip=${proxy_ip:-$last_proxy_ip}
                
                read -p "请输入远程Clash Verge服务器端口 [默认: $last_proxy_port]: " proxy_port
                proxy_port=${proxy_port:-$last_proxy_port}
                
                echo ""
                echo "配置信息:"
                echo "  IP: $proxy_ip"
                echo "  端口: $proxy_port"
                echo ""
                
                read -p "确认配置? [y/N]: " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    if [[ $EUID -eq 0 ]]; then
                        create_config "$proxy_ip" "$proxy_port"
                    else
                        echo ""
                        echo "❌ 需要root权限来保存配置"
                        echo "请使用: sudo $0 config $proxy_ip $proxy_port"
                    fi
                else
                    echo "❌ 配置已取消"
                fi
                wait_for_enter
                ;;
            3)
                echo "🚀 启动流量转发..."
                echo ""
                if [[ $EUID -eq 0 ]]; then
                    # 首先检查是否存在配置文件
                    if [ ! -f "$CONFIG_FILE" ]; then
                        echo "❌ 未找到代理配置文件"
                        echo "请先使用选项 2 配置远程代理服务器信息"
                        wait_for_enter
                        continue
                    fi
                    
                    start_proxy
                    # 强制刷新服务状态
                    systemctl daemon-reload
                    sleep 1
                else
                    echo "❌ 需要root权限来启动流量转发"
                    echo "请使用: sudo $0 start"
                    echo ""
                    echo "是否尝试使用sudo执行? [y/N]"
                    read -p "> " try_sudo
                    if [[ $try_sudo =~ ^[Yy]$ ]]; then
                        echo "执行: sudo $0 start"
                        sudo "$0" start
                        sleep 1
                    fi
                fi
                wait_for_enter
                ;;
            4)
                echo "🛑 停止流量转发..."
                echo ""
                if [[ $EUID -eq 0 ]]; then
                    stop_proxy
                    # 强制刷新服务状态
                    systemctl daemon-reload
                    sleep 1
                else
                    echo "❌ 需要root权限来停止流量转发"
                    echo "请使用: sudo $0 stop"
                    echo ""
                    echo "是否尝试使用sudo执行? [y/N]"
                    read -p "> " try_sudo
                    if [[ $try_sudo =~ ^[Yy]$ ]]; then
                        echo "执行: sudo $0 stop"
                        sudo "$0" stop
                        sleep 1
                    fi
                fi
                wait_for_enter
                ;;
            5)
                echo "🔄 重启流量转发..."
                echo ""
                if [[ $EUID -eq 0 ]]; then
                    stop_proxy
                    echo ""
                    sleep 2
                    start_proxy
                    # 强制刷新服务状态
                    systemctl daemon-reload
                    sleep 1
                else
                    echo "❌ 需要root权限来重启流量转发"
                    echo "请使用: sudo $0 restart"
                    echo ""
                    echo "是否尝试使用sudo执行? [y/N]"
                    read -p "> " try_sudo
                    if [[ $try_sudo =~ ^[Yy]$ ]]; then
                        echo "执行: sudo $0 restart"
                        sudo "$0" restart
                        sleep 1
                    fi
                fi
                wait_for_enter
                ;;
            6)
                echo "➕ 添加自定义豁免规则"
                echo ""
                echo "支持的豁免类型:"
                echo "  1) IP地址 (例如: 192.168.1.100 或 192.168.1.100,192.168.1.101)"
                echo "  2) 域名 (例如: example.com 或 example.com,google.com)"
                echo "  3) 端口号 (例如: 8080 或 8080,9090,3306)"
                echo ""
                read -p "请选择豁免类型 [1-3] (输入0取消): " type_choice
                
                # 检查输入是否为有效数字
                if ! [[ "$type_choice" =~ ^[0-9]+$ ]]; then
                    echo "❌ 无效输入，请输入数字"
                    wait_for_enter
                    continue
                fi
                
                # 检查是否选择取消
                if [ "$type_choice" -eq 0 ]; then
                    echo "❌ 操作已取消"
                    wait_for_enter
                    continue
                fi
                
                # 根据选择设置豁免类型
                local exemption_type=""
                case "$type_choice" in
                    1)
                        exemption_type="ip"
                        ;;
                    2)
                        exemption_type="domain"
                        ;;
                    3)
                        exemption_type="port"
                        ;;
                    *)
                        echo "❌ 不支持的类型: $type_choice"
                        echo "支持的类型: 1 (IP地址), 2 (域名), 3 (端口号)"
                        wait_for_enter
                        continue
                        ;;
                esac
                
                read -p "请输入豁免值: " exemption_value
                
                if [[ -n "$exemption_type" && -n "$exemption_value" ]]; then
                    if [[ $EUID -eq 0 ]]; then
                        add_exemption "$exemption_type" "$exemption_value"
                        echo ""
                        echo "ℹ️  请重启服务以使豁免规则生效"
                    else
                        echo "❌ 需要root权限来添加豁免规则"
                        echo "请使用: sudo $0 add-exemption $exemption_type $exemption_value"
                    fi
                else
                    echo "❌ 豁免类型和值不能为空"
                fi
                wait_for_enter
                ;;
            7)
                echo "➖ 删除自定义豁免规则"
                echo ""
                
                # 显示带序号的豁免规则列表
                local exemptions_list=()
                local count=1
                
                if [ -f "$CUSTOM_EXEMPTION_FILE" ]; then
                    while IFS= read -r line || [[ -n "$line" ]]; do
                        # 跳过注释和空行
                        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
                        
                        echo "   $count) $line"
                        exemptions_list+=("$line")
                        ((count++))
                    done < "$CUSTOM_EXEMPTION_FILE"
                fi
                
                if [ ${#exemptions_list[@]} -eq 0 ]; then
                    echo "ℹ️  没有配置自定义豁免规则"
                    wait_for_enter
                    continue
                fi
                
                echo ""
                echo "支持的操作:"
                echo "  1-${#exemptions_list[@]}) 删除指定规则"
                echo "  0) 取消操作"
                echo "  all) 删除所有规则"
                echo ""
                read -p "请选择操作 [1-${#exemptions_list[@]} / all / 0]: " choice
                
                # 检查是否选择删除所有规则
                if [ "$choice" = "all" ]; then
                    echo "⚠️  您将删除所有自定义豁免规则"
                    read -p "确认删除所有规则? [y/N]: " confirm_all
                    if [[ $confirm_all =~ ^[Yy]$ ]]; then
                        if [[ $EUID -eq 0 ]]; then
                            remove_all_exemptions
                            echo ""
                            echo "ℹ️  请重启服务以使更改生效"
                        else
                            echo "❌ 需要root权限来删除所有豁免规则"
                            echo "请使用: sudo $0"
                        fi
                    else
                        echo "❌ 删除所有规则操作已取消"
                    fi
                    wait_for_enter
                    continue
                fi
                
                # 检查输入是否为空
                if [ -z "$choice" ]; then
                    echo "❌ 输入不能为空"
                    wait_for_enter
                    continue
                fi
                
                # 检查是否选择取消
                if [ "$choice" -eq 0 ]; then
                    echo "❌ 操作已取消"
                    wait_for_enter
                    continue
                fi
                
                # 检查输入是否为有效数字
                if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
                    echo "❌ 无效输入，请输入数字或 'all'"
                    wait_for_enter
                    continue
                fi
                
                # 检查序号是否在有效范围内
                if [ "$choice" -lt 1 ] || [ "$choice" -gt ${#exemptions_list[@]} ]; then
                    echo "❌ 序号超出范围，请输入 1-${#exemptions_list[@]} 之间的数字"
                    wait_for_enter
                    continue
                fi
                
                # 获取选中的规则
                local selected_rule="${exemptions_list[$((choice-1))]}"
                local exemption_type=$(echo "$selected_rule" | cut -d'=' -f1)
                local exemption_value=$(echo "$selected_rule" | cut -d'=' -f2)
                
                echo "您选择删除的规则: $exemption_type=$exemption_value"
                read -p "确认删除? [y/N]: " confirm
                
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    if [[ $EUID -eq 0 ]]; then
                        remove_exemption "$exemption_type" "$exemption_value"
                        echo ""
                        echo "ℹ️  请重启服务以使更改生效"
                    else
                        echo "❌ 需要root权限来删除豁免规则"
                        echo "请使用: sudo $0 remove-exemption $exemption_type $exemption_value"
                    fi
                else
                    echo "❌ 删除操作已取消"
                fi
                wait_for_enter
                ;;
            8)
                echo "📋 自定义豁免规则列表"
                echo ""
                list_exemptions
                wait_for_enter
                ;;
            9)
                echo "🌐 测试境外网站访问"
                echo ""
                # 临时禁用严格模式以允许测试命令失败
                set +e
                test_connectivity
                # 恢复严格模式
                if [[ "${1:-}" != "test" ]]; then
                    set -euo pipefail
                else
                    set -uo pipefail
                fi
                wait_for_enter
                ;;
            10)
                echo "📦 安装为系统服务"
                echo ""
                echo "⚠️  此操作将安装Stream Weaver为系统服务"
                echo "   安装后可以使用systemctl命令直接控制服务"
                echo "   同时创建系统级命令 'sw'，可直接使用sw命令控制流量转发"
                echo ""
                read -p "确认安装服务? [y/N]: " confirm_install
                if [[ $confirm_install =~ ^[Yy]$ ]]; then
                    if [[ $EUID -eq 0 ]]; then
                        install_service
                    else
                        echo "❌ 需要root权限来安装服务"
                        echo "请使用: sudo $0 install-service"
                    fi
                else
                    echo "❌ 服务安装已取消"
                fi
                wait_for_enter
                ;;
            11)
                echo "🗑️  卸载系统服务"
                echo ""
                echo "⚠️  此操作将从系统中卸载Stream Weaver服务"
                echo "   同时移除系统级命令 'sw'"
                echo "   卸载后只能通过脚本命令控制流量转发"
                echo ""
                read -p "确认卸载服务? [y/N]: " confirm_uninstall
                if [[ $confirm_uninstall =~ ^[Yy]$ ]]; then
                    if [[ $EUID -eq 0 ]]; then
                        uninstall_service
                    else
                        echo "❌ 需要root权限来卸载服务"
                        echo "请使用: sudo $0 uninstall-service"
                    fi
                else
                    echo "❌ 服务卸载已取消"
                fi
                wait_for_enter
                ;;
            12)
                echo "🗑️  重置系统到默认状态"
                echo ""
                echo "⚠️  警告: 此操作将删除配置并停止服务"
                echo "   包括:"
                echo "   • 停止并禁用 redsocks 服务"
                echo "   • 清理所有 iptables 规则"
                echo "   • 禁用 IP 转发"
                echo "   • 删除代理配置文件"
                echo ""
                echo "请选择重置选项:"
                echo "  1) 完全重置（删除所有配置，包括豁免规则）"
                echo "  2) 部分重置（保留豁免规则）"
                echo "  3) 完全重置并卸载服务"
                echo "  4) 部分重置并卸载服务"
                echo "  0) 取消操作"
                echo ""
                read -p "请选择 [1/2/3/4/0]: " reset_choice
                
                case "$reset_choice" in
                    1)
                        echo ""
                        echo "⚠️  您将完全重置系统，包括删除所有豁免规则"
                        read -p "确认完全重置? [y/N]: " confirm_full
                        if [[ $confirm_full =~ ^[Yy]$ ]]; then
                            if [[ $EUID -eq 0 ]]; then
                                reset_system "yes" "no"  # 重置豁免规则，不卸载服务
                            else
                                echo "❌ 需要root权限来重置系统"
                                echo "请使用: sudo $0 reset"
                            fi
                        else
                            echo "❌ 完全重置操作已取消"
                        fi
                        ;;
                    2)
                        echo ""
                        echo "⚠️  您将部分重置系统，保留豁免规则"
                        read -p "确认部分重置? [y/N]: " confirm_partial
                        if [[ $confirm_partial =~ ^[Yy]$ ]]; then
                            if [[ $EUID -eq 0 ]]; then
                                reset_system "no" "no"  # 保留豁免规则，不卸载服务
                            else
                                echo "❌ 需要root权限来重置系统"
                                echo "请使用: sudo $0 reset"
                            fi
                        else
                            echo "❌ 部分重置操作已取消"
                        fi
                        ;;
                    3)
                        echo ""
                        echo "⚠️  您将完全重置系统并卸载服务"
                        echo "   包括删除所有豁免规则和服务文件"
                        read -p "确认完全重置并卸载服务? [y/N]: " confirm_full_uninstall
                        if [[ $confirm_full_uninstall =~ ^[Yy]$ ]]; then
                            if [[ $EUID -eq 0 ]]; then
                                reset_system "yes" "yes"  # 重置豁�规则，卸载服务
                            else
                                echo "❌ 需要root权限来重置系统"
                                echo "请使用: sudo $0 reset"
                            fi
                        else
                            echo "❌ 完全重置并卸载服务操作已取消"
                        fi
                        ;;
                    4)
                        echo ""
                        echo "⚠️  您将部分重置系统并卸载服务"
                        echo "   保留豁免规则，删除服务文件"
                        read -p "确认部分重置并卸载服务? [y/N]: " confirm_partial_uninstall
                        if [[ $confirm_partial_uninstall =~ ^[Yy]$ ]]; then
                            if [[ $EUID -eq 0 ]]; then
                                reset_system "no" "yes"  # 保留豁免规则，卸载服务
                            else
                                echo "❌ 需要root权限来重置系统"
                                echo "请使用: sudo $0 reset"
                            fi
                        else
                            echo "❌ 部分重置并卸载服务操作已取消"
                        fi
                        ;;
                    0|*)
                        echo "❌ 重置操作已取消"
                        ;;
                esac
                wait_for_enter
                ;;
                
            13)
                show_help
                wait_for_enter
                ;;
            0)
                echo "👋 再见！"
                break
                ;;
            *)
                echo "❌ 无效选择，请输入 0-13"
                wait_for_enter
                ;;
        esac
    done
}

# 测试境外网站访问功能
test_connectivity() {
    echo "🌐 测试境外网站访问功能"
    echo "========================"
    echo ""
    
    # 定义要测试的境外网站列表
    local websites=(
        "google.com"
        "youtube.com"
        "github.com"
        "wikipedia.org"
        "stackoverflow.com"
        "reddit.com"
        "twitter.com"
        "facebook.com"
        "instagram.com"
        "linkedin.com"
    )
    
    local success_count=0
    local total_count=${#websites[@]}
    
    echo "正在测试 $total_count 个境外主流网站的访问..."
    echo ""
    
    # 逐个测试网站访问
    for website in "${websites[@]}"; do
        echo -n "测试 $website ... "
        
        # 使用curl测试网站访问，设置5秒超时
        if command -v curl >/dev/null 2>&1; then
            # 使用|| true确保即使curl失败也不会导致脚本退出
            if curl -s --connect-timeout 5 --max-time 10 "https://$website" >/dev/null 2>&1 || \
               curl -s --connect-timeout 5 --max-time 10 "http://$website" >/dev/null 2>&1; then
                echo "✅ 可访问"
                ((success_count++))
            else
                echo "❌ 无法访问"
            fi
        elif command -v wget >/dev/null 2>&1; then
            # 使用|| true确保即使wget失败也不会导致脚本退出
            if wget --spider --timeout=5 --tries=1 "https://$website" >/dev/null 2>&1 || \
               wget --spider --timeout=5 --tries=1 "http://$website" >/dev/null 2>&1; then
                echo "✅ 可访问"
                ((success_count++))
            else
                echo "❌ 无法访问"
            fi
        else
            echo "⚠️  无可用测试工具 (需要curl或wget)"
            break
        fi
    done
    
    echo ""
    echo "📊 测试结果: $success_count/$total_count 个网站可访问"
    
    if [ $success_count -eq $total_count ]; then
        echo "🎉 所有测试网站均可正常访问！"
    elif [ $success_count -gt 0 ]; then
        echo "⚠️  部分网站可访问 ($success_count/$total_count)"
    else
        echo "❌ 所有测试网站均无法访问"
        echo "💡 建议检查:"
        echo "   • 网络连接是否正常"
        echo "   • 代理配置是否正确"
        echo "   • 远程Clash Verge服务是否运行"
        echo "   • 防火墙设置"
    fi
    
    echo ""
    echo "📝 测试的网站列表:"
    for website in "${websites[@]}"; do
        echo "   • $website"
    done
    
    # 返回成功状态码
    return 0
}

# 安装服务功能
install_service() {
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        echo "❌ 服务安装需要root权限"
        echo "请使用: sudo $0 install-service"
        exit 1
    fi
    
    log "开始安装Stream Weaver服务..."
    
    # 获取脚本的绝对路径
    local script_path=$(realpath "$0")
    
    # 创建systemd服务文件
    local service_file="/etc/systemd/system/stream-weaver.service"
    log "创建systemd服务文件: $service_file"
    
    cat > "$service_file" <<EOF
[Unit]
Description=Stream Weaver - Transparent proxy for Linux systems
After=network.target

[Service]
Type=forking
ExecStart=$script_path start
ExecStop=$script_path stop
ExecReload=$script_path restart
RemainAfterExit=yes
User=root
Group=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # 创建系统级命令链接
    local system_bin="/usr/local/bin/sw"
    log "创建系统级命令链接: $system_bin"
    
    # 检查是否在管道模式下运行（脚本路径和目标路径相同）
    if [ "$script_path" = "$system_bin" ]; then
        log "在管道模式下运行，跳过创建符号链接"
    else
        # 创建符号链接
        ln -sf "$script_path" "$system_bin"
        chmod +x "$system_bin"
    fi
    
    # 重新加载systemd配置
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable stream-weaver.service
    
    log "Stream Weaver服务安装完成"
    echo "✅ Stream Weaver服务已安装并启用"
    echo "ℹ️  现在可以使用以下命令控制服务:"
    echo "   启动服务: sudo systemctl start stream-weaver"
    echo "   停止服务: sudo systemctl stop stream-weaver"
    echo "   重启服务: sudo systemctl restart stream-weaver"
    echo "   查看状态: sudo systemctl status stream-weaver"
    echo ""
    echo "ℹ️  也可以直接使用sw命令控制流量转发:"
    echo "   配置代理: sudo sw config <IP> <端口>"
    echo "   启动转发: sudo sw start"
    echo "   停止转发: sudo sw stop"
    echo "   重启转发: sudo sw restart"
    echo "   查看状态: sw status"
    echo ""
    echo "⚠️  注意: 使用服务模式前请确保已配置代理服务器"
    echo "   配置命令: sudo $script_path config <IP> <端口>"
}

# 卸载服务功能
uninstall_service() {
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        echo "❌ 服务卸载需要root权限"
        echo "请使用: sudo $0 uninstall-service"
        exit 1
    fi
    
    log "开始卸载Stream Weaver服务..."
    
    # 停止服务
    systemctl stop stream-weaver.service 2>/dev/null || true
    
    # 禁用服务
    systemctl disable stream-weaver.service 2>/dev/null || true
    
    # 删除服务文件
    local service_file="/etc/systemd/system/stream-weaver.service"
    if [ -f "$service_file" ]; then
        rm -f "$service_file"
        log "已删除服务文件: $service_file"
    fi
    
    # 删除系统级命令链接
    local system_bin="/usr/local/bin/sw"
    if [ -L "$system_bin" ] || [ -f "$system_bin" ]; then
        rm -f "$system_bin"
        log "已删除系统级命令链接: $system_bin"
    fi
    
    # 重新加载systemd配置
    systemctl daemon-reload
    
    log "Stream Weaver服务卸载完成"
    echo "✅ Stream Weaver服务已卸载"
    echo "ℹ️  系统级命令 'sw' 已移除"
}

# 显示帮助信息
show_help() {
    cat <<EOF
🔧 Linux系统流量转发到远程Clash Verge代理工具

📖 用法: $0 <命令> [参数]

📋 命令:
    start (s)                启动流量转发模式
    stop (x)                 停止流量转发模式
    status (t)               检查流量转发状态 (无需root权限)
    restart (r)              重启流量转发服务
    config (c) <ip> <port>   设置远程Clash Verge代理服务器配置
    add-exemption (a) <type> <value>  添加自定义豁免规则
    remove-exemption (rm) <type> <value>  删除自定义豁免规则
    remove-all-exemptions (ra)  删除所有自定义豁免规则
    list-exemptions (l)      列出所有自定义豁免规则
    test                     测试境外网站访问功能
    install-service          安装为系统服务
    uninstall-service        从系统中卸载服务
    reset [-k|--keep-exemptions] [-u|--uninstall-service]  重置系统到默认状态
    menu (m)                 进入交互式菜单
    help (h)                 显示此帮助信息

💡 示例:
    $0 c 192.168.1.100 7890          # 设置远程Clash Verge代理服务器
    $0 s                             # 启动流量转发
    $0 t                             # 检查状态
    $0 x                             # 停止流量转发
    $0 a ip 192.168.1.100            # 豁免特定IP地址
    $0 a ip 192.168.1.100,192.168.1.101,192.168.1.102  # 豁免多个IP地址
    $0 a domain example.com          # 豁免特定域名
    $0 a port 8080                   # 豁免特定端口
    $0 a port 8080,9090,3306         # 豁免多个端口
    $0 l                             # 列出所有自定义豁免规则
    $0 test                          # 测试境外网站访问
    $0 install-service               # 安装为系统服务
    $0 uninstall-service             # 卸载服务
    $0 ra                            # 删除所有自定义豁免规则
    $0 reset                         # 完全重置系统（包括豁免规则）
    $0 reset -k                      # 部分重置系统（保留豁免规则）
    $0 reset -u                      # 完全重置系统并卸载服务
    $0 reset -k -u                   # 部分重置系统并卸载服务
    $0 m                             # 交互式菜单
    help (h)                 显示此帮助信息

在交互式菜单的"删除自定义豁免规则"选项中，您可以:
    • 选择特定规则序号删除单个规则
    • 输入"all"删除所有自定义豁免规则

在交互式菜单的"重置系统"选项中，您可以:
    • 选择完全重置（删除所有配置，包括豁免规则）
    • 选择部分重置（保留豁免规则）
    • 选择完全重置并卸载服务
    • 选择部分重置并卸载服务

⚠️  注意:
    • start(s)/stop(x)/restart(r)/config(c)/reset/add-exemption(a)/remove-exemption(rm)/remove-all-exemptions(ra)/install-service/uninstall-service 命令需要 root 权限
    • status(t)/menu(m)/help(h)/list-exemptions(l)/test 命令可以在普通用户下运行
    • 默认远程代理服务器: 192.168.1.100:7890
    • 配置文件位置: $CONFIG_FILE
    • 豁免规则文件位置: $CUSTOM_EXEMPTION_FILE

🔧 重置选项:
    • 使用 "reset" 命令完全重置系统（删除所有配置，包括豁免规则）
    • 使用 "reset -k" 或 "reset --keep-exemptions" 命令部分重置系统（保留豁免规则）
    • 使用 "reset -u" 或 "reset --uninstall-service" 命令重置系统并卸载服务
    • 使用 "reset -k -u" 命令部分重置系统并卸载服务
    • 在交互式菜单中选择重置选项时，可选择完全重置、部分重置、完全重置并卸载服务或部分重置并卸载服务

🔍 功能特点:
    • 透明转发：无需配置应用程序
    • 双栈支持：同时支持IPv4和IPv6流量
    • 智能路由：自动跳过本地和私有网络
    • 自定义豁免：支持IP、域名、端口的自定义豁免
    • 批量添加：支持使用逗号分隔一次添加多个目标
    • 自动备份：启动前备份 iptables/ip6tables 规则
    • 错误恢复：异常退出时自动恢复规则

🚀 安装服务后，您还可以直接使用 'sw' 命令:
    sudo sw config 192.168.1.100 7890  # 配置代理服务器
    sudo sw start                      # 启动流量转发
    sudo sw stop                       # 停止流量转发
    sudo sw restart                    # 重启流量转发
    sw status                          # 检查状态
    sw test                            # 测试境外网站访问
EOF
}

# 检查命令是否需要root权限
needs_root_permission() {
    local command="$1"
    case "$command" in
        start|s|stop|x|restart|r|config|c|reset|add-exemption|a|remove-exemption|rm|remove-all-exemptions|ra|install-service|uninstall-service)
            return 0  # 需要root权限
            ;;
        status|t|help|--help|-h|h|menu|m|list-exemptions|l|test)
            return 1  # 不需要root权限
            ;;
        *)
            return 1  # 默认不需要
            ;;
    esac
}

# 主函数
main() {
    local command="${1:-menu}"
    
    # 对于需要root权限的命令，提前检查权限
    if needs_root_permission "$command"; then
        check_root_permission "$@"
    fi
    
    case "$command" in
        start|s)
            start_proxy
            ;;
        stop|x)
            stop_proxy
            ;;
        status|t)
            check_status
            ;;
        restart|r)
            restart_proxy
            ;;
        config|c)
            create_config "$2" "$3"
            ;;
        add-exemption|a)
            add_exemption "$2" "$3"
            ;;
        remove-exemption|rm)
            remove_exemption "$2" "$3"
            ;;
        remove-all-exemptions|ra)
            remove_all_exemptions
            ;;
        list-exemptions|l)
            list_exemptions
            ;;
        test)
            test_connectivity
            # 对于测试命令，我们需要确保脚本正常退出而不是触发清理
            exit 0
            ;;
        install-service)
            install_service
            ;;
        uninstall-service)
            uninstall_service
            ;;
        reset)
            # 检查是否有参数指定是否重置豁免规则
            local reset_exemptions="yes"
            local uninstall_service="no"
            
            # 解析命令行参数
            shift  # 移除第一个参数（reset）
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --keep-exemptions|-k)
                        reset_exemptions="no"
                        shift
                        ;;
                    --uninstall-service|-u)
                        uninstall_service="yes"
                        shift
                        ;;
                    *)
                        echo "❌ 未知参数: $1"
                        echo "支持的参数:"
                        echo "  -k, --keep-exemptions  保留豁免规则"
                        echo "  -u, --uninstall-service  卸载服务"
                        exit 1
                        ;;
                esac
            done
            
            if [[ $EUID -eq 0 ]]; then
                reset_system "$reset_exemptions" "$uninstall_service"
            else
                echo "❌ 需要root权限来重置系统"
                echo "请使用: sudo $0 reset"
                exit 1
            fi
            ;;
        menu|m)
            interactive_menu
            ;;
        help|--help|-h|h)
            show_help
            ;;
        *)
            echo "❌ 未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"