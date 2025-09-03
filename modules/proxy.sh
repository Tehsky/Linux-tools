#!/bin/bash

# 透明代理配置模块

# 透明代理所需的依赖项
PROXY_DEPENDENCIES=(
    "curl"
    "wget"
    "iptables"
    "systemctl"
    "ip"
    "ss"
    "nslookup"
)

# 可选的高级工具
OPTIONAL_TOOLS=(
    "iproute2"
    "iptables-persistent"
    "resolvconf"
    "tun"
)

# 检查并安装依赖项
check_and_install_dependencies() {
    log "检查透明代理依赖项..."
    
    local missing_deps=()
    local missing_optional=()
    
    # 检查基础依赖
    for dep in "${PROXY_DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # 检查可选工具
    for tool in "${OPTIONAL_TOOLS[@]}"; do
        case "$tool" in
            "iproute2")
                if ! command -v ip &> /dev/null; then
                    missing_optional+=("$tool")
                fi
                ;;
            "iptables-persistent")
                if [[ "$PKG_MANAGER" == "apt" ]] && ! dpkg -l | grep -q iptables-persistent; then
                    missing_optional+=("$tool")
                fi
                ;;
            "resolvconf")
                if ! command -v resolvconf &> /dev/null && [[ ! -f /etc/resolv.conf ]]; then
                    missing_optional+=("$tool")
                fi
                ;;
            "tun")
                if [[ ! -c /dev/net/tun ]]; then
                    missing_optional+=("tun模块")
                fi
                ;;
        esac
    done
    
    # 安装缺失的基础依赖
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        warn "发现缺失的基础依赖: ${missing_deps[*]}"
        if check_root; then
            log "正在安装缺失的依赖项..."
            install_missing_dependencies "${missing_deps[@]}"
        else
            error "需要root权限安装依赖项"
            return 1
        fi
    else
        success "所有基础依赖项已满足"
    fi
    
    # 提示安装可选工具
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        warn "建议安装以下可选工具以获得更好体验: ${missing_optional[*]}"
        read -p "是否安装可选工具? (y/N): " install_optional
        if [[ "$install_optional" =~ ^[Yy]$ ]] && check_root; then
            install_optional_tools "${missing_optional[@]}"
        fi
    fi
    
    return 0
}

# 安装缺失的依赖项 - 增强版本，包含重试和备用方案
install_missing_dependencies() {
    local deps=("$@")
    local failed_deps=()
    
    for dep in "${deps[@]}"; do
        log "安装 $dep..."
        
        # 首次尝试安装
        if install_single_dependency "$dep"; then
            success "$dep 安装成功"
            continue
        fi
        
        # 如果首次安装失败，尝试更新包管理器缓存后重试
        warn "$dep 首次安装失败，尝试更新包管理器缓存..."
        update_package_manager_cache
        
        if install_single_dependency "$dep"; then
            success "$dep 重试安装成功"
            continue
        fi
        
        # 如果仍然失败，尝试备用安装方法
        warn "$dep 标准安装失败，尝试备用方法..."
        if install_dependency_alternative "$dep"; then
            success "$dep 备用方法安装成功"
            continue
        fi
        
        # 所有方法都失败
        error "$dep 所有安装方法都失败"
        failed_deps+=("$dep")
    done
    
    # 报告失败的依赖项
    if [[ ${#failed_deps[@]} -gt 0 ]]; then
        error "以下依赖项安装失败: ${failed_deps[*]}"
        echo "建议手动安装这些依赖项，或检查网络连接和包管理器配置"
        return 1
    fi
    
    return 0
}

# 安装单个依赖项
install_single_dependency() {
    local dep="$1"
    
    case "$dep" in
        "curl"|"wget")
            case "$PKG_MANAGER" in
                "pacman") timeout 300 $INSTALL_CMD "$dep" ;;
                "emerge") timeout 600 $INSTALL_CMD "net-misc/$dep" ;;
                "apt") timeout 300 $INSTALL_CMD "$dep" ;;
                "dnf"|"yum") timeout 300 $INSTALL_CMD "$dep" ;;
                "zypper") timeout 300 $INSTALL_CMD "$dep" ;;
            esac
            ;;
        "iptables")
            case "$PKG_MANAGER" in
                "pacman") timeout 300 $INSTALL_CMD iptables ;;
                "emerge") timeout 600 $INSTALL_CMD net-firewall/iptables ;;
                "apt") timeout 300 $INSTALL_CMD iptables ;;
                "dnf"|"yum") timeout 300 $INSTALL_CMD iptables ;;
                "zypper") timeout 300 $INSTALL_CMD iptables ;;
            esac
            ;;
        "ip"|"ss")
            case "$PKG_MANAGER" in
                "pacman") timeout 300 $INSTALL_CMD iproute2 ;;
                "emerge") timeout 600 $INSTALL_CMD sys-apps/iproute2 ;;
                "apt") timeout 300 $INSTALL_CMD iproute2 ;;
                "dnf"|"yum") timeout 300 $INSTALL_CMD iproute ;;
                "zypper") timeout 300 $INSTALL_CMD iproute2 ;;
            esac
            ;;
        "nslookup")
            case "$PKG_MANAGER" in
                "pacman") timeout 300 $INSTALL_CMD bind-tools ;;
                "emerge") timeout 600 $INSTALL_CMD net-dns/bind-tools ;;
                "apt") timeout 300 $INSTALL_CMD dnsutils ;;
                "dnf"|"yum") timeout 300 $INSTALL_CMD bind-utils ;;
                "zypper") timeout 300 $INSTALL_CMD bind-utils ;;
            esac
            ;;
    esac
    
    # 验证安装结果
    command -v "$dep" &> /dev/null
}

