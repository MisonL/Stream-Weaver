# Stream Weaver 使用示例

## 一键安装

只需一句命令即可完成Stream Weaver的下载和安装，并立即启动交互式菜单：

```bash
curl -fsSL https://raw.githubusercontent.com/MisonL/Stream-Weaver/master/sw.sh | sudo bash
```

如果希望同时安装为系统服务，可以使用：

```bash
curl -fsSL https://raw.githubusercontent.com/MisonL/Stream-Weaver/master/sw.sh | sudo bash -s install-service
```

如果希望仅下载安装但不启动交互式菜单，可以使用：

```bash
curl -fsSL https://raw.githubusercontent.com/MisonL/Stream-Weaver/master/sw.sh | sudo bash -s -- no-menu
```

如果希望安装为系统服务但不启动交互式菜单，可以使用：

```bash
curl -fsSL https://raw.githubusercontent.com/MisonL/Stream-Weaver/master/sw.sh | sudo bash -s install-service no-menu
```

## 基础命令使用

| 功能 | 完整命令 | 缩写命令 | 说明 |
|------|----------|----------|------|
| 设置执行权限 | `chmod +x sw.sh` | 无 | 为脚本添加执行权限 |
| 配置代理服务器 | `sudo ./sw.sh config <IP> <端口>` | `sudo ./sw.sh c <IP> <端口>` | 设置远程代理服务器的IP和端口 |
| 启动流量转发 | `sudo ./sw.sh start` | `sudo ./sw.sh s` | 启动流量转发服务 |
| 停止流量转发 | `sudo ./sw.sh stop` | `sudo ./sw.sh x` | 停止流量转发服务 |
| 检查状态 | `./sw.sh status` | `./sw.sh t` | 检查流量转发的当前状态 |
| 重启服务 | `sudo ./sw.sh restart` | `sudo ./sw.sh r` | 重启流量转发服务 |
| 显示帮助 | `./sw.sh help` | `./sw.sh h` | 显示帮助信息 |
| 启动交互式菜单 | `./sw.sh menu` | `./sw.sh m` | 启动交互式菜单界面 |
| 测试境外网站访问 | `./sw.sh test` | 无 | 测试访问多个境外主流网站 |

## 豁免规则管理

| 功能 | 命令 | 说明 |
|------|------|------|
| 添加IP豁免 | `sudo ./sw.sh add-exemption ip <IP地址>` | 添加单个IP地址到豁免列表 |
| 添加域名豁免 | `sudo ./sw.sh add-exemption domain <域名>` | 添加单个域名到豁免列表 |
| 添加端口豁免 | `sudo ./sw.sh add-exemption port <端口号>` | 添加单个端口到豁免列表 |
| 批量添加豁免 | `sudo ./sw.sh add-exemption ip <IP1,IP2,IP3>` | 一次添加多个IP地址到豁免列表 |
| 列出所有豁免规则 | `./sw.sh list-exemptions` | 显示所有已配置的豁免规则 |
| 删除特定豁免规则 | `sudo ./sw.sh remove-exemption <类型> <值>` | 删除指定的豁免规则 |
| 删除所有豁免规则 | `sudo ./sw.sh remove-all-exemptions` | 清空所有豁免规则 |

## 系统重置选项

| 重置类型 | 命令 | 说明 |
|----------|------|------|
| 完全重置 | `sudo ./sw.sh reset` | 删除所有配置，包括豁免规则 |
| 部分重置 | `sudo ./sw.sh reset -k` | 重置系统但保留豁免规则 |
| 重置并卸载服务 | `sudo ./sw.sh reset -u` | 完全重置系统并卸载服务 |
| 部分重置并卸载服务 | `sudo ./sw.sh reset -k -u` | 保留豁免规则并卸载服务 |

## 服务管理命令

安装为系统服务后，可以使用systemctl命令管理服务：

| 功能 | 命令 | 说明 |
|------|------|------|
| 安装系统服务 | `sudo ./sw.sh install-service` | 将Stream Weaver安装为系统服务 |
| 启动服务 | `sudo systemctl start stream-weaver` | 启动Stream Weaver服务 |
| 停止服务 | `sudo systemctl stop stream-weaver` | 停止Stream Weaver服务 |
| 重启服务 | `sudo systemctl restart stream-weaver` | 重启Stream Weaver服务 |
| 查看服务状态 | `sudo systemctl status stream-weaver` | 显示Stream Weaver服务状态 |
| 卸载服务 | `sudo ./sw.sh uninstall-service` | 从系统中卸载Stream Weaver服务 |

安装服务后，还可以直接使用 `sw` 命令来控制流量转发，无需指定完整路径：

| 功能 | 命令 | 说明 |
|------|------|------|
| 配置代理服务器 | `sudo sw config <IP> <端口>` | 设置远程代理服务器的IP和端口 |
| 启动流量转发 | `sudo sw start` | 启动流量转发服务 |
| 停止流量转发 | `sudo sw stop` | 停止流量转发服务 |
| 重启流量转发 | `sudo sw restart` | 重启流量转发服务 |
| 检查状态 | `sw status` | 检查流量转发的当前状态 |
| 测试境外网站访问 | `sw test` | 测试访问多个境外主流网站 |
| 列出豁免规则 | `sw list-exemptions` | 显示所有已配置的豁免规则 |
| 添加豁免规则 | `sudo sw add-exemption <type> <value>` | 添加IP地址、域名或端口的豁免规则 |
| 删除豁免规则 | `sudo sw remove-exemption <type> <value>` | 删除指定的豁免规则 |

## 交互式菜单功能

交互式菜单提供以下功能选项：

| 菜单项 | 功能描述 |
|--------|----------|
| 1 | 检查详细状态 - 显示流量转发的详细状态信息 |
| 2 | 配置远程代理服务器 - 设置或修改远程Clash Verge代理服务器信息 |
| 3 | 启动流量转发 - 启动流量转发服务 |
| 4 | 停止流量转发 - 停止流量转发服务 |
| 5 | 重启流量转发 - 重启流量转发服务 |
| 6 | 添加自定义豁免规则 - 添加IP地址、域名或端口的豁免规则 |
| 7 | 删除自定义豁免规则 - 删除特定的豁免规则或所有规则 |
| 8 | 列出自定义豁免规则 - 显示所有已配置的豁免规则 |
| 9 | 测试境外网站访问 - 测试访问多个境外主流网站，验证代理是否正常工作 |
| 10 | 安装为系统服务 - 将Stream Weaver安装为系统服务 |
| 11 | 卸载系统服务 - 从系统中卸载Stream Weaver服务 |
| 12 | 重置系统到默认状态 - 完全重置系统或部分重置（保留豁免规则） |
| 13 | 显示帮助 - 显示帮助信息 |

交互式菜单会自动检测是否具有必要的权限，并在需要时提示您使用sudo。

## 高级使用技巧

### 自定义默认配置

在脚本中修改以下变量来自定义默认配置：

```bash
DEFAULT_PROXY_IP="192.168.1.100"  # 默认代理IP
DEFAULT_PROXY_PORT="7890"         # 默认代理端口
LOCAL_REDIR_PORT="12345"          # redsocks本地端口
```

### 手动编辑配置文件

配置文件位置：
- 代理配置：`/etc/clash_forward/config`
- 豁免规则：`/etc/clash_forward/exemptions`

可以直接编辑这些文件来修改配置，但需要重启服务才能生效。