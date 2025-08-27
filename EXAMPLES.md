# Stream Weaver 使用示例

## 常见使用场景

### 1. 基本使用流程

```bash
# 1. 设置执行权限
chmod +x sw.sh

# 2. 配置代理服务器
sudo ./sw.sh config 192.168.1.100 7890

# 3. 启动流量转发
sudo ./sw.sh start

# 4. 检查状态
./sw.sh status

# 5. 测试境外网站访问
./sw.sh test

# 6. 停止流量转发
sudo ./sw.sh stop
```

### 2. 使用命令缩写

```bash
# 启动流量转发
sudo ./sw.sh s

# 停止流量转发
sudo ./sw.sh x

# 检查状态
./sw.sh t

# 重启服务
sudo ./sw.sh r
```

### 3. 添加豁免规则

```bash
# 添加IP豁免
sudo ./sw.sh a ip 192.168.1.100

# 添加域名豁免
sudo ./sw.sh a domain google.com

# 添加端口豁免
sudo ./sw.sh a port 8080

# 批量添加IP豁免
sudo ./sw.sh a ip 192.168.1.100,192.168.1.101,192.168.1.102

# 重启服务使豁免规则生效
sudo ./sw.sh r
```

### 4. 管理豁免规则

```bash
# 列出所有豁免规则
./sw.sh l

# 删除特定豁免规则
sudo ./sw.sh rm ip 192.168.1.100

# 删除所有豁免规则
sudo ./sw.sh ra
```

### 5. 重置系统

```bash
# 完全重置系统（包括豁免规则）
sudo ./sw.sh reset

# 部分重置系统（保留豁免规则）
sudo ./sw.sh reset -k

# 完全重置系统并卸载服务
sudo ./sw.sh reset -u

# 部分重置系统并卸载服务（保留豁免规则）
sudo ./sw.sh reset -k -u
```

### 6. 使用交互式菜单

```bash
# 启动交互式菜单
./sw.sh m
```

### 7. 测试境外网站访问

```bash
# 测试境外网站访问
./sw.sh test
```

### 8. 安装为系统服务

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

# 安装服务后，可以直接使用sw命令
sudo sw config 192.168.1.100 7890  # 配置代理服务器
sudo sw start                      # 启动流量转发
sudo sw stop                       # 停止流量转发
sudo sw restart                    # 重启流量转发
sw status                          # 检查状态
sw test                            # 测试境外网站访问
sw list-exemptions                 # 列出豁免规则
sw add-exemption ip 192.168.1.100  # 添加IP豁免规则
sw remove-exemption ip 192.168.1.100  # 删除IP豁免规则
```

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

## 高级使用技巧

### 1. 自定义默认配置

在脚本中修改以下变量来自定义默认配置：

```bash
DEFAULT_PROXY_IP="192.168.1.100"  # 默认代理IP
DEFAULT_PROXY_PORT="7890"         # 默认代理端口
LOCAL_REDIR_PORT="12345"          # redsocks本地端口
```

### 2. 手动编辑配置文件

配置文件位置：
- 代理配置：`/etc/clash_forward/config`
- 豁免规则：`/etc/clash_forward/exemptions`

可以直接编辑这些文件来修改配置，但需要重启服务才能生效。

### 3. 使用系统级命令

安装服务后，您可以直接使用 `sw` 命令而无需指定完整路径：

```bash
# 配置代理服务器
sudo sw config 192.168.1.100 7890

# 启动流量转发
sudo sw start

# 停止流量转发
sudo sw stop

# 重启流量转发
sudo sw restart

# 检查状态
sw status

# 测试境外网站访问
sw test

# 管理豁免规则
sudo sw add-exemption ip 192.168.1.100
sw list-exemptions
sudo sw remove-exemption ip 192.168.1.100
```