# 更新包管理器缓存
update_package_manager_cache() {
    log "更新包管理器缓存..."
    
    case "$PKG_MANAGER" in
        "pacman")
            timeout 300 pacman -Sy --noconfirm ;;
        "emerge")
            timeout 600 emerge --sync ;;
        "apt")
            timeout 300 apt update ;;
        "dnf")
            timeout 300 dnf makecache ;;
        "yum")
            timeout 300 yum makecache ;;
        "zypper")
            timeout 300 zypper refresh ;;
    esac
}

# 备用安装方法
install_dependency_alternative() {
    local dep="$1"
    
    case "$dep" in
        "curl")
            # 尝试从源码编译或使用静态二进制
            if command -v wget &> /dev/null; then
                log "尝试下载curl静态二进制文件..."
                wget -O /tmp/curl https://github.com/moparisthebest/static-curl/releases/latest/download/curl-amd64
                chmod +x /tmp/curl
                mv /tmp/curl /usr/local/bin/curl
                return $?
            fi
            ;;
        "wget")
            # 如果有curl，可以用curl下载wget
            if command -v curl &> /dev/null; then
                log "尝试使用curl下载wget..."
                curl -L -o /tmp/wget https://ftp.gnu.org/gnu/wget/wget-1.21.3.tar.gz
                # 这里应该编译安装，简化处理
                return 1
            fi
            ;;
        "iptables")
            # 检查是否系统内置
            if [[ -f /sbin/iptables ]]; then
                ln -sf /sbin/iptables /usr/local/bin/iptables
                return 0
            fi
            ;;
    esac
    
    return 1
}

# 安装可选工具
install_optional_tools() {
    local tools=("$@")
    
    for tool in "${tools[@]}"; do
        case "$tool" in
            "iproute2")
                log "安装 iproute2..."
                case "$PKG_MANAGER" in
                    "pacman") $INSTALL_CMD iproute2 ;;
                    "emerge") $INSTALL_CMD sys-apps/iproute2 ;;
                    "apt") $INSTALL_CMD iproute2 ;;
                    "dnf"|"yum") $INSTALL_CMD iproute ;;
                    "zypper") $INSTALL_CMD iproute2 ;;
                esac
                ;;
            "iptables-persistent")
                if [[ "$PKG_MANAGER" == "apt" ]]; then
                    log "安装 iptables-persistent..."
                    $INSTALL_CMD iptables-persistent
                fi
                ;;
            "resolvconf")
                log "安装 resolvconf..."
                case "$PKG_MANAGER" in
                    "pacman") $INSTALL_CMD openresolv ;;
                    "emerge") $INSTALL_CMD net-dns/openresolv ;;
                    "apt") $INSTALL_CMD resolvconf ;;
                    "dnf"|"yum") $INSTALL_CMD systemd-resolved ;;
                    "zypper") $INSTALL_CMD systemd ;;
                esac
                ;;
            "tun模块")
                log "配置TUN模块..."
                modprobe tun 2>/dev/null || warn "无法加载TUN模块，可能需要重新编译内核"
                echo 'tun' >> /etc/modules-load.d/tun.conf 2>/dev/null || true
                ;;
        esac
    done
}

