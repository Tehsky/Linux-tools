#!/bin/bash

# 透明代理配置模块

configure_transparent_proxy() {
    while true; do
        clear
        echo -e "${CYAN}=== 透明代理配置 ===${NC}"
        echo
        echo "选择代理软件:"
        echo "1. 🦄 V2Ray/Xray (推荐)"
        echo "2. 🐱 Clash/Clash Meta"
        echo "3. 🔒 Shadowsocks + iptables"
        echo "4. 🌐 Trojan-Go"
        echo "5. 📡 Hysteria"
        echo "6. ⚡ SingBox"
        echo "7. 🔧 自定义透明代理规则"
        echo "8. 📊 查看代理状态"
        echo "9. 🗑️  卸载代理软件"
        echo "0. 返回主菜单"
        echo
        read -p "请选择 (0-9): " proxy_choice
        
        case $proxy_choice in
            1)
                install_v2ray_xray
                ;;
            2)
                install_clash
                ;;
            3)
                install_shadowsocks
                ;;
            4)
                install_trojan_go
                ;;
            5)
                install_hysteria
                ;;
            6)
                install_singbox
                ;;
            7)
                configure_custom_proxy
                ;;
            8)
                show_proxy_status
                ;;
            9)
                uninstall_proxy
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

install_v2ray_xray() {
    log "安装V2Ray/Xray透明代理..."
    
    if ! check_root; then
        return 1
    fi
    
    echo "选择安装版本:"
    echo "1. V2Ray (官方版本)"
    echo "2. Xray (增强版本，推荐)"
    read -p "请选择: " version_choice
    
    case "$version_choice" in
        1)
            install_v2ray_official
            ;;
        2)
            install_xray_official
            ;;
        *)
            error "无效选择"
            return 1
            ;;
    esac
    
    # 配置透明代理
    configure_v2ray_transparent_proxy
    
    read -p "按Enter键继续..."
}

install_v2ray_official() {
    log "安装V2Ray官方版本..."
    
    # 下载安装脚本
    curl -Ls https://install.direct/go.sh | bash
    
    # 启用服务
    systemctl enable v2ray
    systemctl start v2ray
    
    success "V2Ray安装完成"
}

install_xray_official() {
    log "安装Xray官方版本..."
    
    # 下载安装脚本
    curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash
    
    # 启用服务
    systemctl enable xray
    systemctl start xray
    
    success "Xray安装完成"
}

configure_v2ray_transparent_proxy() {
    log "配置V2Ray/Xray透明代理..."
    
    # 创建配置文件
    read -p "输入代理服务器地址: " server_address
    read -p "输入代理服务器端口: " server_port
    read -p "输入UUID: " uuid
    
    # 生成配置文件
    cat > /usr/local/etc/xray/config.json << EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "tag": "transparent",
            "port": 12345,
            "protocol": "dokodemo-door",
            "settings": {
                "network": "tcp,udp",
                "followRedirect": true
            },
            "streamSettings": {
                "sockopt": {
                    "tproxy": "tproxy"
                }
            }
        },
        {
            "tag": "socks",
            "port": 1080,
            "protocol": "socks",
            "settings": {
                "auth": "noauth",
                "udp": true
            }
        },
        {
            "tag": "http",
            "port": 8080,
            "protocol": "http"
        }
    ],
    "outbounds": [
        {
            "tag": "proxy",
            "protocol": "vmess",
            "settings": {
                "vnext": [
                    {
                        "address": "$server_address",
                        "port": $server_port,
                        "users": [
                            {
                                "id": "$uuid",
                                "security": "auto"
                            }
                        ]
                    }
                ]
            }
        },
        {
            "tag": "direct",
            "protocol": "freedom"
        },
        {
            "tag": "block",
            "protocol": "blackhole"
        }
    ],
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "ip": ["geoip:private"],
                "outboundTag": "direct"
            },
            {
                "type": "field",
                "ip": ["geoip:cn"],
                "outboundTag": "direct"
            },
            {
                "type": "field",
                "domain": ["geosite:cn"],
                "outboundTag": "direct"
            }
        ]
    }
}
EOF
    
    # 配置iptables规则
    configure_iptables_rules
    
    # 重启服务
    systemctl restart xray
    
    success "透明代理配置完成"
}

