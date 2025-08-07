#!/bin/bash

# Docker安装和配置模块

install_docker() {
    log "安装Docker并配置加速器..."
    
    if ! check_root; then
        return 1
    fi
    
    # 检查Docker是否已安装
    if command -v docker &> /dev/null; then
        warn "Docker已安装，版本: $(docker --version)"
        read -p "是否重新配置Docker? (y/N): " reconfigure
        if [[ "$reconfigure" != "y" && "$reconfigure" != "Y" ]]; then
            return 0
        fi
    fi
    
    case "$PKG_MANAGER" in
        "pacman")
            log "在Arch Linux上安装Docker..."
            $INSTALL_CMD docker docker-compose
            systemctl enable docker
            systemctl start docker
            ;;
        "emerge")
            log "在Gentoo上安装Docker..."
            # 检查是否需要添加USE标志
            if ! grep -q "docker" /etc/portage/make.conf 2>/dev/null; then
                warn "建议在/etc/portage/make.conf中添加Docker相关USE标志"
                echo "USE=\"\${USE} docker\"" >> /etc/portage/make.conf
            fi

            # 安装Docker
            $INSTALL_CMD app-containers/docker app-containers/docker-compose

            # 启用服务
            rc-update add docker default
            rc-service docker start
            ;;
        "apt")
            log "在Ubuntu/Debian上安装Docker..."
            # 卸载旧版本
            apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # 安装依赖
            $INSTALL_CMD apt-transport-https ca-certificates curl gnupg lsb-release
            
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 添加Docker仓库
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            $UPDATE_CMD
            $INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            systemctl enable docker
            systemctl start docker
            ;;
        "dnf")
            log "在Fedora上安装Docker..."
            $INSTALL_CMD dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            $INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            systemctl enable docker
            systemctl start docker
            ;;
        "yum")
            log "在CentOS/RHEL上安装Docker..."
            $INSTALL_CMD yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            systemctl enable docker
            systemctl start docker
            ;;
        "zypper")
            log "在openSUSE上安装Docker..."
            $INSTALL_CMD docker docker-compose
            systemctl enable docker
            systemctl start docker
            ;;
    esac
    
    # 添加当前用户到docker组
    if [[ -n "$SUDO_USER" ]]; then
        usermod -aG docker "$SUDO_USER"
        log "已将用户 $SUDO_USER 添加到docker组"
        warn "请重新登录以使组权限生效"
    fi

    success "Docker安装完成!"

    # 测试Docker
    log "测试Docker安装..."
    if docker run --rm hello-world &> /dev/null; then
        success "Docker测试成功!"
    else
        warn "Docker测试失败，请检查安装"
    fi

    echo
    # 询问是否配置加速器
    read -p "是否配置Docker镜像加速器? (y/N): " configure_mirrors
    if [[ "$configure_mirrors" =~ ^[Yy]$ ]]; then
        configure_docker_mirrors
    else
        log "跳过镜像加速器配置"
    fi

    read -p "按Enter键继续..."
}

