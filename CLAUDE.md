# CLAUDE.md

此文件为Claude Code (claude.ai/code) 提供本代码仓库的工作指导。

## 概述

Stream Weaver（流织者）是一个Linux流量转发工具，通过redsocks和iptables将本地系统流量透明转发到远程Clash Verge代理服务器。专为无需应用配置的透明代理而设计。

## 架构

### 核心组件

- **sw.sh**: 主bash脚本（约93KB），实现所有功能
- **透明代理流程**: 本地应用 → iptables NAT → redsocks → 远程Clash Verge → 目标服务器
- **双栈支持**: 通过iptables/ip6tables规则支持IPv4和IPv6
- **智能路由**: 自动豁免本地和私有网络，避免循环转发

### 关键技术

- **redsocks**: SOCKS5代理重定向器，用于透明代理
- **iptables/ip6tables**: 用于流量重定向的NAT规则
- **systemd**: 服务管理（可选安装）
- **Bash**: 主要实现语言，具有全面的错误处理

## 已知问题修复

### GitHub一键安装问题（已修复）
- **系统检测错误**: 修复了detect_system()返回"redhat"但install_dependencies()期望具体值（"fedora"、"centos"）的case语句不匹配问题
- **交互式菜单调用**: 通过使用保存的脚本执行修复了管道模式下interactive_menu函数可见性问题
- **脚本保存逻辑**: 增强了save_script()函数以正确处理curl-to-bash场景中的内容保存

## 开发命令

### 基本操作
```bash
# 流量转发控制
sudo ./sw.sh start          # 启动流量转发
sudo ./sw.sh stop           # 停止流量转发
sudo ./sw.sh restart        # 重启流量转发
sudo ./sw.sh status         # 检查详细状态

# 配置
sudo ./sw.sh config <IP> <PORT>    # 设置代理服务器
sudo ./sw.sh menu           # 交互式菜单
sudo ./sw.sh test           # 测试境外网站连通性

# 豁免管理
sudo ./sw.sh add-exemption ip 192.168.1.100        # 添加IP豁免
sudo ./sw.sh add-exemption domain example.com      # 添加域名豁免
sudo ./sw.sh add-exemption port 8080               # 添加端口豁免
sudo ./sw.sh remove-exemption ip 192.168.1.100     # 删除特定豁免
sudo ./sw.sh remove-all-exemptions                 # 清除所有豁免
sudo ./sw.sh list-exemptions                       # 列出所有豁免
```

### 系统服务管理
```bash
# 安装为系统服务
sudo ./sw.sh install-service

# 安装后可直接使用sw命令
sudo sw config 192.168.1.100 7890
sudo sw start
sudo sw stop
sudo sw restart
sw status
sw test

# 卸载服务
sudo ./sw.sh uninstall-service
```

### 重置操作
```bash
sudo ./sw.sh reset                          # 完全重置（删除所有配置）
sudo ./sw.sh reset -k                       # 部分重置（保留豁免规则）
sudo ./sw.sh reset -u                       # 重置并卸载服务
sudo ./sw.sh reset -k -u                    # 部分重置并卸载服务
```

### 命令别名
- `start` → `s`
- `stop` → `x`
- `restart` → `r`
- `status` → `t`
- `config` → `c`
- `add-exemption` → `a`
- `remove-exemption` → `rm`
- `remove-all-exemptions` → `ra`
- `list-exemptions` → `l`
- `menu` → `m`

## 文件结构

- **sw.sh**: 主可执行脚本（93KB）
- **README.md**: 中文综合文档
- **EXAMPLES.md**: 使用示例和场景
- **LICENSE**: MIT许可证

## 配置文件

- **/etc/clash_forward/config**: 代理服务器配置
- **/etc/clash_forward/exemptions**: 自定义豁免规则
- **/etc/redsocks.conf**: redsocks配置（自动生成）
- **/etc/systemd/system/stream-weaver.service**: 系统服务文件（可选）

## 重要说明

1. **Root权限**: 大多数命令需要`sudo`用于iptables/systemd操作
2. **网络影响**: 脚本修改系统iptables规则并启用IP转发
3. **自动清理**: 包含错误恢复和自动规则恢复
4. **IPv6支持**: 如果可用，检测并配置ip6tables
5. **服务模式**: 可选的systemd集成，用于持久操作
6. **测试**: 内置10个主要境外网站的连通性测试

## 开发背景

这是一个专注于系统级网络的单文件bash实现。更改应保持与Ubuntu/Debian和CentOS/RedHat系统的兼容性，优雅处理边界情况，并保留现有的用户界面模式。

### 代码结构

- **管道模式检测**: 脚本使用`${BASH_SOURCE[0]}`检测是否通过`curl | bash`运行
- **双主函数**: 管道模式（顶部）和普通执行（底部）的独立主函数
- **系统检测**: 使用包管理器检测（apt-get/dnf/yum）进行系统识别
- **错误处理**: 全面的日志记录，带颜色输出和严格模式（`set -euo pipefail`）

### 测试命令

```bash
# 本地测试一键安装
cat sw.sh | sudo bash                    # 基础安装
cat sw.sh | sudo bash -s install-service # 带服务安装

# 测试脚本功能
sudo ./sw.sh test                        # 运行连通性测试
sudo ./sw.sh status                      # 检查详细状态
bash -n sw.sh                           # 语法检查
```

### 关键函数

- **detect_system()**: 确定操作系统类型以进行包管理
- **save_script()**: 处理curl-to-bash安装场景
- **interactive_menu()**: 主用户界面（定义在第~1737行）
- **install_dependencies()**: 系统特定的包安装
- **check_root()**: 权限验证，特别处理管道模式