#!/bin/bash

# 系统进程管理模块

manage_processes() {
    while true; do
        clear
        echo -e "${CYAN}=== 系统进程管理 ===${NC}"
        echo
        
        # 显示系统负载
        show_system_load
        echo
        
        echo "进程管理选项:"
        echo "1. 📊 查看进程列表"
        echo "2. 🔍 搜索进程"
        echo "3. ⚡ 查看资源使用TOP进程"
        echo "4. 🛑 终止进程"
        echo "5. ⏸️  暂停/恢复进程"
        echo "6. 🎯 调整进程优先级"
        echo "7. 👥 查看用户进程"
        echo "8. 🔧 系统服务管理"
        echo "9. 📈 实时监控"
        echo "10. 🧹 清理僵尸进程"
        echo "11. 📋 进程树显示"
        echo "12. 💾 内存使用分析"
        echo "0. 返回主菜单"
        echo
        read -p "请选择 (0-12): " process_choice
        
        case $process_choice in
            1)
                show_process_list
                ;;
            2)
                search_processes
                ;;
            3)
                show_top_processes
                ;;
            4)
                kill_process
                ;;
            5)
                suspend_resume_process
                ;;
            6)
                adjust_process_priority
                ;;
            7)
                show_user_processes
                ;;
            8)
                manage_system_services
                ;;
            9)
                real_time_monitoring
                ;;
            10)
                clean_zombie_processes
                ;;
            11)
                show_process_tree
                ;;
            12)
                analyze_memory_usage
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

show_system_load() {
    echo -e "${BLUE}=== 系统负载信息 ===${NC}"
    
    # 系统负载
    echo -e "${GREEN}系统负载:${NC} $(uptime | awk -F'load average:' '{print $2}')"
    
    # CPU使用率
    if command -v top &> /dev/null; then
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        echo -e "${GREEN}CPU使用率:${NC} ${cpu_usage}%"
    fi
    
    # 内存使用率
    memory_info=$(free | awk '/^Mem:/{printf "%.1f%%", ($3/$2)*100}')
    echo -e "${GREEN}内存使用率:${NC} $memory_info"
    
    # 进程数量
    process_count=$(ps aux | wc -l)
    echo -e "${GREEN}运行进程数:${NC} $((process_count - 1))"
    
    # 系统运行时间
    echo -e "${GREEN}系统运行时间:${NC} $(uptime -p)"
}

show_process_list() {
    echo -e "${CYAN}=== 进程列表 ===${NC}"
    echo
    
    echo "选择显示方式:"
    echo "1. 简单列表 (ps aux)"
    echo "2. 详细信息 (ps -ef)"
    echo "3. 按CPU使用率排序"
    echo "4. 按内存使用率排序"
    echo "5. 按启动时间排序"
    echo "0. 返回"
    
    read -p "请选择: " list_choice
    
    case $list_choice in
        1)
            ps aux | head -20
            ;;
        2)
            ps -ef | head -20
            ;;
        3)
            ps aux --sort=-%cpu | head -20
            ;;
        4)
            ps aux --sort=-%mem | head -20
            ;;
        5)
            ps aux --sort=lstart | head -20
            ;;
        0)
            return 0
            ;;
    esac
    
    echo
    read -p "显示更多? (y/N): " show_more
    if [[ "$show_more" == "y" || "$show_more" == "Y" ]]; then
        case $list_choice in
            1) ps aux ;;
            2) ps -ef ;;
            3) ps aux --sort=-%cpu ;;
            4) ps aux --sort=-%mem ;;
            5) ps aux --sort=lstart ;;
        esac | less
    fi
    
    read -p "按Enter键继续..."
}

search_processes() {
    echo -e "${CYAN}=== 搜索进程 ===${NC}"
    echo
    
    read -p "输入进程名称或关键词: " search_term
    
    if [[ -z "$search_term" ]]; then
        warn "未输入搜索关键词"
        return 0
    fi
    
    echo -e "${BLUE}搜索结果:${NC}"
    ps aux | grep -i "$search_term" | grep -v grep
    
    echo
    echo -e "${BLUE}使用pgrep搜索:${NC}"
    pgrep -l "$search_term" 2>/dev/null || echo "未找到匹配的进程"
    
    read -p "按Enter键继续..."
}

