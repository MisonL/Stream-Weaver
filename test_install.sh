#!/bin/bash

# 测试脚本，用于模拟一键安装过程

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

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 测试函数
test_install() {
    log "开始测试一键安装功能..."
    
    # 测试1: 基本安装
    log "测试1: 基本安装"
    if curl -fsSL "https://raw.githubusercontent.com/MisonL/Stream-Weaver/master/sw.sh" | sudo bash; then
        success "测试1通过"
    else
        error "测试1失败"
        return 1
    fi
    
    # 检查脚本是否已安装
    if [ -f "/usr/local/bin/sw" ]; then
        success "脚本已成功安装到 /usr/local/bin/sw"
    else
        error "脚本未安装到预期位置"
        return 1
    fi
    
    # 测试2: 安装为系统服务
    log "测试2: 安装为系统服务"
    if curl -fsSL "https://raw.githubusercontent.com/MisonL/Stream-Weaver/master/sw.sh" | sudo bash -s install-service no-menu; then
        success "测试2通过"
    else
        error "测试2失败"
        return 1
    fi
    
    success "所有测试通过"
}

# 执行测试
test_install