# 配置终端代理环境变量
configure_terminal_proxy() {
    local proxy_type="$1"
    local proxy_host="${2:-127.0.0.1}"
    local socks_port="${3:-1080}"
    local http_port="${4:-8080}"
    
    log "配置终端代理环境变量..."
    
    # 创建代理配置文件
    local proxy_config="/etc/profile.d/proxy.sh"
    
    cat > "$proxy_config" << 'EOF'
#!/bin/bash
# 透明代理终端配置
# 由 Linux Toolkit 自动生成

# 代理管理函数
proxy_on() {
    export http_proxy="http://127.0.0.1:8080"
    export https_proxy="http://127.0.0.1:8080"
    export all_proxy="socks5://127.0.0.1:1080"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export ALL_PROXY="$all_proxy"
    export no_proxy="localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
    export NO_PROXY="$no_proxy"
    echo "代理已开启"
}

proxy_off() {
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy NO_PROXY
    echo "代理已关闭"
}

proxy_status() {
    if [[ -n "$http_proxy" ]]; then
        echo "代理状态: 开启"
        echo "HTTP代理: $http_proxy"
        echo "SOCKS代理: $all_proxy"
    else
        echo "代理状态: 关闭"
    fi
}

# 别名设置
alias px='proxy_on'
alias pxoff='proxy_off'
alias pxs='proxy_status'
EOF
    
    # 使用传入的参数更新配置文件
    sed -i "s/127.0.0.1:8080/${proxy_host}:${http_port}/g" "$proxy_config"
    sed -i "s/127.0.0.1:1080/${proxy_host}:${socks_port}/g" "$proxy_config"
    
    chmod +x "$proxy_config"
    
    # 为当前用户创建个人配置
    local user_config="$HOME/.proxy_config"
    cp "$proxy_config" "$user_config" 2>/dev/null || true
    
    success "终端代理配置完成"
    info "使用以下命令管理代理:"
    echo "  px      - 开启代理"
    echo "  pxoff   - 关闭代理"
    echo "  pxs     - 查看代理状态"
    echo ""
    echo "重新登录或执行 'source /etc/profile.d/proxy.sh' 使配置生效"
}

# 配置TUN模式透明代理
configure_tun_proxy() {
    local tun_interface="${1:-tun0}"
    local tun_ip="${2:-10.0.0.1}"
    local tun_netmask="${3:-255.255.255.0}"
    
    log "配置TUN模式透明代理..."
    
    if ! check_root; then
        return 1
    fi
    
    # 检查TUN模块
    if [[ ! -c /dev/net/tun ]]; then
        warn "TUN设备不存在，尝试加载模块..."
        modprobe tun || {
            error "无法加载TUN模块"
            return 1
        }
    fi
    
    # 创建TUN接口配置脚本
    cat > /usr/local/bin/setup-tun-proxy.sh << EOF
#!/bin/bash
# TUN代理设置脚本

# 创建TUN接口
ip tuntap add dev $tun_interface mode tun
ip addr add $tun_ip/24 dev $tun_interface
ip link set dev $tun_interface up

# 配置路由规则
ip route add default dev $tun_interface table 100
ip rule add fwmark 1 table 100

# 配置iptables规则
iptables -t mangle -N TUN_PROXY
iptables -t mangle -A TUN_PROXY -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A TUN_PROXY -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A TUN_PROXY -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A TUN_PROXY -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A TUN_PROXY -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A TUN_PROXY -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A TUN_PROXY -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A TUN_PROXY -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A TUN_PROXY -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -p tcp -j TUN_PROXY

echo "TUN代理设置完成"
EOF

    chmod +x /usr/local/bin/setup-tun-proxy.sh
    
    # 创建清理脚本
    cat > /usr/local/bin/cleanup-tun-proxy.sh << EOF
#!/bin/bash
# TUN代理清理脚本

# 清理iptables规则
iptables -t mangle -F TUN_PROXY 2>/dev/null || true
iptables -t mangle -X TUN_PROXY 2>/dev/null || true
iptables -t mangle -D OUTPUT -p tcp -j TUN_PROXY 2>/dev/null || true

# 清理路由规则
ip rule del fwmark 1 table 100 2>/dev/null || true
ip route del default dev $tun_interface table 100 2>/dev/null || true

# 删除TUN接口
ip link set dev $tun_interface down 2>/dev/null || true
ip tuntap del dev $tun_interface mode tun 2>/dev/null || true

echo "TUN代理清理完成"
EOF

    chmod +x /usr/local/bin/cleanup-tun-proxy.sh
    
    success "TUN模式配置完成"
    info "使用以下命令管理TUN代理:"
    echo "  启动: /usr/local/bin/setup-tun-proxy.sh"
    echo "  停止: /usr/local/bin/cleanup-tun-proxy.sh"
}