show_top_processes() {
    echo -e "${CYAN}=== 资源使用TOP进程 ===${NC}"
    echo
    
    echo "选择排序方式:"
    echo "1. CPU使用率最高"
    echo "2. 内存使用率最高"
    echo "3. 磁盘I/O最高"
    echo "4. 网络使用最高"
    echo "5. 交互式top"
    echo "0. 返回"
    
    read -p "请选择: " top_choice
    
    case $top_choice in
        1)
            echo -e "${BLUE}CPU使用率最高的进程:${NC}"
            ps aux --sort=-%cpu | head -15
            ;;
        2)
            echo -e "${BLUE}内存使用率最高的进程:${NC}"
            ps aux --sort=-%mem | head -15
            ;;
        3)
            if command -v iotop &> /dev/null; then
                echo -e "${BLUE}磁盘I/O最高的进程:${NC}"
                iotop -b -n 1 | head -15
            else
                warn "iotop未安装，使用iostat替代"
                iostat -x 1 1 2>/dev/null || echo "iostat也未安装"
            fi
            ;;
        4)
            if command -v nethogs &> /dev/null; then
                echo -e "${BLUE}网络使用最高的进程:${NC}"
                timeout 5 nethogs -t
            else
                warn "nethogs未安装"
                echo "安装命令: sudo $PKG_MANAGER install nethogs"
            fi
            ;;
        5)
            echo "启动交互式top (按q退出)..."
            sleep 2
            top
            ;;
        0)
            return 0
            ;;
    esac
    
    read -p "按Enter键继续..."
}

kill_process() {
    echo -e "${CYAN}=== 终止进程 ===${NC}"
    echo
    
    echo "选择终止方式:"
    echo "1. 按PID终止"
    echo "2. 按进程名终止"
    echo "3. 强制终止 (SIGKILL)"
    echo "4. 优雅终止 (SIGTERM)"
    echo "0. 返回"
    
    read -p "请选择: " kill_choice
    
    case $kill_choice in
        1)
            read -p "输入进程PID: " pid
            if [[ "$pid" =~ ^[0-9]+$ ]]; then
                if ps -p "$pid" > /dev/null; then
                    echo "进程信息:"
                    ps -p "$pid" -o pid,ppid,cmd
                    read -p "确定终止此进程? (y/N): " confirm
                    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                        kill "$pid" && success "进程已终止" || error "终止失败"
                    fi
                else
                    error "进程不存在"
                fi
            else
                error "无效的PID"
            fi
            ;;
        2)
            read -p "输入进程名: " process_name
            if [[ -n "$process_name" ]]; then
                echo "找到的进程:"
                pgrep -l "$process_name"
                read -p "确定终止所有匹配的进程? (y/N): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    pkill "$process_name" && success "进程已终止" || error "终止失败"
                fi
            fi
            ;;
        3)
            read -p "输入要强制终止的PID: " pid
            if [[ "$pid" =~ ^[0-9]+$ ]]; then
                read -p "确定强制终止进程 $pid? (y/N): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    kill -9 "$pid" && success "进程已强制终止" || error "终止失败"
                fi
            fi
            ;;
        4)
            read -p "输入要优雅终止的PID: " pid
            if [[ "$pid" =~ ^[0-9]+$ ]]; then
                kill -15 "$pid" && success "发送终止信号" || error "发送失败"
            fi
            ;;
    esac
    
    read -p "按Enter键继续..."
}

suspend_resume_process() {
    echo -e "${CYAN}=== 暂停/恢复进程 ===${NC}"
    echo
    
    echo "选择操作:"
    echo "1. 暂停进程 (SIGSTOP)"
    echo "2. 恢复进程 (SIGCONT)"
    echo "3. 查看暂停的进程"
    echo "0. 返回"
    
    read -p "请选择: " suspend_choice
    
    case $suspend_choice in
        1)
            read -p "输入要暂停的进程PID: " pid
            if [[ "$pid" =~ ^[0-9]+$ ]]; then
                kill -STOP "$pid" && success "进程已暂停" || error "暂停失败"
            fi
            ;;
        2)
            read -p "输入要恢复的进程PID: " pid
            if [[ "$pid" =~ ^[0-9]+$ ]]; then
                kill -CONT "$pid" && success "进程已恢复" || error "恢复失败"
            fi
            ;;
        3)
            echo -e "${BLUE}暂停的进程:${NC}"
            ps aux | awk '$8 ~ /T/ {print $2, $11}' | head -10
            ;;
    esac
    
    read -p "按Enter键继续..."
}

