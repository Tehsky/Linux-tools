#!/bin/bash

# Swap管理模块

manage_swap() {
    while true; do
        clear
        echo -e "${CYAN}=== Swap管理 ===${NC}"
        echo
        
        # 显示当前Swap状态
        show_swap_status
        echo
        
        echo "Swap管理选项:"
        echo "1. 📁 创建Swap文件"
        echo "2. 💿 创建Swap分区"
        echo "3. 🗑️  删除Swap"
        echo "4. 📏 调整Swap大小"
        echo "5. ⚙️  配置Swappiness"
        echo "6. 🔄 启用/禁用Swap"
        echo "7. 🧹 清理Swap缓存"
        echo "8. 📊 Swap性能分析"
        echo "9. 🔧 Zswap配置"
        echo "10. 💾 Swap加密设置"
        echo "0. 返回主菜单"
        echo
        read -p "请选择 (0-10): " swap_choice
        
        case $swap_choice in
            1)
                create_swap_file
                ;;
            2)
                create_swap_partition
                ;;
            3)
                remove_swap
                ;;
            4)
                resize_swap
                ;;
            5)
                configure_swappiness
                ;;
            6)
                toggle_swap
                ;;
            7)
                clear_swap_cache
                ;;
            8)
                analyze_swap_performance
                ;;
            9)
                configure_zswap
                ;;
            10)
                configure_swap_encryption
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

show_swap_status() {
    echo -e "${BLUE}=== 当前Swap状态 ===${NC}"
    
    # 显示Swap使用情况
    if [[ -f /proc/swaps ]]; then
        echo -e "${GREEN}Swap设备:${NC}"
        cat /proc/swaps
        echo
    fi
    
    # 显示内存和Swap使用情况
    echo -e "${GREEN}内存使用情况:${NC}"
    free -h
    echo
    
    # 显示Swappiness值
    echo -e "${GREEN}当前Swappiness:${NC} $(cat /proc/sys/vm/swappiness)"
    
    # 显示Swap相关的内核参数
    echo -e "${GREEN}Swap相关参数:${NC}"
    echo "vm.swappiness = $(cat /proc/sys/vm/swappiness)"
    echo "vm.vfs_cache_pressure = $(cat /proc/sys/vm/vfs_cache_pressure)"
    echo "vm.dirty_ratio = $(cat /proc/sys/vm/dirty_ratio)"
    echo "vm.dirty_background_ratio = $(cat /proc/sys/vm/dirty_background_ratio)"
}

create_swap_file() {
    if ! check_root; then
        return 1
    fi
    
    echo -e "${CYAN}=== 创建Swap文件 ===${NC}"
    echo
    
    # 检查可用空间
    echo -e "${BLUE}磁盘空间使用情况:${NC}"
    df -h /
    echo
    
    # 获取推荐的Swap大小
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    RECOMMENDED_SWAP=$(calculate_recommended_swap_size $TOTAL_RAM)
    
    echo -e "${GREEN}系统内存:${NC} ${TOTAL_RAM}MB"
    echo -e "${GREEN}推荐Swap大小:${NC} ${RECOMMENDED_SWAP}MB"
    echo
    
    read -p "输入Swap文件大小 (MB) [默认: $RECOMMENDED_SWAP]: " swap_size
    swap_size=${swap_size:-$RECOMMENDED_SWAP}
    
    read -p "输入Swap文件路径 [默认: /swapfile]: " swap_path
    swap_path=${swap_path:-/swapfile}
    
    # 检查文件是否已存在
    if [[ -f "$swap_path" ]]; then
        warn "文件 $swap_path 已存在"
        read -p "是否覆盖? (y/N): " overwrite
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            return 0
        fi
        rm -f "$swap_path"
    fi
    
    log "创建 ${swap_size}MB 的Swap文件: $swap_path"
    
    # 创建Swap文件
    dd if=/dev/zero of="$swap_path" bs=1M count="$swap_size" status=progress
    
    # 设置权限
    chmod 600 "$swap_path"
    
    # 格式化为Swap
    mkswap "$swap_path"
    
    # 启用Swap
    swapon "$swap_path"
    
    # 添加到fstab
    if ! grep -q "$swap_path" /etc/fstab; then
        echo "$swap_path none swap sw 0 0" >> /etc/fstab
        log "已添加到 /etc/fstab"
    fi
    
    success "Swap文件创建完成"
    show_swap_status
    
    read -p "按Enter键继续..."
}