configure_transparent_proxy() {
    # 首先检查并安装依赖
    if ! check_and_install_dependencies; then
        error "依赖检查失败，无法继续"
        return 1
    fi
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
        echo "8. 🌐 配置TUN模式代理"
        echo "9. 💻 配置终端代理环境"
        echo "10. 📊 查看代理状态"
        echo "11. 🔍 检查依赖项"
        echo "12. 🗑️  卸载代理软件"
        echo "0. 返回主菜单"
        echo
        read -p "请选择 (0-12): " proxy_choice
        
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
                configure_tun_proxy
                ;;
            9)
                configure_terminal_proxy "manual"
                ;;
            10)
                show_proxy_status
                ;;
            11)
                check_and_install_dependencies
                read -p "按Enter键继续..."
                ;;
            12)
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
    
    # 检查依赖项
    if ! check_and_install_dependencies; then
        error "依赖检查失败，无法继续安装"
        return 1
    fi
    
    echo "选择安装版本:"
    echo "1. V2Ray (官方版本)"
    echo "2. Xray (增强版本，推荐)"
    read -p "请选择: " version_choice
    
    local service_name=""
    case "$version_choice" in
        1)
            install_v2ray_official
            service_name="v2ray"
            ;;
        2)
            install_xray_official
            service_name="xray"
            ;;
        *)
            error "无效选择"
            return 1
            ;;
    esac
    
    # 配置透明代理
    configure_v2ray_transparent_proxy
    
    # 配置终端代理环境
    read -p "是否配置终端代理环境变量? (y/N): " setup_terminal
    if [[ "$setup_terminal" =~ ^[Yy]$ ]]; then
        configure_terminal_proxy "$service_name" "127.0.0.1" "1080" "8080"
    fi
    
    # 验证安装
    if systemctl is-active --quiet "$service_name"; then
        success "$service_name 安装并启动成功"
        echo "代理端口:"
        echo "  SOCKS5: 127.0.0.1:1080"
        echo "  HTTP: 127.0.0.1:8080"
        echo "  透明代理: 127.0.0.1:12345"
    else
        warn "$service_name 已安装但未正常运行，请检查配置"
    fi
    
    read -p "按Enter键继续..."
}

install_v2ray_official() {
    log "安装V2Ray官方版本..."
    
    # 多个安装源尝试
    local install_sources=(
        "https://install.direct/go.sh"
        "https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh"
        "https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip"
    )
    
    for source in "${install_sources[@]}"; do
        log "尝试从源: $source"
        
        # 检查网络连接
        if ! curl -s --connect-timeout 10 "$source" > /dev/null; then
            warn "无法连接到 $source，尝试下一个源..."
            continue
        fi
        
        if [[ "$source" == *.sh ]]; then
            # 脚本安装方法
            if timeout 600 curl -Ls "$source" | bash; then
                log "V2Ray安装脚本执行成功"
                break
            else
                warn "安装脚本执行失败，尝试下一个源..."
                continue
            fi
        elif [[ "$source" == *.zip ]]; then
            # 手动下载安装
            if install_v2ray_manual "$source"; then
                log "V2Ray手动安装成功"
                break
            else
                warn "手动安装失败，尝试下一个源..."
                continue
            fi
        fi
    done
    
    # 检查安装结果
    if [[ ! -f /usr/local/bin/v2ray ]] && [[ ! -f /usr/bin/v2ray ]]; then
        error "V2Ray二进制文件未找到，所有安装方法都失败"
        return 1
    fi
    
    # 创建服务文件（如果不存在）
    create_v2ray_service
    
    # 启用并启动服务
    if systemctl enable v2ray && systemctl start v2ray; then
        success "V2Ray服务启动成功"
        return 0
    else
        warn "V2Ray服务启动失败，可能需要配置文件"
        return 0  # 安装成功，但服务未启动
    fi
}