adjust_process_priority() {
    if ! check_root; then
        warn "调整进程优先级需要root权限"
        read -p "按Enter键继续..."
        return 1
    fi
    
    echo -e "${CYAN}=== 调整进程优先级 ===${NC}"
    echo
    
    echo -e "${BLUE}Nice值说明:${NC}"
    echo "• -20 到 19 的范围"
    echo "• -20 = 最高优先级"
    echo "• 0 = 默认优先级"
    echo "• 19 = 最低优先级"
    echo
    
    read -p "输入进程PID: " pid
    if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
        error "无效的PID"
        return 1
    fi
    
    if ! ps -p "$pid" > /dev/null; then
        error "进程不存在"
        return 1
    fi
    
    # 显示当前优先级
    current_nice=$(ps -o nice= -p "$pid")
    echo -e "${GREEN}当前Nice值:${NC} $current_nice"
    
    read -p "输入新的Nice值 (-20 到 19): " new_nice
    if [[ ! "$new_nice" =~ ^-?[0-9]+$ ]] || [[ "$new_nice" -lt -20 ]] || [[ "$new_nice" -gt 19 ]]; then
        error "无效的Nice值"
        return 1
    fi
    
    renice "$new_nice" -p "$pid" && success "优先级已调整" || error "调整失败"
    
    read -p "按Enter键继续..."
}

show_user_processes() {
    echo -e "${CYAN}=== 用户进程 ===${NC}"
    echo
    
    echo "选择查看方式:"
    echo "1. 当前用户进程"
    echo "2. 指定用户进程"
    echo "3. 所有用户进程统计"
    echo "0. 返回"
    
    read -p "请选择: " user_choice
    
    case $user_choice in
        1)
            echo -e "${BLUE}当前用户 ($USER) 的进程:${NC}"
            ps -u "$USER" -o pid,ppid,cmd | head -20
            ;;
        2)
            read -p "输入用户名: " username
            if id "$username" &> /dev/null; then
                echo -e "${BLUE}用户 $username 的进程:${NC}"
                ps -u "$username" -o pid,ppid,cmd | head -20
            else
                error "用户不存在"
            fi
            ;;
        3)
            echo -e "${BLUE}各用户进程统计:${NC}"
            ps aux | awk '{user[$1]++} END {for (u in user) print u, user[u]}' | sort -k2 -nr
            ;;
    esac
    
    read -p "按Enter键继续..."
}

manage_system_services() {
    echo -e "${CYAN}=== 系统服务管理 ===${NC}"
    echo
    
    if command -v systemctl &> /dev/null; then
        manage_systemd_services
    elif command -v service &> /dev/null; then
        manage_sysv_services
    else
        warn "未找到服务管理工具"
    fi
    
    read -p "按Enter键继续..."
}

manage_systemd_services() {
    echo "Systemd服务管理:"
    echo "1. 查看所有服务状态"
    echo "2. 查看运行中的服务"
    echo "3. 查看失败的服务"
    echo "4. 启动服务"
    echo "5. 停止服务"
    echo "6. 重启服务"
    echo "7. 启用服务 (开机自启)"
    echo "8. 禁用服务"
    echo "0. 返回"
    
    read -p "请选择: " service_choice
    
    case $service_choice in
        1)
            systemctl list-units --type=service | head -20
            ;;
        2)
            systemctl list-units --type=service --state=running
            ;;
        3)
            systemctl list-units --type=service --state=failed
            ;;
        4)
            read -p "输入要启动的服务名: " service_name
            if [[ -n "$service_name" ]]; then
                if check_root; then
                    systemctl start "$service_name" && success "服务已启动" || error "启动失败"
                fi
            fi
            ;;
        5)
            read -p "输入要停止的服务名: " service_name
            if [[ -n "$service_name" ]]; then
                if check_root; then
                    systemctl stop "$service_name" && success "服务已停止" || error "停止失败"
                fi
            fi
            ;;
        6)
            read -p "输入要重启的服务名: " service_name
            if [[ -n "$service_name" ]]; then
                if check_root; then
                    systemctl restart "$service_name" && success "服务已重启" || error "重启失败"
                fi
            fi
            ;;
        7)
            read -p "输入要启用的服务名: " service_name
            if [[ -n "$service_name" ]]; then
                if check_root; then
                    systemctl enable "$service_name" && success "服务已启用" || error "启用失败"
                fi
            fi
            ;;
        8)
            read -p "输入要禁用的服务名: " service_name
            if [[ -n "$service_name" ]]; then
                if check_root; then
                    systemctl disable "$service_name" && success "服务已禁用" || error "禁用失败"
                fi
            fi
            ;;
    esac
}

