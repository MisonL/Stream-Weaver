<div align="center">

# 🌐 Stream Weaver - 流织者

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

Stream Weaver（流织者）是一个将本地Linux系统流量透明转发到远程Clash Verge代理服务器的工具。通过redsocks和iptables实现，像织布一样巧妙地编织和引导所有TCP流量通过远程代理进行路由。

## 📖 功能简介

- **透明转发**：无需配置应用程序，自动转发所有TCP流量
- **双栈支持**：同时支持IPv4和IPv6流量转发
- **智能路由**：自动跳过本地和私有网络，避免循环转发
- **自定义豁免**：支持IP地址、域名、端口的豁免规则
- **批量添加**：支持逗号分隔一次添加多个豁免规则
- **系统兼容**：兼容Ubuntu/Debian和CentOS/RedHat系列系统
- **命令缩写**：支持命令行参数缩写，提高使用便捷性
- **灵活重置**：支持完全重置和部分重置（保留豁免规则）

## 🚀 快速开始

### 1. 设置执行权限

```bash
chmod +x sw.sh
```

### 2. 配置代理服务器

```bash
sudo ./sw.sh config <远程服务器IP> <端口>
```

默认配置：
- 远程服务器IP: 192.168.1.100
- 端口: 7890 (Clash Verge默认混合代理端口)

> **提示**：强烈建议使用Clash Verge的**混合代理端口**（默认7890），支持自动识别协议（HTTP/HTTPS/SOCKS），兼容性更好。

### 3. 启动流量转发

```bash
sudo ./sw.sh start
```

### 4. 检查状态

```bash
./sw.sh status
```

### 5. 测试境外网站访问

```bash
./sw.sh test
```

该命令将测试访问多个境外主流网站，验证代理是否正常工作。

### 6. 停止流量转发

```bash
sudo ./sw.sh stop
```

### 7. 安装为系统服务（可选）

如果您希望将Stream Weaver安装为系统服务，可以直接使用systemctl命令控制：

```bash
# 安装为系统服务
sudo ./sw.sh install-service

# 启动服务
sudo systemctl start stream-weaver

# 停止服务
sudo systemctl stop stream-weaver

# 重启服务
sudo systemctl restart stream-weaver

# 查看服务状态
sudo systemctl status stream-weaver

# 卸载服务
sudo ./sw.sh uninstall-service
```

安装服务后，您还可以直接使用 `sw` 命令来控制流量转发，无需指定完整路径：

```bash
# 安装服务后，可以直接使用sw命令
sudo sw config 192.168.1.100 7890  # 配置代理服务器
sudo sw start                      # 启动流量转发
sudo sw stop                       # 停止流量转发
sudo sw restart                    # 重启流量转发
sw status                          # 检查状态
sw test                            # 测试境外网站访问
sw list-exemptions                 # 列出豁免规则
```

## 📋 命令行参数

| 命令 | 缩写 | 说明 | 权限 | 示例 |
|------|------|------|------|------|
| `start` | `s` | 启动流量转发 | root | `sudo ./sw.sh s` |
| `stop` | `x` | 停止流量转发 | root | `sudo ./sw.sh x` |
| `status` | `t` | 检查状态 | 无 | `./sw.sh t` |
| `restart` | `r` | 重启服务 | root | `sudo ./sw.sh r` |
| `config <ip> <port>` | `c` | 设置代理配置 | root | `sudo ./sw.sh c 192.168.1.100 7890` |
| `add-exemption <type> <value>` | `a` | 添加豁免规则 | root | `sudo ./sw.sh a ip 192.168.1.100` |
| `remove-exemption <type> <value>` | `rm` | 删除豁免规则 | root | `sudo ./sw.sh rm ip 192.168.1.100` |
| `remove-all-exemptions` | `ra` | 删除所有豁免规则 | root | `sudo ./sw.sh ra` |
| `list-exemptions` | `l` | 列出豁免规则 | 无 | `./sw.sh l` |
| `test` | 无 | 测试境外网站访问 | 无 | `./sw.sh test` |
| `install-service` | 无 | 安装为系统服务 | root | `sudo ./sw.sh install-service` |
| `uninstall-service` | 无 | 卸载系统服务 | root | `sudo ./sw.sh uninstall-service` |
| `reset` | 无 | 完全重置系统 | root | `sudo ./sw.sh reset` |
| `reset -k` | 无 | 部分重置(保留豁免规则) | root | `sudo ./sw.sh reset -k` |
| 无参数 | `m` | 启动交互式菜单 | 无 | `./sw.sh m` |
| `help` | `h` | 显示帮助信息 | 无 | `./sw.sh h` |