create_swap_partition() {
    if ! check_root; then
        return 1
    fi
    
    echo -e "${CYAN}=== 创建Swap分区 ===${NC}"
    echo
    
    warn "创建Swap分区需要未分配的磁盘空间"
    echo "这是一个高级操作，请确保您了解分区操作的风险"
    echo
    
    # 显示磁盘信息
    echo -e "${BLUE}可用磁盘:${NC}"
    lsblk -d -o NAME,SIZE,MODEL
    echo
    
    echo -e "${BLUE}分区信息:${NC}"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    echo
    
    warn "请使用专业的分区工具 (如 fdisk, parted, gparted) 创建Swap分区"
    echo "创建分区后，可以使用以下命令格式化和启用:"
    echo "  mkswap /dev/sdXY"
    echo "  swapon /dev/sdXY"
    echo "  echo '/dev/sdXY none swap sw 0 0' >> /etc/fstab"
    
    read -p "按Enter键继续..."
}

remove_swap() {
    if ! check_root; then
        return 1
    fi
    
    echo -e "${CYAN}=== 删除Swap ===${NC}"
    echo
    
    # 显示当前Swap
    if [[ ! -s /proc/swaps ]]; then
        warn "当前没有活动的Swap"
        return 0
    fi
    
    echo -e "${BLUE}当前Swap设备:${NC}"
    cat /proc/swaps
    echo
    
    read -p "输入要删除的Swap设备路径: " swap_device
    
    if [[ -z "$swap_device" ]]; then
        warn "未指定Swap设备"
        return 0
    fi
    
    # 检查设备是否存在
    if ! grep -q "$swap_device" /proc/swaps; then
        error "Swap设备 $swap_device 不存在或未启用"
        return 1
    fi
    
    read -p "确定删除Swap设备 $swap_device 吗? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "禁用Swap设备: $swap_device"
        swapoff "$swap_device"
        
        # 从fstab中删除
        sed -i "\|$swap_device|d" /etc/fstab
        
        # 如果是文件，询问是否删除
        if [[ -f "$swap_device" ]]; then
            read -p "是否删除Swap文件? (y/N): " delete_file
            if [[ "$delete_file" == "y" || "$delete_file" == "Y" ]]; then
                rm -f "$swap_device"
                log "Swap文件已删除"
            fi
        fi
        
        success "Swap设备删除完成"
    else
        log "操作已取消"
    fi
    
    read -p "按Enter键继续..."
}

configure_swappiness() {
    if ! check_root; then
        return 1
    fi
    
    echo -e "${CYAN}=== 配置Swappiness ===${NC}"
    echo
    
    current_swappiness=$(cat /proc/sys/vm/swappiness)
    echo -e "${GREEN}当前Swappiness值:${NC} $current_swappiness"
    echo
    
    echo -e "${BLUE}Swappiness值说明:${NC}"
    echo "• 0-10: 最小化Swap使用，优先使用RAM (适合桌面)"
    echo "• 10-30: 低Swap使用 (推荐桌面用户)"
    echo "• 30-60: 平衡使用 (默认值通常为60)"
    echo "• 60-100: 积极使用Swap (适合服务器)"
    echo
    
    read -p "输入新的Swappiness值 (0-100): " new_swappiness
    
    if [[ ! "$new_swappiness" =~ ^[0-9]+$ ]] || [[ "$new_swappiness" -gt 100 ]]; then
        error "无效的Swappiness值"
        return 1
    fi
    
    # 临时设置
    echo "$new_swappiness" > /proc/sys/vm/swappiness
    
    # 永久设置
    if grep -q "vm.swappiness" /etc/sysctl.conf; then
        sed -i "s/vm.swappiness.*/vm.swappiness = $new_swappiness/" /etc/sysctl.conf
    else
        echo "vm.swappiness = $new_swappiness" >> /etc/sysctl.conf
    fi
    
    success "Swappiness已设置为: $new_swappiness"
    
    read -p "按Enter键继续..."
}

