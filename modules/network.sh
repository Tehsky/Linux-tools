#!/bin/bash

# 网络配置查看和管理模块

show_network_config() {
    while true; do
        clear
        echo -e "${CYAN}=== 网络配置信息 ===${NC}"
        echo
        
        # 显示网络接口信息
        echo -e "${BLUE}📡 网络接口信息:${NC}"
        ip addr show | grep -E "^[0-9]+:|inet " | while read line; do
            if [[ $line =~ ^[0-9]+: ]]; then
                echo -e "${YELLOW}$line${NC}"
            else
                echo "  $line"
            fi
        done
        echo
        
        # 显示路由信息
        echo -e "${BLUE}🛣️  路由信息:${NC}"
        echo -e "${GREEN}默认网关:${NC}"
        ip route | grep default
        echo
        echo -e "${GREEN}路由表:${NC}"
        ip route show table main | head -10
        echo
        
        # 显示DNS信息
        echo -e "${BLUE}🌐 DNS配置:${NC}"
        if [[ -f /etc/resolv.conf ]]; then
            grep nameserver /etc/resolv.conf | while read line; do
                echo -e "${GREEN}$line${NC}"
            done
        fi
        echo
        
        # 显示网络连接状态
        echo -e "${BLUE}🔗 网络连接状态:${NC}"
        if command -v ss &> /dev/null; then
            echo -e "${GREEN}活动连接 (前10个):${NC}"
            ss -tuln | head -11
        elif command -v netstat &> /dev/null; then
            echo -e "${GREEN}活动连接 (前10个):${NC}"
            netstat -tuln | head -11
        fi
        echo
        
        # 网络测试
        echo -e "${BLUE}🔍 网络连通性测试:${NC}"
        test_network_connectivity
        echo
        
        # 显示菜单
        echo -e "${CYAN}=== 网络管理选项 ===${NC}"
        echo "1. 详细网络信息"
        echo "2. WiFi管理"
        echo "3. 网络诊断"
        echo "4. 防火墙状态"
        echo "5. 网络性能测试"
        echo "6. 修改DNS设置"
        echo "7. 网络配置备份/恢复"
        echo "0. 返回主菜单"
        echo
        read -p "请选择操作 (0-7): " choice
        
        case $choice in
            1)
                show_detailed_network_info
                ;;
            2)
                manage_wifi
                ;;
            3)
                network_diagnostics
                ;;
            4)
                show_firewall_status
                ;;
            5)
                network_performance_test
                ;;
            6)
                configure_dns
                ;;
            7)
                network_backup_restore
                ;;
            0)
                return 0
                ;;
            *)
                error "无效选择"
                sleep 2
                ;;
        esac
    done
}

test_network_connectivity() {
    # 测试本地连通性
    if ping -c 1 127.0.0.1 &> /dev/null; then
        echo -e "${GREEN}✓ 本地回环正常${NC}"
    else
        echo -e "${RED}✗ 本地回环异常${NC}"
    fi
    
    # 测试网关连通性
    GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
    if [[ -n "$GATEWAY" ]]; then
        if ping -c 1 -W 2 "$GATEWAY" &> /dev/null; then
            echo -e "${GREEN}✓ 网关连通 ($GATEWAY)${NC}"
        else
            echo -e "${RED}✗ 网关不通 ($GATEWAY)${NC}"
        fi
    fi
    
    # 测试DNS解析
    if nslookup google.com &> /dev/null; then
        echo -e "${GREEN}✓ DNS解析正常${NC}"
    else
        echo -e "${RED}✗ DNS解析异常${NC}"
    fi
    
    # 测试外网连通性
    if ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}✓ 外网连通${NC}"
    else
        echo -e "${RED}✗ 外网不通${NC}"
    fi
}

show_detailed_network_info() {
    clear
    echo -e "${CYAN}=== 详细网络信息 ===${NC}"
    echo
    
    # 网络接口详细信息
    echo -e "${BLUE}网络接口详细信息:${NC}"
    ip -s link show
    echo
    
    # ARP表
    echo -e "${BLUE}ARP表:${NC}"
    ip neigh show
    echo
    
    # 网络统计
    echo -e "${BLUE}网络统计:${NC}"
    cat /proc/net/dev
    echo
    
    read -p "按Enter键继续..."
}

