#!/bin/bash

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
            if curl -s --connect-timeout 5 --max-time 10 "https://$website" >/dev/null 2>&1 || \
               curl -s --connect-timeout 5 --max-time 10 "http://$website" >/dev/null 2>&1; then
                echo "✅ 可访问"
                ((success_count++))
            else
                echo "❌ 无法访问"
            fi
        elif command -v wget >/dev/null 2>&1; then
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
}

# 执行测试功能
test_connectivity