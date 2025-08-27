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

# 5. 停止流量转发
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
```

### 6. 使用交互式菜单

```bash
# 启动交互式菜单
./sw.sh m
```

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