configure_docker_mirrors() {
    echo
    echo -e "${CYAN}=== Docker镜像加速器配置 ===${NC}"
    echo
    echo "选择镜像加速器:"
    echo "1) 中科大镜像 (推荐)"
    echo "2) 网易镜像"
    echo "3) 百度镜像"
    echo "4) 腾讯云镜像"
    echo "5) 阿里云镜像 (需要注册获取专属地址)"
    echo "6) 多个镜像组合 (推荐)"
    echo "7) 自定义镜像地址"
    echo "0) 跳过配置"
    echo

    read -p "请选择 (0-7): " mirror_choice

    case $mirror_choice in
        1)
            MIRRORS='["https://docker.mirrors.ustc.edu.cn"]'
            MIRROR_NAME="中科大镜像"
            ;;
        2)
            MIRRORS='["https://hub-mirror.c.163.com"]'
            MIRROR_NAME="网易镜像"
            ;;
        3)
            MIRRORS='["https://mirror.baidubce.com"]'
            MIRROR_NAME="百度镜像"
            ;;
        4)
            MIRRORS='["https://ccr.ccs.tencentyun.com"]'
            MIRROR_NAME="腾讯云镜像"
            ;;
        5)
            echo
            warn "阿里云镜像需要注册获取专属地址"
            info "请访问: https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors"
            read -p "请输入您的阿里云镜像地址 (如: https://xxxxxx.mirror.aliyuncs.com): " aliyun_mirror
            if [[ -n "$aliyun_mirror" ]]; then
                MIRRORS="[\"$aliyun_mirror\"]"
                MIRROR_NAME="阿里云镜像"
            else
                warn "未输入镜像地址，跳过配置"
                return
            fi
            ;;
        6)
            MIRRORS='[
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com",
        "https://mirror.baidubce.com",
        "https://ccr.ccs.tencentyun.com"
    ]'
            MIRROR_NAME="多个镜像组合"
            ;;
        7)
            echo
            read -p "请输入自定义镜像地址 (如: https://your-mirror.com): " custom_mirror
            if [[ -n "$custom_mirror" ]]; then
                MIRRORS="[\"$custom_mirror\"]"
                MIRROR_NAME="自定义镜像"
            else
                warn "未输入镜像地址，跳过配置"
                return
            fi
            ;;
        0)
            log "跳过镜像加速器配置"
            return
            ;;
        *)
            error "无效选择，跳过配置"
            return
            ;;
    esac

    log "配置 $MIRROR_NAME..."

    # 创建docker配置目录
    mkdir -p /etc/docker

    # 备份现有配置
    if [[ -f /etc/docker/daemon.json ]]; then
        cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
        log "已备份现有配置"
    fi

    # 配置镜像源
    cat > /etc/docker/daemon.json << EOF
{
    "registry-mirrors": $MIRRORS,
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ],
    "live-restore": true
}
EOF

    # 重启Docker服务
    log "重启Docker服务..."
    systemctl daemon-reload
    systemctl restart docker

    # 验证配置
    sleep 2
    if systemctl is-active --quiet docker; then
        success "$MIRROR_NAME 配置完成"

        # 显示配置信息
        echo
        info "当前Docker配置:"
        docker info | grep -A 10 "Registry Mirrors:" 2>/dev/null || echo "  配置已生效"

        # 测试拉取镜像
        echo
        read -p "是否测试拉取镜像? (y/N): " test_pull
        if [[ "$test_pull" =~ ^[Yy]$ ]]; then
            log "测试拉取 alpine 镜像..."
            if docker pull alpine:latest; then
                success "镜像拉取测试成功!"
                docker rmi alpine:latest &>/dev/null
            else
                warn "镜像拉取测试失败，请检查网络或镜像配置"
            fi
        fi
    else
        error "Docker服务启动失败，请检查配置"
        if [[ -f /etc/docker/daemon.json.backup.* ]]; then
            warn "可以恢复备份配置: cp /etc/docker/daemon.json.backup.* /etc/docker/daemon.json"
        fi
    fi
}

# 管理Docker镜像加速器
manage_docker_mirrors() {
    while true; do
        clear
        echo -e "${CYAN}=== Docker镜像加速器管理 ===${NC}"
        echo

        # 检查Docker是否安装
        if ! command -v docker &> /dev/null; then
            error "Docker未安装，请先安装Docker"
            read -p "按Enter键返回..."
            return
        fi

        # 显示当前配置
        echo -e "${BLUE}当前配置状态:${NC}"
        if [[ -f /etc/docker/daemon.json ]]; then
            if grep -q "registry-mirrors" /etc/docker/daemon.json; then
                success "已配置镜像加速器"
                echo "当前镜像源:"
                grep -A 10 "registry-mirrors" /etc/docker/daemon.json | grep "https://" | sed 's/.*"https/  https/g' | sed 's/",*//g'
            else
                warn "daemon.json存在但未配置镜像加速器"
            fi
        else
            warn "未配置镜像加速器"
        fi

        echo
        echo "选择操作:"
        echo "1) 配置/更新镜像加速器"
        echo "2) 删除镜像加速器配置"
        echo "3) 查看当前Docker配置"
        echo "4) 测试镜像拉取速度"
        echo "5) 恢复备份配置"
        echo "0) 返回上级菜单"
        echo

        read -p "请选择 (0-5): " choice

        case $choice in
            1)
                configure_docker_mirrors
                ;;
            2)
                remove_docker_mirrors
                ;;
            3)
                show_docker_config
                ;;
            4)
                test_docker_mirrors
                ;;
            5)
                restore_docker_config
                ;;
            0)
                return
                ;;
            *)
                error "无效选择"
                sleep 2
                ;;
        esac
    done
}