## 🛡️ 自定义豁免规则

支持三种类型的豁免规则，使特定流量不通过代理：

### 1. IP地址豁免

```bash
# 单个IP
sudo ./sw.sh a ip 192.168.1.100

# 多个IP（逗号分隔）
sudo ./sw.sh a ip 192.168.1.100,192.168.1.101
```

### 2. 域名豁免

```bash
# 单个域名
sudo ./sw.sh a domain example.com

# 多个域名
sudo ./sw.sh a domain example.com,google.com
```

### 3. 端口豁免

```bash
# 单个端口
sudo ./sw.sh a port 8080

# 多个端口
sudo ./sw.sh a port 8080,9090,3306
```

### 豁免规则管理

```bash
# 列出所有规则
./sw.sh l

# 删除特定规则
sudo ./sw.sh rm ip 192.168.1.100

# 删除所有规则
sudo ./sw.sh ra
```

> **注意**：添加或删除豁免规则后，需要重启服务才能生效：`sudo ./sw.sh r`

## ⚡ 技术实现

### 工作流程

本地应用程序 → iptables NAT → redsocks → 远程Clash Verge代理 → 目标服务器

### Clash Verge端口设置

Clash Verge提供多种代理端口类型：

1. **混合代理端口**（推荐，默认7890）
   - 自动识别HTTP/HTTPS/SOCKS协议
   - 最佳兼容性和稳定性

2. 其他端口类型（不推荐）
   - SOCKS5端口（默认7891）
   - HTTP代理端口（默认7892）
   - Redirect端口（默认7893）

设置方法：打开Clash Verge设置 → 端口设置 → 启用"混合代理端口"

## 🖥️ 系统兼容性

支持的Linux发行版：
- **Ubuntu/Debian**：18.04/20.04/22.04/24.04, Debian 9/10/11/12
- **CentOS/RedHat**：CentOS 7/8, RHEL 7/8/9, Rocky Linux 8/9, AlmaLinux 8/9

自动适配系统包管理器和服务管理方式。

## ⚠️ 使用须知

1. 只代理TCP流量，UDP流量不受影响
2. 自动跳过本地和私有网络流量
3. 首次运行会自动安装必要依赖包
4. 确保远程Clash Verge服务器正在运行
5. 添加豁免规则后需重启服务生效
6. 重置功能支持保留或删除豁免规则

## 🔍 故障排除

### 常见问题解决

1. **检查状态**：`./sw.sh t`
2. **检查代理连通性**：`nc -z 192.168.1.100 7890`
3. **查看服务日志**：`sudo journalctl -u redsocks -f`
4. **恢复iptables规则**：`sudo iptables-restore < /etc/iptables/backup/rules.v4.last`
5. **重置系统**：`sudo ./sw.sh reset`

状态检查现在会显示服务安装状态：
- Stream Weaver服务安装状态
- 系统级命令'sw'安装状态
- redsocks服务运行状态
- 流量转发状态
- IP转发状态等

### 配置文件位置

- 代理配置：`/etc/clash_forward/config`
- 豁免规则：`/etc/clash_forward/exemptions`
- redsocks配置：`/etc/redsocks.conf`
- iptables备份：`/etc/iptables/backup/`

## 🔧 高级配置

### 自定义默认设置

```
# 脚本内变量
DEFAULT_PROXY_IP="192.168.1.100"  # 默认代理IP
DEFAULT_PROXY_PORT="7890"         # 默认代理端口
LOCAL_REDIR_PORT="12345"          # redsocks本地端口
```

### 配置文件格式

```
# /etc/clash_forward/config
PROXY_IP="192.168.1.100"
PROXY_PORT="7890"

# /etc/clash_forward/exemptions
# 格式: 类型=값
ip=192.168.1.100
domain=example.com
port=8080
```