install_clash() {
    log "安装Clash透明代理..."
    
    if ! check_root; then
        return 1
    fi
    
    echo "选择Clash版本:"
    echo "1. Clash (原版)"
    echo "2. Clash Meta (增强版，推荐)"
    read -p "请选择: " clash_choice
    
    case "$clash_choice" in
        1)
            install_clash_original
            ;;
        2)
            install_clash_meta
            ;;
        *)
            error "无效选择"
            return 1
            ;;
    esac
    
    read -p "按Enter键继续..."
}

install_clash_original() {
    log "安装Clash原版..."
    
    # 下载Clash
    CLASH_VERSION=$(curl -s https://api.github.com/repos/Dreamacro/clash/releases/latest | grep 'tag_name' | cut -d\" -f4)
    ARCH=$(uname -m)
    
    case "$ARCH" in
        "x86_64")
            CLASH_ARCH="linux-amd64"
            ;;
        "aarch64")
            CLASH_ARCH="linux-arm64"
            ;;
        *)
            error "不支持的架构: $ARCH"
            return 1
            ;;
    esac
    
    wget -O /tmp/clash.gz "https://github.com/Dreamacro/clash/releases/download/${CLASH_VERSION}/clash-${CLASH_ARCH}-${CLASH_VERSION}.gz"
    gunzip /tmp/clash.gz
    chmod +x /tmp/clash
    mv /tmp/clash /usr/local/bin/clash
    
    # 创建配置目录
    mkdir -p /etc/clash
    
    # 创建systemd服务
    create_clash_service
    
    success "Clash安装完成"
}

install_clash_meta() {
    log "安装Clash Meta..."
    
    # 下载Clash Meta
    META_VERSION=$(curl -s https://api.github.com/repos/MetaCubeX/Clash.Meta/releases/latest | grep 'tag_name' | cut -d\" -f4)
    ARCH=$(uname -m)
    
    case "$ARCH" in
        "x86_64")
            META_ARCH="linux-amd64"
            ;;
        "aarch64")
            META_ARCH="linux-arm64"
            ;;
        *)
            error "不支持的架构: $ARCH"
            return 1
            ;;
    esac
    
    wget -O /tmp/clash-meta.gz "https://github.com/MetaCubeX/Clash.Meta/releases/download/${META_VERSION}/clash.meta-${META_ARCH}-${META_VERSION}.gz"
    gunzip /tmp/clash-meta.gz
    chmod +x /tmp/clash-meta
    mv /tmp/clash-meta /usr/local/bin/clash
    
    # 创建配置目录
    mkdir -p /etc/clash
    
    # 创建systemd服务
    create_clash_service
    
    success "Clash Meta安装完成"
}

create_clash_service() {
    cat > /etc/systemd/system/clash.service << 'EOF'
[Unit]
Description=Clash daemon
After=network.target

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/clash -d /etc/clash

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable clash
}

configure_iptables_rules() {
    log "配置iptables透明代理规则..."
    
    # 创建新的链
    iptables -t nat -N V2RAY
    iptables -t mangle -N V2RAY
    iptables -t mangle -N V2RAY_MARK
    
    # 直连的目标地址
    iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A V2RAY -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A V2RAY -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A V2RAY -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A V2RAY -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A V2RAY -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A V2RAY -d 240.0.0.0/4 -j RETURN
    
    # 重定向到透明代理端口
    iptables -t nat -A V2RAY -p tcp -j REDIRECT --to-ports 12345
    
    # 应用规则
    iptables -t nat -A OUTPUT -p tcp -j V2RAY
    
    # 保存规则
    save_iptables_rules
    
    success "iptables规则配置完成"
}