manage_wifi() {
    echo -e "${CYAN}=== WiFi管理 ===${NC}"
    echo
    
    if command -v nmcli &> /dev/null; then
        echo "1. 扫描WiFi网络"
        echo "2. 查看已保存的WiFi"
        echo "3. 连接WiFi网络"
        echo "4. 断开WiFi连接"
        echo "5. 忘记WiFi网络"
        echo "0. 返回"
        echo
        read -p "请选择操作: " wifi_choice
        
        case $wifi_choice in
            1)
                nmcli device wifi list
                ;;
            2)
                nmcli connection show | grep wifi
                ;;
            3)
                read -p "输入WiFi名称: " ssid
                read -s -p "输入密码: " password
                echo
                nmcli device wifi connect "$ssid" password "$password"
                ;;
            4)
                nmcli device disconnect $(nmcli device | grep wifi | awk '{print $1}')
                ;;
            5)
                read -p "输入要忘记的WiFi名称: " ssid
                nmcli connection delete "$ssid"
                ;;
        esac
    else
        warn "未找到WiFi管理工具"
    fi
    
    read -p "按Enter键继续..."
}

network_diagnostics() {
    echo -e "${CYAN}=== 网络诊断 ===${NC}"
    echo
    
    log "运行网络诊断..."
    
    # 检查网络服务状态
    echo -e "${BLUE}网络服务状态:${NC}"
    if systemctl is-active --quiet NetworkManager; then
        echo -e "${GREEN}✓ NetworkManager运行中${NC}"
    elif systemctl is-active --quiet systemd-networkd; then
        echo -e "${GREEN}✓ systemd-networkd运行中${NC}"
    else
        echo -e "${RED}✗ 网络服务未运行${NC}"
    fi
    
    # 检查网络接口状态
    echo -e "${BLUE}网络接口状态:${NC}"
    ip link show | grep -E "^[0-9]+:" | while read line; do
        interface=$(echo $line | cut -d: -f2 | tr -d ' ')
        if echo $line | grep -q "UP"; then
            echo -e "${GREEN}✓ $interface 已启用${NC}"
        else
            echo -e "${RED}✗ $interface 已禁用${NC}"
        fi
    done
    
    read -p "按Enter键继续..."
}

show_firewall_status() {
    echo -e "${CYAN}=== 防火墙状态 ===${NC}"
    echo
    
    # 检查iptables
    if command -v iptables &> /dev/null; then
        echo -e "${BLUE}iptables规则:${NC}"
        iptables -L -n | head -20
        echo
    fi
    
    # 检查ufw
    if command -v ufw &> /dev/null; then
        echo -e "${BLUE}UFW状态:${NC}"
        ufw status verbose
        echo
    fi
    
    # 检查firewalld
    if command -v firewall-cmd &> /dev/null; then
        echo -e "${BLUE}firewalld状态:${NC}"
        firewall-cmd --state
        firewall-cmd --list-all
        echo
    fi
    
    read -p "按Enter键继续..."
}

network_performance_test() {
    echo -e "${CYAN}=== 网络性能测试 ===${NC}"
    echo
    
    # 延迟测试
    echo -e "${BLUE}延迟测试:${NC}"
    echo "测试到Google DNS (8.8.8.8):"
    ping -c 5 8.8.8.8
    echo
    
    # 带宽测试 (如果有speedtest-cli)
    if command -v speedtest-cli &> /dev/null; then
        echo -e "${BLUE}带宽测试:${NC}"
        speedtest-cli
    else
        echo -e "${YELLOW}安装speedtest-cli进行带宽测试:${NC}"
        case "$PKG_MANAGER" in
            "pacman") echo "sudo pacman -S speedtest-cli" ;;
            "emerge") echo "sudo emerge net-analyzer/speedtest-cli" ;;
            "apt") echo "sudo apt install speedtest-cli" ;;
            "dnf") echo "sudo dnf install speedtest-cli" ;;
            "yum") echo "sudo yum install speedtest-cli" ;;
            "zypper") echo "sudo zypper install speedtest-cli" ;;
        esac
    fi
    
    read -p "按Enter键继续..."
}