toggle_swap() {
    if ! check_root; then
        return 1
    fi
    
    echo -e "${CYAN}=== 启用/禁用Swap ===${NC}"
    echo
    
    echo "1. 启用所有Swap"
    echo "2. 禁用所有Swap"
    echo "3. 启用特定Swap设备"
    echo "4. 禁用特定Swap设备"
    echo "0. 返回"
    
    read -p "请选择: " toggle_choice
    
    case $toggle_choice in
        1)
            log "启用所有Swap设备..."
            swapon -a
            success "所有Swap设备已启用"
            ;;
        2)
            log "禁用所有Swap设备..."
            swapoff -a
            success "所有Swap设备已禁用"
            ;;
        3)
            read -p "输入要启用的Swap设备路径: " swap_device
            if [[ -n "$swap_device" ]]; then
                swapon "$swap_device"
                success "Swap设备已启用: $swap_device"
            fi
            ;;
        4)
            read -p "输入要禁用的Swap设备路径: " swap_device
            if [[ -n "$swap_device" ]]; then
                swapoff "$swap_device"
                success "Swap设备已禁用: $swap_device"
            fi
            ;;
    esac
    
    show_swap_status
    read -p "按Enter键继续..."
}

clear_swap_cache() {
    if ! check_root; then
        return 1
    fi
    
    echo -e "${CYAN}=== 清理Swap缓存 ===${NC}"
    echo
    
    warn "清理Swap缓存会将Swap中的数据移回内存"
    warn "请确保有足够的可用内存"
    echo
    
    # 显示当前内存使用情况
    free -h
    echo
    
    read -p "确定清理Swap缓存吗? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "清理Swap缓存..."
        
        # 禁用所有Swap
        swapoff -a
        
        # 重新启用所有Swap
        swapon -a
        
        success "Swap缓存清理完成"
        show_swap_status
    else
        log "操作已取消"
    fi
    
    read -p "按Enter键继续..."
}

analyze_swap_performance() {
    echo -e "${CYAN}=== Swap性能分析 ===${NC}"
    echo
    
    # 显示Swap使用统计
    echo -e "${BLUE}Swap使用统计:${NC}"
    if command -v vmstat &> /dev/null; then
        echo "最近的Swap活动 (每秒):"
        vmstat 1 5 | tail -5
    fi
    echo
    
    # 显示进程Swap使用情况
    echo -e "${BLUE}进程Swap使用情况 (前10个):${NC}"
    if [[ -d /proc ]]; then
        for pid in $(ps -eo pid --no-headers); do
            if [[ -f "/proc/$pid/smaps" ]]; then
                swap_kb=$(awk '/^Swap:/ {sum += $2} END {print sum}' "/proc/$pid/smaps" 2>/dev/null)
                if [[ -n "$swap_kb" && "$swap_kb" -gt 0 ]]; then
                    cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
                    echo "$pid $cmd ${swap_kb}KB"
                fi
            fi
        done | sort -k3 -nr | head -10
    fi
    echo
    
    # Swap设备性能信息
    echo -e "${BLUE}Swap设备信息:${NC}"
    cat /proc/swaps
    echo
    
    # 建议
    echo -e "${BLUE}性能建议:${NC}"
    total_ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    swap_usage=$(free | awk '/^Swap:/{if($2>0) print ($3/$2)*100; else print 0}')
    
    if (( $(echo "$swap_usage > 50" | bc -l) )); then
        warn "Swap使用率较高 (${swap_usage}%)，建议:"
        echo "• 增加物理内存"
        echo "• 降低Swappiness值"
        echo "• 检查内存泄漏的程序"
    elif (( $(echo "$swap_usage < 5" | bc -l) )); then
        info "Swap使用率很低 (${swap_usage}%)，可以考虑:"
        echo "• 减少Swap大小"
        echo "• 提高Swappiness值以更好利用Swap"
    else
        success "Swap使用率正常 (${swap_usage}%)"
    fi
    
    read -p "按Enter键继续..."
}