install_xray_official() {
    log "安装Xray官方版本..."
    
    # 多个安装源尝试
    local install_sources=(
        "https://github.com/XTLS/Xray-install/raw/main/install-release.sh"
        "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
    )
    
    for source in "${install_sources[@]}"; do
        log "尝试从源: $source"
        
        # 检查网络连接
        if ! curl -s --connect-timeout 10 "$source" > /dev/null; then
            warn "无法连接到 $source，尝试下一个源..."
            continue
        fi
        
        if [[ "$source" == *.sh ]]; then
            # 脚本安装方法
            if timeout 600 curl -Ls "$source" | bash; then
                log "Xray安装脚本执行成功"
                break
            else
                warn "安装脚本执行失败，尝试下一个源..."
                continue
            fi
        elif [[ "$source" == *.zip ]]; then
            # 手动下载安装
            if install_xray_manual "$source"; then
                log "Xray手动安装成功"
                break
            else
                warn "手动安装失败，尝试下一个源..."
                continue
            fi
        fi
    done
    
    # 检查安装结果
    if [[ ! -f /usr/local/bin/xray ]] && [[ ! -f /usr/bin/xray ]]; then
        error "Xray二进制文件未找到，所有安装方法都失败"
        return 1
    fi
    
    # 创建服务文件（如果不存在）
    create_xray_service
    
    # 启用并启动服务
    if systemctl enable xray && systemctl start xray; then
        success "Xray服务启动成功"
        return 0
    else
        warn "Xray服务启动失败，可能需要配置文件"
        return 0  # 安装成功，但服务未启动
    fi
}

# V2Ray手动安装
install_v2ray_manual() {
    local download_url="$1"
    local temp_dir="/tmp/v2ray_install"
    
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # 下载文件
    if ! curl -L -o v2ray.zip "$download_url"; then
        return 1
    fi
    
    # 解压文件
    if ! unzip -q v2ray.zip; then
        return 1
    fi
    
    # 安装二进制文件
    chmod +x v2ray
    mv v2ray /usr/local/bin/
    
    # 创建配置目录
    mkdir -p /usr/local/etc/v2ray
    
    # 清理临时文件
    cd /
    rm -rf "$temp_dir"
    
    return 0
}

# Xray手动安装
install_xray_manual() {
    local download_url="$1"
    local temp_dir="/tmp/xray_install"
    
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # 下载文件
    if ! curl -L -o xray.zip "$download_url"; then
        return 1
    fi
    
    # 解压文件
    if ! unzip -q xray.zip; then
        return 1
    fi
    
    # 安装二进制文件
    chmod +x xray
    mv xray /usr/local/bin/
    
    # 创建配置目录
    mkdir -p /usr/local/etc/xray
    
    # 清理临时文件
    cd /
    rm -rf "$temp_dir"
    
    return 0
}

# 创建V2Ray服务文件
create_v2ray_service() {
    if [[ ! -f /etc/systemd/system/v2ray.service ]]; then
        cat > /etc/systemd/system/v2ray.service << 'EOF'
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray run -config /usr/local/etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
    fi
}