configure_dns() {
    if ! check_root; then
        return 1
    fi
    
    echo -e "${CYAN}=== DNS配置 ===${NC}"
    echo
    echo "当前DNS设置:"
    cat /etc/resolv.conf
    echo
    
    echo "选择DNS服务器:"
    echo "1. Google DNS (8.8.8.8, 8.8.4.4)"
    echo "2. Cloudflare DNS (1.1.1.1, 1.0.0.1)"
    echo "3. 阿里DNS (223.5.5.5, 223.6.6.6)"
    echo "4. 腾讯DNS (119.29.29.29, 182.254.116.116)"
    echo "5. 自定义DNS"
    echo "0. 取消"
    
    read -p "请选择: " dns_choice
    
    case $dns_choice in
        1)
            echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf
            ;;
        2)
            echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf
            ;;
        3)
            echo -e "nameserver 223.5.5.5\nnameserver 223.6.6.6" > /etc/resolv.conf
            ;;
        4)
            echo -e "nameserver 119.29.29.29\nnameserver 182.254.116.116" > /etc/resolv.conf
            ;;
        5)
            read -p "输入主DNS服务器: " dns1
            read -p "输入备用DNS服务器: " dns2
            echo -e "nameserver $dns1\nnameserver $dns2" > /etc/resolv.conf
            ;;
        0)
            return 0
            ;;
    esac
    
    success "DNS配置已更新"
    echo "新的DNS配置:"
    cat /etc/resolv.conf
    
    read -p "按Enter键继续..."
}

network_backup_restore() {
    echo -e "${CYAN}=== 网络配置备份/恢复 ===${NC}"
    echo
    echo "1. 备份网络配置"
    echo "2. 恢复网络配置"
    echo "3. 查看备份列表"
    echo "0. 返回"
    
    read -p "请选择操作: " backup_choice
    
    case $backup_choice in
        1)
            backup_network_config
            ;;
        2)
            restore_network_config
            ;;
        3)
            list_network_backups
            ;;
    esac
}

backup_network_config() {
    if ! check_root; then
        return 1
    fi
    
    BACKUP_DIR="/etc/network-backups"
    mkdir -p "$BACKUP_DIR"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/network_config_$TIMESTAMP.tar.gz"
    
    log "备份网络配置到 $BACKUP_FILE"
    
    tar -czf "$BACKUP_FILE" \
        /etc/resolv.conf \
        /etc/hosts \
        /etc/hostname \
        /etc/NetworkManager/ \
        /etc/netplan/ \
        /etc/network/ \
        2>/dev/null
    
    success "网络配置备份完成"
    read -p "按Enter键继续..."
}

restore_network_config() {
    if ! check_root; then
        return 1
    fi
    
    BACKUP_DIR="/etc/network-backups"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        error "备份目录不存在"
        return 1
    fi
    
    echo "可用的备份:"
    ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null || {
        error "没有找到备份文件"
        return 1
    }
    
    read -p "输入要恢复的备份文件名: " backup_file
    
    if [[ -f "$BACKUP_DIR/$backup_file" ]]; then
        warn "这将覆盖当前网络配置，确定继续吗? (y/N)"
        read -p "> " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            tar -xzf "$BACKUP_DIR/$backup_file" -C /
            success "网络配置恢复完成"
            warn "请重启网络服务或重启系统"
        fi
    else
        error "备份文件不存在"
    fi
    
    read -p "按Enter键继续..."
}

list_network_backups() {
    BACKUP_DIR="/etc/network-backups"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        echo "网络配置备份列表:"
        ls -lah "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "没有备份文件"
    else
        echo "备份目录不存在"
    fi
    
    read -p "按Enter键继续..."
}