# 删除Docker镜像加速器配置
remove_docker_mirrors() {
    echo
    warn "这将删除Docker镜像加速器配置"
    read -p "确认删除? (y/N): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # 备份当前配置
        if [[ -f /etc/docker/daemon.json ]]; then
            cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
            log "已备份当前配置"
        fi

        # 创建不包含镜像加速器的配置
        cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ],
    "live-restore": true
}
EOF

        # 重启Docker服务
        systemctl daemon-reload
        systemctl restart docker

        success "镜像加速器配置已删除"
    else
        log "操作已取消"
    fi

    read -p "按Enter键继续..."
}

# 显示Docker配置
show_docker_config() {
    echo
    echo -e "${BLUE}=== Docker配置信息 ===${NC}"
    echo

    if [[ -f /etc/docker/daemon.json ]]; then
        echo "daemon.json 内容:"
        cat /etc/docker/daemon.json | jq . 2>/dev/null || cat /etc/docker/daemon.json
    else
        warn "daemon.json 文件不存在"
    fi

    echo
    echo "Docker系统信息:"
    docker info | grep -E "(Registry Mirrors|Storage Driver|Logging Driver)" || true

    read -p "按Enter键继续..."
}

# 测试Docker镜像拉取速度
test_docker_mirrors() {
    echo
    echo -e "${BLUE}=== 测试镜像拉取速度 ===${NC}"
    echo

    # 清理可能存在的测试镜像
    docker rmi alpine:latest &>/dev/null || true

    log "测试拉取 alpine:latest 镜像..."

    start_time=$(date +%s)
    if docker pull alpine:latest; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        success "镜像拉取成功! 耗时: ${duration}秒"

        # 清理测试镜像
        docker rmi alpine:latest &>/dev/null
    else
        error "镜像拉取失败"
    fi

    read -p "按Enter键继续..."
}

# 恢复Docker配置备份
restore_docker_config() {
    echo
    echo -e "${BLUE}=== 恢复Docker配置备份 ===${NC}"
    echo

    # 查找备份文件
    backup_files=($(ls /etc/docker/daemon.json.backup.* 2>/dev/null || true))

    if [[ ${#backup_files[@]} -eq 0 ]]; then
        warn "未找到备份文件"
        read -p "按Enter键继续..."
        return
    fi

    echo "找到以下备份文件:"
    for i in "${!backup_files[@]}"; do
        echo "$((i+1))) ${backup_files[$i]}"
    done
    echo "0) 取消"
    echo

    read -p "选择要恢复的备份 (0-${#backup_files[@]}): " backup_choice

    if [[ "$backup_choice" -ge 1 && "$backup_choice" -le ${#backup_files[@]} ]]; then
        selected_backup="${backup_files[$((backup_choice-1))]}"

        log "恢复备份: $selected_backup"
        cp "$selected_backup" /etc/docker/daemon.json

        # 重启Docker服务
        systemctl daemon-reload
        systemctl restart docker

        success "配置已恢复"
    else
        log "操作已取消"
    fi

    read -p "按Enter键继续..."
}

# Docker管理菜单
manage_docker() {
    while true; do
        echo
        echo -e "${CYAN}=== Docker管理 ===${NC}"
        echo "1. 查看Docker状态"
        echo "2. 查看运行中的容器"
        echo "3. 查看所有容器"
        echo "4. 查看镜像列表"
        echo "5. 清理未使用的资源"
        echo "6. 镜像加速器管理"
        echo "7. 安装Docker Compose"
        echo "0. 返回主菜单"
        echo
        read -p "请选择操作 (0-7): " choice
        
        case $choice in
            1)
                docker info
                ;;
            2)
                docker ps
                ;;
            3)
                docker ps -a
                ;;
            4)
                docker images
                ;;
            5)
                log "清理Docker资源..."
                docker system prune -f
                success "清理完成"
                ;;
            6)
                if check_root; then
                    manage_docker_mirrors
                fi
                ;;
            7)
                install_docker_compose
                ;;
            0)
                return 0
                ;;
            *)
                error "无效选择"
                ;;
        esac
        read -p "按Enter键继续..."
    done
}

install_docker_compose() {
    log "安装Docker Compose..."
    
    if ! check_root; then
        return 1
    fi
    
    case "$PKG_MANAGER" in
        "pacman")
            $INSTALL_CMD docker-compose
            ;;
        "apt")
            $INSTALL_CMD docker-compose-plugin
            ;;
        *)
            # 通用安装方法
            COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
            curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            ;;
    esac
    
    success "Docker Compose安装完成"
    docker-compose --version
}