# 创建Xray服务文件
create_xray_service() {
    if [[ ! -f /etc/systemd/system/xray.service ]]; then
        cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
    fi
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
    
    # 检查依赖项
    if ! check_and_install_dependencies; then
        error "依赖检查失败，无法继续安装"
        return 1
    fi
    
    echo "选择Clash版本:"
    echo "1. Clash (原版)"
    echo "2. Clash Meta (增强版，推荐)"
    read -p "请选择: " clash_choice
    
    case "$clash_choice" in
        1)
            if install_clash_original; then
                success "Clash 原版安装完成"
            else
                error "Clash 原版安装失败"
                return 1
            fi
            ;;
        2)
            if install_clash_meta; then
                success "Clash Meta 安装完成"
            else
                error "Clash Meta 安装失败"
                return 1
            fi
            ;;
        *)
            error "无效选择"
            return 1
            ;;
    esac
    
    # 配置终端代理环境
    read -p "是否配置终端代理环境变量? (y/N): " setup_terminal
    if [[ "$setup_terminal" =~ ^[Yy]$ ]]; then
        configure_terminal_proxy "clash" "127.0.0.1" "7891" "7890"
    fi
    
    # 验证安装
    if systemctl is-active --quiet clash; then
        success "Clash 服务运行正常"
        echo "默认端口配置:"
        echo "  HTTP: 127.0.0.1:7890"
        echo "  SOCKS5: 127.0.0.1:7891"
        echo "  控制面板: http://127.0.0.1:9090/ui"
    else
        warn "Clash 服务未运行，可能需要配置文件"
        echo "请将配置文件放置到 /etc/clash/config.yaml"
    fi
    
    read -p "按Enter键继续..."
}

install_clash_original() {
    log "安装Clash原版..."
    
    local arch=$(uname -m)
    local clash_arch=""
    
    # 确定架构
    case "$arch" in
        "x86_64")
            clash_arch="linux-amd64"
            ;;
        "aarch64")
            clash_arch="linux-arm64"
            ;;
        "armv7l")
            clash_arch="linux-armv7"
            ;;
        *)
            error "不支持的架构: $arch"
            return 1
            ;;
    esac
    
    # 尝试多种方法获取版本信息
    local version=""
    local api_urls=(
        "https://api.github.com/repos/Dreamacro/clash/releases/latest"
        "https://github.com/Dreamacro/clash/releases/latest"
    )
    
    for api_url in "${api_urls[@]}"; do
        if [[ "$api_url" == *"api.github.com"* ]]; then
            version=$(timeout 30 curl -s "$api_url" | grep 'tag_name' | cut -d\" -f4 2>/dev/null)
        else
            # 解析HTML页面获取版本
            version=$(timeout 30 curl -s "$api_url" | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 2>/dev/null)
        fi
        
        if [[ -n "$version" ]]; then
            log "获取到Clash版本: $version"
            break
        fi
        warn "无法从 $api_url 获取版本信息，尝试下一个源..."
    done
    
    # 如果无法获取版本，使用备用版本
    if [[ -z "$version" ]]; then
        version="v1.18.0"
        warn "无法获取最新版本，使用备用版本: $version"
    fi
    
    # 尝试多种下载方法
    local download_success=false
    local download_urls=(
        "https://github.com/Dreamacro/clash/releases/download/${version}/clash-${clash_arch}-${version}.gz"
        "https://github.com/Dreamacro/clash/releases/download/${version}/clash-${clash_arch}.gz"
    )
    
    for download_url in "${download_urls[@]}"; do
        log "尝试下载: $download_url"
        
        # 尝试wget
        if command -v wget &> /dev/null; then
            if timeout 300 wget -O /tmp/clash.gz "$download_url" 2>/dev/null; then
                download_success=true
                break
            fi
        fi
        
        # 尝试curl
        if command -v curl &> /dev/null; then
            if timeout 300 curl -L -o /tmp/clash.gz "$download_url" 2>/dev/null; then
                download_success=true
                break
            fi
        fi
        
        warn "下载失败: $download_url"
    done
    
    if [[ "$download_success" != true ]]; then
        error "所有下载方法都失败"
        return 1
    fi
    
    # 验证下载的文件
    if [[ ! -f /tmp/clash.gz ]] || [[ ! -s /tmp/clash.gz ]]; then
        error "下载的文件无效或为空"
        return 1
    fi
    
    # 解压和安装
    if ! gunzip /tmp/clash.gz 2>/dev/null; then
        error "解压Clash文件失败"
        rm -f /tmp/clash.gz 2>/dev/null
        return 1
    fi
    
    if [[ ! -f /tmp/clash ]]; then
        error "解压后未找到Clash二进制文件"
        return 1
    fi
    
    chmod +x /tmp/clash
    if ! mv /tmp/clash /usr/local/bin/clash; then
        error "移动Clash二进制文件失败"
        return 1
    fi
    
    # 验证安装
    if [[ ! -f /usr/local/bin/clash ]]; then
        error "Clash二进制文件安装失败"
        return 1
    fi
    
    # 创建配置目录
    mkdir -p /etc/clash
    
    # 创建systemd服务
    create_clash_service
    
    success "Clash原版安装完成"
    return 0
}