save_iptables_rules() {
    case "$PKG_MANAGER" in
        "pacman")
            iptables-save > /etc/iptables/iptables.rules
            systemctl enable iptables
            ;;
        "apt")
            iptables-save > /etc/iptables/rules.v4
            $INSTALL_CMD iptables-persistent
            ;;
        "dnf"|"yum")
            service iptables save
            ;;
    esac
}

show_proxy_status() {
    echo -e "${CYAN}=== 代理状态 ===${NC}"
    echo
    
    # 检查各种代理服务状态
    services=("v2ray" "xray" "clash" "shadowsocks-libev" "trojan-go" "hysteria" "sing-box")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${GREEN}✓ $service 运行中${NC}"
            systemctl status "$service" --no-pager -l | head -3
        elif systemctl list-unit-files | grep -q "$service"; then
            echo -e "${RED}✗ $service 已安装但未运行${NC}"
        fi
    done
    
    echo
    echo -e "${BLUE}网络连接测试:${NC}"
    
    # 测试代理连接
    if curl -s --connect-timeout 5 --socks5 127.0.0.1:1080 https://www.google.com &> /dev/null; then
        echo -e "${GREEN}✓ SOCKS5代理 (1080) 可用${NC}"
    else
        echo -e "${RED}✗ SOCKS5代理 (1080) 不可用${NC}"
    fi
    
    if curl -s --connect-timeout 5 --proxy 127.0.0.1:8080 https://www.google.com &> /dev/null; then
        echo -e "${GREEN}✓ HTTP代理 (8080) 可用${NC}"
    else
        echo -e "${RED}✗ HTTP代理 (8080) 不可用${NC}"
    fi
    
    read -p "按Enter键继续..."
}

# 其他代理软件安装函数（简化版）
install_shadowsocks() {
    log "Shadowsocks安装功能开发中..."
    read -p "按Enter键继续..."
}

install_trojan_go() {
    log "Trojan-Go安装功能开发中..."
    read -p "按Enter键继续..."
}

install_hysteria() {
    log "Hysteria安装功能开发中..."
    read -p "按Enter键继续..."
}

install_singbox() {
    log "SingBox安装功能开发中..."
    read -p "按Enter键继续..."
}

configure_custom_proxy() {
    log "自定义透明代理规则配置功能开发中..."
    read -p "按Enter键继续..."
}

uninstall_proxy() {
    if ! check_root; then
        return 1
    fi
    
    echo -e "${CYAN}=== 卸载代理软件 ===${NC}"
    echo
    warn "这将删除所有代理软件和配置文件"
    read -p "确定继续吗? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        return 0
    fi
    
    # 停止并禁用服务
    services=("v2ray" "xray" "clash" "shadowsocks-libev" "trojan-go" "hysteria" "sing-box")
    for service in "${services[@]}"; do
        systemctl stop "$service" 2>/dev/null || true
        systemctl disable "$service" 2>/dev/null || true
    done
    
    # 删除文件
    rm -rf /usr/local/bin/v2ray /usr/local/bin/xray /usr/local/bin/clash
    rm -rf /usr/local/etc/v2ray /usr/local/etc/xray /etc/clash
    rm -f /etc/systemd/system/v2ray.service /etc/systemd/system/xray.service /etc/systemd/system/clash.service
    
    # 清理iptables规则
    iptables -t nat -F V2RAY 2>/dev/null || true
    iptables -t nat -X V2RAY 2>/dev/null || true
    iptables -t mangle -F V2RAY 2>/dev/null || true
    iptables -t mangle -X V2RAY 2>/dev/null || true
    
    systemctl daemon-reload
    
    success "代理软件卸载完成"
    read -p "按Enter键继续..."
}