configure_zswap() {
    if ! check_root; then
        return 1
    fi
    
    echo -e "${CYAN}=== Zswap配置 ===${NC}"
    echo
    
    echo -e "${BLUE}Zswap说明:${NC}"
    echo "• Zswap是内核内存压缩功能"
    echo "• 在写入磁盘Swap前先压缩内存页"
    echo "• 可以提高Swap性能并减少磁盘I/O"
    echo
    
    # 检查Zswap状态
    if [[ -f /sys/module/zswap/parameters/enabled ]]; then
        zswap_enabled=$(cat /sys/module/zswap/parameters/enabled)
        echo -e "${GREEN}Zswap状态:${NC} $([[ "$zswap_enabled" == "Y" ]] && echo "已启用" || echo "已禁用")"
        
        if [[ "$zswap_enabled" == "Y" ]]; then
            echo -e "${GREEN}压缩算法:${NC} $(cat /sys/module/zswap/parameters/compressor)"
            echo -e "${GREEN}内存池:${NC} $(cat /sys/module/zswap/parameters/zpool)"
            echo -e "${GREEN}最大池大小:${NC} $(cat /sys/module/zswap/parameters/max_pool_percent)%"
        fi
    else
        warn "当前内核不支持Zswap"
        return 1
    fi
    echo
    
    echo "Zswap配置选项:"
    echo "1. 启用Zswap"
    echo "2. 禁用Zswap"
    echo "3. 配置压缩算法"
    echo "4. 配置内存池大小"
    echo "0. 返回"
    
    read -p "请选择: " zswap_choice
    
    case $zswap_choice in
        1)
            echo Y > /sys/module/zswap/parameters/enabled
            success "Zswap已启用"
            ;;
        2)
            echo N > /sys/module/zswap/parameters/enabled
            success "Zswap已禁用"
            ;;
        3)
            echo "可用的压缩算法:"
            cat /sys/module/zswap/parameters/compressor
            read -p "输入压缩算法: " compressor
            if [[ -n "$compressor" ]]; then
                echo "$compressor" > /sys/module/zswap/parameters/compressor
                success "压缩算法已设置为: $compressor"
            fi
            ;;
        4)
            read -p "输入最大池大小百分比 (1-50): " pool_percent
            if [[ "$pool_percent" =~ ^[0-9]+$ ]] && [[ "$pool_percent" -le 50 ]]; then
                echo "$pool_percent" > /sys/module/zswap/parameters/max_pool_percent
                success "最大池大小已设置为: ${pool_percent}%"
            else
                error "无效的百分比值"
            fi
            ;;
    esac
    
    read -p "按Enter键继续..."
}

configure_swap_encryption() {
    echo -e "${CYAN}=== Swap加密设置 ===${NC}"
    echo
    
    warn "Swap加密是一个高级功能，需要重新配置系统"
    echo "建议在系统安装时配置，或寻求专业帮助"
    echo
    
    echo -e "${BLUE}Swap加密方法:${NC}"
    echo "1. 使用cryptsetup配置加密Swap分区"
    echo "2. 使用随机密钥的临时加密Swap"
    echo "3. 集成到LUKS全盘加密中"
    echo
    
    echo "参考命令:"
    echo "# 创建加密Swap分区"
    echo "cryptsetup luksFormat /dev/sdXY"
    echo "cryptsetup luksOpen /dev/sdXY swap"
    echo "mkswap /dev/mapper/swap"
    echo "swapon /dev/mapper/swap"
    echo
    
    echo "# 在/etc/crypttab中添加:"
    echo "swap /dev/sdXY /dev/urandom swap,cipher=aes-xts-plain64,size=256"
    
    read -p "按Enter键继续..."
}

resize_swap() {
    log "调整Swap大小功能开发中..."
    read -p "按Enter键继续..."
}

calculate_recommended_swap_size() {
    local ram_mb=$1
    local swap_mb
    
    if [[ $ram_mb -le 2048 ]]; then
        # 2GB以下: 2倍RAM
        swap_mb=$((ram_mb * 2))
    elif [[ $ram_mb -le 8192 ]]; then
        # 2-8GB: 等于RAM
        swap_mb=$ram_mb
    elif [[ $ram_mb -le 16384 ]]; then
        # 8-16GB: 0.5倍RAM
        swap_mb=$((ram_mb / 2))
    else
        # 16GB以上: 4-8GB
        swap_mb=8192
    fi
    
    echo $swap_mb
}