install_clash_meta() {
    log "安装Clash Meta..."
    
    local arch=$(uname -m)
    local meta_arch=""
    
    # 确定架构
    case "$arch" in
        "x86_64")
            meta_arch="linux-amd64"
            ;;
        "aarch64")
            meta_arch="linux-arm64"
            ;;
        "armv7l")
            meta_arch="linux-armv7"
            ;;
        *)
            error "不支持的架构: $arch"
            return 1
            ;;
    esac
    
    # 尝试多种方法获取版本信息
    local version=""
    local api_urls=(
        "https://api.github.com/repos/MetaCubeX/Clash.Meta/releases/latest"
        "https://github.com/MetaCubeX/Clash.Meta/releases/latest"
    )
    
    for api_url in "${api_urls[@]}"; do
        if [[ "$api_url" == *"api.github.com"* ]]; then
            version=$(timeout 30 curl -s "$api_url" | grep 'tag_name' | cut -d\" -f4 2>/dev/null)
        else
            # 解析HTML页面获取版本
            version=$(timeout 30 curl -s "$api_url" | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 2>/dev/null)
        fi
        
        if [[ -n "$version" ]]; then
            log "获取到Clash Meta版本: $version"
            break
        fi
        warn "无法从 $api_url 获取版本信息，尝试下一个源..."
    done
    
    # 如果无法获取版本，使用备用版本
    if [[ -z "$version" ]]; then
        version="v1.17.0"
        warn "无法获取最新版本，使用备用版本: $version"
    fi
    
    # 尝试多种下载方法
    local download_success=false
    local download_urls=(
        "https://github.com/MetaCubeX/Clash.Meta/releases/download/${version}/clash.meta-${meta_arch}-${version}.gz"
        "https://github.com/MetaCubeX/Clash.Meta/releases/download/${version}/clash.meta-${meta_arch}.gz"
    )
    
    for download_url in "${download_urls[@]}"; do
        log "尝试下载: $download_url"
        
        # 尝试wget
        if command -v wget &> /dev/null; then
            if timeout 300 wget -O /tmp/clash-meta.gz "$download_url" 2>/dev/null; then
                download_success=true
                break
            fi
        fi
        
        # 尝试curl
        if command -v curl &> /dev/null; then
            if timeout 300 curl -L -o /tmp/clash-meta.gz "$download_url" 2>/dev/null; then
                download_success=true
                break
            fi
        fi
        
        warn "下载失败: $download_url"
    done
    
    if [[ "$download_success" != true ]]; then
        error "所有下载方法都失败"
        return 1
    fi
    
    # 验证下载的文件
    if [[ ! -f /tmp/clash-meta.gz ]] || [[ ! -s /tmp/clash-meta.gz ]]; then
        error "下载的文件无效或为空"
        return 1
    fi
    
    # 解压和安装
    if ! gunzip /tmp/clash-meta.gz 2>/dev/null; then
        error "解压Clash Meta文件失败"
        rm -f /tmp/clash-meta.gz 2>/dev/null
        return 1
    fi
    
    if [[ ! -f /tmp/clash-meta ]]; then
        error "解压后未找到Clash Meta二进制文件"
        return 1
    fi
    
    chmod +x /tmp/clash-meta
    if ! mv /tmp/clash-meta /usr/local/bin/clash; then
        error "移动Clash Meta二进制文件失败"
        return 1
    fi
    
    # 验证安装
    if [[ ! -f /usr/local/bin/clash ]]; then
        error "Clash Meta二进制文件安装失败"
        return 1
    fi
    
    # 创建配置目录
    mkdir -p /etc/clash
    
    # 创建systemd服务
    create_clash_service
    
    success "Clash Meta安装完成"
    return 0
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