### 重置选项

系统重置支持多种选项：
- 完全重置：`sudo ./sw.sh reset`（删除所有配置，包括豁免规则）
- 部分重置：`sudo ./sw.sh reset -k`（保留豁免规则）
- 重置并卸载服务：`sudo ./sw.sh reset -u`（完全重置并卸载服务）
- 部分重置并卸载服务：`sudo ./sw.sh reset -k -u`（保留豁免规则并卸载服务）

在交互式菜单中，重置选项提供以下选择：
1. 完全重置（删除所有配置，包括豁免规则）
2. 部分重置（保留豁免规则）
3. 完全重置并卸载服务（删除所有配置并卸载Stream Weaver服务）
4. 部分重置并卸载服务（保留豁免规则并卸载Stream Weaver服务）

## 📄 许可证

本项目采用MIT许可证，详情请参见 [LICENSE](LICENSE) 文件。

## 📘 使用示例

更多使用示例请参见 [EXAMPLES.md](EXAMPLES.md) 文件。

## 交互式菜单详解

Stream Weaver提供了一个直观的交互式菜单界面，方便用户进行各种操作。要启动交互式菜单，只需运行：

```bash
./sw.sh menu
# 或者使用简写
./sw.sh m
```

交互式菜单包含以下功能选项：

1. **检查详细状态** - 显示流量转发的详细状态信息
2. **配置远程代理服务器** - 设置或修改远程Clash Verge代理服务器信息
3. **启动流量转发** - 启动流量转发服务
4. **停止流量转发** - 停止流量转发服务
5. **重启流量转发** - 重启流量转发服务
6. **添加自定义豁免规则** - 添加IP地址、域名或端口的豁免规则
7. **删除自定义豁免规则** - 删除特定的豁免规则或所有规则
8. **列出自定义豁免规则** - 显示所有已配置的豁免规则
9. **测试境外网站访问** - 测试访问多个境外主流网站，验证代理是否正常工作
10. **安装为系统服务** - 将Stream Weaver安装为系统服务
11. **卸载系统服务** - 从系统中卸载Stream Weaver服务
12. **重置系统到默认状态** - 完全重置系统或部分重置（保留豁免规则）
13. **显示帮助** - 显示帮助信息

交互式菜单会自动检测是否具有必要的权限，并在需要时提示您使用sudo。

### 7. 安装为系统服务

```
# 安装为系统服务
sudo ./sw.sh install-service

# 启动服务
sudo systemctl start stream-weaver

# 停止服务
sudo systemctl stop stream-weaver

# 重启服务
sudo systemctl restart stream-weaver

# 查看服务状态
sudo systemctl status stream-weaver

# 卸载服务
sudo ./sw.sh uninstall-service

# 安装服务后，可以直接使用sw命令
sudo sw config 192.168.1.100 7890  # 配置代理服务器
sudo sw start                      # 启动流量转发
sudo sw stop                       # 停止流量转发
sudo sw restart                    # 重启流量转发
sw status                          # 检查状态
sw test                            # 测试境外网站访问
sw list-exemptions                 # 列出豁免规则
```

## 🎛️ 交互式菜单使用

除了命令行参数方式，Stream Weaver还提供了一个直观的交互式菜单界面，方便用户进行各种操作：

```bash
./sw.sh menu
# 或者简写为
./sw.sh m
```

在交互式菜单中，您可以：
- 检查详细状态
- 配置远程代理服务器
- 启动/停止/重启流量转发
- 添加/删除/列出自定义豁免规则
- 测试境外网站访问
- 安装/卸载系统服务
- 重置系统到默认状态
- 查看帮助信息

交互式菜单会自动检测是否具有必要的权限，并在需要时提示您使用sudo。
./sw.sh m
```

在交互式菜单中，您可以：
- 检查详细状态
- 配置远程代理服务器
- 启动/停止/重启流量转发
- 添加/删除/列出自定义豁免规则
- 测试境外网站访问
- 安装/卸载系统服务
- 重置系统到默认状态
- 查看帮助信息

交互式菜单会自动检测是否具有必要的权限，并在需要时提示您使用sudo。