real_time_monitoring() {
    echo -e "${CYAN}=== 实时监控 ===${NC}"
    echo
    
    echo "选择监控工具:"
    echo "1. htop (推荐)"
    echo "2. top"
    echo "3. iotop (磁盘I/O)"
    echo "4. nethogs (网络)"
    echo "5. watch + ps"
    echo "0. 返回"
    
    read -p "请选择: " monitor_choice
    
    case $monitor_choice in
        1)
            if command -v htop &> /dev/null; then
                htop
            else
                warn "htop未安装，使用top替代"
                top
            fi
            ;;
        2)
            top
            ;;
        3)
            if command -v iotop &> /dev/null; then
                if check_root; then
                    iotop
                fi
            else
                warn "iotop未安装"
                echo "安装命令: sudo $PKG_MANAGER install iotop"
            fi
            ;;
        4)
            if command -v nethogs &> /dev/null; then
                if check_root; then
                    nethogs
                fi
            else
                warn "nethogs未安装"
                echo "安装命令: sudo $PKG_MANAGER install nethogs"
            fi
            ;;
        5)
            watch -n 1 'ps aux --sort=-%cpu | head -20'
            ;;
    esac
}

clean_zombie_processes() {
    echo -e "${CYAN}=== 清理僵尸进程 ===${NC}"
    echo
    
    # 查找僵尸进程
    zombies=$(ps aux | awk '$8 ~ /Z/ {print $2}')
    
    if [[ -z "$zombies" ]]; then
        success "没有发现僵尸进程"
    else
        echo -e "${BLUE}发现的僵尸进程:${NC}"
        ps aux | awk '$8 ~ /Z/ {print $2, $11}'
        echo
        
        warn "僵尸进程通常需要重启父进程来清理"
        echo "或者等待父进程自动清理"
        
        # 尝试向父进程发送SIGCHLD信号
        for zombie in $zombies; do
            ppid=$(ps -o ppid= -p "$zombie" 2>/dev/null)
            if [[ -n "$ppid" ]]; then
                echo "尝试清理僵尸进程 $zombie (父进程: $ppid)"
                kill -CHLD "$ppid" 2>/dev/null || true
            fi
        done
    fi
    
    read -p "按Enter键继续..."
}

show_process_tree() {
    echo -e "${CYAN}=== 进程树 ===${NC}"
    echo
    
    if command -v pstree &> /dev/null; then
        echo "使用pstree显示进程树:"
        pstree -p | head -30
        echo
        read -p "显示完整进程树? (y/N): " show_full
        if [[ "$show_full" == "y" || "$show_full" == "Y" ]]; then
            pstree -p | less
        fi
    else
        echo "使用ps显示进程层次:"
        ps auxf | head -30
        echo
        read -p "显示完整进程树? (y/N): " show_full
        if [[ "$show_full" == "y" || "$show_full" == "Y" ]]; then
            ps auxf | less
        fi
    fi
    
    read -p "按Enter键继续..."
}

analyze_memory_usage() {
    echo -e "${CYAN}=== 内存使用分析 ===${NC}"
    echo
    
    # 总体内存使用情况
    echo -e "${BLUE}总体内存使用:${NC}"
    free -h
    echo
    
    # 内存使用最多的进程
    echo -e "${BLUE}内存使用最多的进程 (前10个):${NC}"
    ps aux --sort=-%mem | head -11
    echo
    
    # 详细内存信息
    echo -e "${BLUE}详细内存信息:${NC}"
    cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree)" | column -t
    echo
    
    # 内存使用建议
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    used_mem=$(free -m | awk '/^Mem:/{print $3}')
    usage_percent=$((used_mem * 100 / total_mem))
    
    echo -e "${BLUE}内存使用分析:${NC}"
    echo "内存使用率: ${usage_percent}%"
    
    if [[ $usage_percent -gt 90 ]]; then
        warn "内存使用率过高，建议:"
        echo "• 关闭不必要的程序"
        echo "• 增加物理内存"
        echo "• 检查内存泄漏"
    elif [[ $usage_percent -gt 70 ]]; then
        info "内存使用率较高，建议监控"
    else
        success "内存使用率正常"
    fi
    
    read -p "按Enter键继续..."
}

manage_sysv_services() {
    echo "SysV服务管理:"
    echo "1. 查看所有服务"
    echo "2. 启动服务"
    echo "3. 停止服务"
    echo "4. 重启服务"
    echo "0. 返回"
    
    read -p "请选择: " sysv_choice
    
    case $sysv_choice in
        1)
            service --status-all
            ;;
        2)
            read -p "输入要启动的服务名: " service_name
            if [[ -n "$service_name" ]] && check_root; then
                service "$service_name" start
            fi
            ;;
        3)
            read -p "输入要停止的服务名: " service_name
            if [[ -n "$service_name" ]] && check_root; then
                service "$service_name" stop
            fi
            ;;
        4)
            read -p "输入要重启的服务名: " service_name
            if [[ -n "$service_name" ]] && check_root; then
                service "$service_name" restart
            fi
            ;;
    esac
}
