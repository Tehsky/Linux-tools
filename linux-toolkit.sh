#!/bin/bash

# Linux Toolkit - 全功能Linux系统管理工具
# 支持多发行版，自动识别系统和包管理器
# 功能：微码、显卡驱动、Docker、网络配置、透明代理、内核管理、Swap管理、进程管理

set -e

# 版本信息
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 系统检测
detect_system() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
        DISTRO_VERSION="$VERSION_ID"
        DISTRO_NAME="$NAME"
    else
        error "无法检测系统发行版"
        exit 1
    fi
    
    # 检测包管理器
    if command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="pacman -S --noconfirm"
        UPDATE_CMD="pacman -Syu --noconfirm"
        SEARCH_CMD="pacman -Ss"
        REMOVE_CMD="pacman -R --noconfirm"
        CLEAN_CMD="pacman -Sc --noconfirm"
    elif command -v emerge &> /dev/null; then
        PKG_MANAGER="emerge"
        INSTALL_CMD="emerge --ask=n"
        UPDATE_CMD="emerge --sync && emerge -uDN @world"
        SEARCH_CMD="emerge --search"
        REMOVE_CMD="emerge --unmerge"
        CLEAN_CMD="emerge --depclean"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="apt install -y"
        UPDATE_CMD="apt update && apt upgrade -y"
        SEARCH_CMD="apt search"
        REMOVE_CMD="apt remove -y"
        CLEAN_CMD="apt autoremove -y && apt autoclean"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="dnf install -y"
        UPDATE_CMD="dnf upgrade -y"
        SEARCH_CMD="dnf search"
        REMOVE_CMD="dnf remove -y"
        CLEAN_CMD="dnf autoremove -y && dnf clean all"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        INSTALL_CMD="yum install -y"
        UPDATE_CMD="yum update -y"
        SEARCH_CMD="yum search"
        REMOVE_CMD="yum remove -y"
        CLEAN_CMD="yum autoremove -y && yum clean all"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
        INSTALL_CMD="zypper install -y"
        UPDATE_CMD="zypper refresh && zypper update -y"
        SEARCH_CMD="zypper search"
        REMOVE_CMD="zypper remove -y"
        CLEAN_CMD="zypper clean -a"
    else
        error "不支持的包管理器"
        exit 1
    fi
    
    # 检测架构
    ARCH=$(uname -m)
    
    log "检测到系统: $DISTRO_NAME ($DISTRO $DISTRO_VERSION)"
    log "包管理器: $PKG_MANAGER"
    log "系统架构: $ARCH"
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此功能需要root权限，请使用sudo运行"
        return 1
    fi
    return 0
}

# 显示主菜单
show_main_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Linux Toolkit v$VERSION                     ║${NC}"
    echo -e "${CYAN}║                  全功能Linux系统管理工具                        ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║  系统信息: $DISTRO_NAME ($ARCH)${NC}"
    echo -e "${WHITE}║  包管理器: $PKG_MANAGER${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║  1. 📦 安装处理器微码 (自动识别Intel/AMD)                      ║${NC}"
    echo -e "${WHITE}║  2. 🎮 安装显卡驱动 (AMD开源/NVIDIA闭源)                       ║${NC}"
    echo -e "${WHITE}║  3. 🐳 安装Docker并配置加速器                                  ║${NC}"
    echo -e "${WHITE}║  4. 🌐 查看网络配置 (IP/网关/DNS)                             ║${NC}"
    echo -e "${WHITE}║  5. 🔒 配置透明代理 (主流翻墙软件)                             ║${NC}"
    echo -e "${WHITE}║  6. 🔧 安装第三方内核                                         ║${NC}"
    echo -e "${WHITE}║  7. 💾 Swap管理                                              ║${NC}"
    echo -e "${WHITE}║  8. ⚙️  系统进程管理                                          ║${NC}"
    echo -e "${WHITE}║  9. 🔄 系统更新                                              ║${NC}"
    echo -e "${WHITE}║  0. 🚪 退出                                                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# 安装处理器微码
install_microcode() {
    log "检测处理器类型并安装微码..."
    
    if ! check_root; then
        return 1
    fi
    
    # 检测CPU类型
    CPU_VENDOR=$(lscpu | grep "Vendor ID" | awk '{print $3}')
    
    case "$CPU_VENDOR" in
        "GenuineIntel")
            log "检测到Intel处理器，安装Intel微码..."
            case "$PKG_MANAGER" in
                "pacman")
                    $INSTALL_CMD intel-ucode
                    ;;
                "emerge")
                    $INSTALL_CMD sys-firmware/intel-microcode
                    ;;
                "apt")
                    $INSTALL_CMD intel-microcode
                    ;;
                "dnf"|"yum")
                    $INSTALL_CMD microcode_ctl
                    ;;
                "zypper")
                    $INSTALL_CMD ucode-intel
                    ;;
            esac
            success "Intel微码安装完成"
            ;;
        "AuthenticAMD")
            log "检测到AMD处理器，安装AMD微码..."
            case "$PKG_MANAGER" in
                "pacman")
                    $INSTALL_CMD amd-ucode
                    ;;
                "emerge")
                    $INSTALL_CMD sys-firmware/linux-firmware
                    ;;
                "apt")
                    $INSTALL_CMD amd64-microcode
                    ;;
                "dnf"|"yum")
                    $INSTALL_CMD microcode_ctl
                    ;;
                "zypper")
                    $INSTALL_CMD ucode-amd
                    ;;
            esac
            success "AMD微码安装完成"
            ;;
        *)
            warn "未知的处理器类型: $CPU_VENDOR"
            ;;
    esac
    
    # 更新引导加载器
    if command -v grub-mkconfig &> /dev/null; then
        log "更新GRUB配置..."
        grub-mkconfig -o /boot/grub/grub.cfg
    elif command -v update-grub &> /dev/null; then
        log "更新GRUB配置..."
        update-grub
    fi
    
    warn "微码更新需要重启系统才能生效"
    read -p "按Enter键继续..."
}

# 检查DKMS依赖
check_dkms_dependencies() {
    local missing_deps=()
    
    # 检查DKMS
    if ! command -v dkms &> /dev/null; then
        missing_deps+=("dkms")
    fi
    
    # 检查编译工具链
    case "$PKG_MANAGER" in
        "pacman")
            if ! pacman -Qi base-devel &> /dev/null; then
                missing_deps+=("base-devel")
            fi
            if ! pacman -Qi linux-headers &> /dev/null; then
                missing_deps+=("linux-headers")
            fi
            ;;
        "emerge")
            if ! command -v gcc &> /dev/null; then
                missing_deps+=("sys-devel/gcc")
            fi
            if ! command -v make &> /dev/null; then
                missing_deps+=("sys-devel/make")
            fi
            ;;
        "apt")
            if ! dpkg -l | grep -q build-essential; then
                missing_deps+=("build-essential")
            fi
            if ! dpkg -l | grep -q linux-headers-$(uname -r); then
                missing_deps+=("linux-headers-$(uname -r)")
            fi
            ;;
        "dnf"|"yum")
            if ! rpm -q kernel-devel &> /dev/null; then
                missing_deps+=("kernel-devel")
            fi
            if ! rpm -q gcc &> /dev/null; then
                missing_deps+=("gcc")
            fi
            ;;
    esac
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        warn "检测到缺少DKMS依赖: ${missing_deps[*]}"
        read -p "是否自动安装这些依赖? (Y/n): " install_deps
        if [[ "$install_deps" != "n" && "$install_deps" != "N" ]]; then
            log "安装DKMS依赖..."
            $INSTALL_CMD ${missing_deps[*]}
            success "DKMS依赖安装完成"
        else
            error "缺少必要依赖，DKMS功能可能无法正常工作"
            return 1
        fi
    fi
    
    return 0
}

# 安装NVIDIA驱动
install_nvidia_driver() {
    local use_dkms="$1"
    
    log "安装NVIDIA驱动 (DKMS: $use_dkms)..."
    
    case "$PKG_MANAGER" in
        "pacman")
            if [[ "$use_dkms" == "true" ]]; then
                log "安装NVIDIA DKMS驱动..."
                $INSTALL_CMD nvidia-dkms nvidia-utils nvidia-settings
                # DKMS版本不需要手动添加到mkinitcpio，会自动处理
                log "配置mkinitcpio hooks..."
                if ! grep -q "nvidia" /etc/mkinitcpio.conf; then
                    sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
                fi
                # 确保dkms hook存在
                if ! grep -q "dkms" /etc/mkinitcpio.conf; then
                    sed -i 's/HOOKS=(/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck dkms /' /etc/mkinitcpio.conf
                fi
                mkinitcpio -P
            else
                log "安装NVIDIA预编译驱动..."
                $INSTALL_CMD nvidia nvidia-utils nvidia-settings
                if ! grep -q "nvidia" /etc/mkinitcpio.conf; then
                    sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
                    mkinitcpio -P
                fi
            fi
            ;;
        "emerge")
            warn "Gentoo NVIDIA驱动安装需要手动配置"
            echo "推荐步骤:"
            echo "1. 在内核中启用: Device Drivers -> Graphics support -> Direct Rendering Manager"
            echo "2. 添加USE标志: echo 'x11-drivers/nvidia-drivers tools' >> /etc/portage/package.use"
            if [[ "$use_dkms" == "true" ]]; then
                echo "3. 安装DKMS: emerge sys-kernel/dkms"
                echo "4. 安装驱动: emerge x11-drivers/nvidia-drivers"
                echo "5. 添加DKMS模块: dkms add nvidia/$(nvidia-settings --version | grep version | cut -d' ' -f4)"
            else
                echo "3. 安装驱动: emerge x11-drivers/nvidia-drivers"
            fi
            read -p "是否继续自动安装? (y/N): " auto_install
            if [[ "$auto_install" =~ ^[Yy]$ ]]; then
                echo 'x11-drivers/nvidia-drivers tools' >> /etc/portage/package.use
                if [[ "$use_dkms" == "true" ]]; then
                    $INSTALL_CMD sys-kernel/dkms
                fi
                $INSTALL_CMD x11-drivers/nvidia-drivers
            fi
            ;;
        "apt")
            log "添加NVIDIA驱动源..."
            add-apt-repository -y ppa:graphics-drivers/ppa
            $UPDATE_CMD
            
            if [[ "$use_dkms" == "true" ]]; then
                log "安装NVIDIA DKMS驱动..."
                $INSTALL_CMD nvidia-driver-470 nvidia-dkms-470 nvidia-settings
            else
                log "安装NVIDIA预编译驱动..."
                $INSTALL_CMD nvidia-driver-470 nvidia-settings
            fi
            ;;
        "dnf")
            log "启用RPM Fusion..."
            $INSTALL_CMD https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
            $INSTALL_CMD https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
            
            if [[ "$use_dkms" == "true" ]]; then
                log "安装NVIDIA DKMS驱动 (akmod)..."
                $INSTALL_CMD akmod-nvidia xorg-x11-drv-nvidia-cuda
                log "akmod-nvidia使用类似DKMS的自动编译机制"
            else
                log "安装NVIDIA预编译驱动..."
                $INSTALL_CMD xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda
            fi
            ;;
        "yum")
            warn "CentOS/RHEL需要手动配置EPEL和ELRepo仓库"
            echo "建议步骤:"
            echo "1. 安装EPEL: yum install epel-release"
            echo "2. 安装ELRepo: yum install elrepo-release"
            echo "3. 安装驱动: yum install nvidia-x11-drv"
            ;;
        "zypper")
            log "安装NVIDIA驱动..."
            if [[ "$use_dkms" == "true" ]]; then
                $INSTALL_CMD nvidia-gfxG05-kmp-default nvidia-glG05 nvidia-settings
                log "openSUSE使用KMP (Kernel Module Package) 系统，类似DKMS"
            else
                $INSTALL_CMD x11-video-nvidiaG05 nvidia-glG05 nvidia-settings
            fi
            ;;
    esac
}

# 安装AMD驱动
install_amd_driver() {
    local use_dkms="$1"
    
    log "安装AMD驱动 (开源Mesa驱动)..."
    
    # AMD主要使用开源驱动，DKMS主要影响内核模块
    case "$PKG_MANAGER" in
        "pacman")
            $INSTALL_CMD mesa xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa-vdpau
            if [[ "$use_dkms" == "true" ]]; then
                log "AMD开源驱动通常不需要DKMS，内核模块已包含在内核中"
                # 如果需要特殊的AMD驱动（如AMDGPU-PRO），可以在这里添加
            fi
            ;;
        "emerge")
            log "配置AMD驱动USE标志..."
            echo 'media-libs/mesa vulkan' >> /etc/portage/package.use
            echo 'x11-libs/libdrm video_cards_amdgpu video_cards_radeon' >> /etc/portage/package.use
            $INSTALL_CMD media-libs/mesa x11-drivers/xf86-video-amdgpu media-libs/vulkan-loader
            if [[ "$use_dkms" == "true" ]]; then
                log "AMD开源驱动已集成在内核中，通常不需要额外的DKMS模块"
            fi
            ;;
        "apt")
            $INSTALL_CMD mesa-vulkan-drivers xserver-xorg-video-amdgpu libva-mesa-driver
            if [[ "$use_dkms" == "true" ]]; then
                log "检查是否需要安装额外的AMD驱动包..."
                # 可以添加AMDGPU-PRO驱动的DKMS支持
            fi
            ;;
        "dnf")
            $INSTALL_CMD mesa-dri-drivers mesa-vulkan-drivers xorg-x11-drv-amdgpu
            if [[ "$use_dkms" == "true" ]]; then
                log "AMD开源驱动已包含在内核中"
            fi
            ;;
        "zypper")
            $INSTALL_CMD Mesa-dri Mesa-gallium xf86-video-amdgpu
            ;;
    esac
}

# 安装显卡驱动主函数
install_gpu_drivers() {
    log "检测显卡并安装驱动..."
    
    if ! check_root; then
        return 1
    fi
    
    # 检测显卡
    GPU_INFO=$(lspci | grep -E "VGA|3D|Display")
    echo -e "${BLUE}检测到的显卡:${NC}"
    echo "$GPU_INFO"
    echo
    
    # 询问是否使用DKMS
    echo -e "${CYAN}=== 驱动安装选项 ===${NC}"
    echo -e "${BLUE}DKMS (Dynamic Kernel Module Support) 说明:${NC}"
    echo "• ✅ 内核更新时自动重新编译驱动模块"
    echo "• ✅ 支持多个内核版本并存"
    echo "• ✅ 减少内核升级后驱动失效问题"
    echo "• ⚠️  需要编译工具链，安装时间较长"
    echo "• ⚠️  可能出现编译失败的情况"
    echo
    echo "选择安装方式:"
    echo "1. 🚀 预编译驱动 (推荐，快速安装)"
    echo "2. 🔧 DKMS驱动 (自动适配内核更新)"
    echo "3. 📋 显示详细信息后选择"
    echo
    read -p "请选择 (1-3): " driver_choice
    
    local use_dkms="false"
    case $driver_choice in
        2)
            use_dkms="true"
            log "选择DKMS驱动模式"
            ;;
        3)
            echo -e "${BLUE}当前系统信息:${NC}"
            echo "内核版本: $(uname -r)"
            echo "系统架构: $(uname -m)"
            echo "发行版: $DISTRO_NAME"
            echo "包管理器: $PKG_MANAGER"
            echo
            read -p "是否使用DKMS驱动? (y/N): " dkms_confirm
            if [[ "$dkms_confirm" =~ ^[Yy]$ ]]; then
                use_dkms="true"
            fi
            ;;
        *)
            log "选择预编译驱动模式"
            ;;
    esac
    
    # 如果选择DKMS，检查依赖
    if [[ "$use_dkms" == "true" ]]; then
        if ! check_dkms_dependencies; then
            error "DKMS依赖检查失败，回退到预编译驱动"
            use_dkms="false"
        fi
    fi
    
    # 安装NVIDIA驱动
    if echo "$GPU_INFO" | grep -i nvidia &> /dev/null; then
        log "检测到NVIDIA显卡"
        install_nvidia_driver "$use_dkms"
        success "NVIDIA驱动安装完成"
    fi
    
    # 安装AMD驱动
    if echo "$GPU_INFO" | grep -i amd &> /dev/null || echo "$GPU_INFO" | grep -i radeon &> /dev/null; then
        log "检测到AMD显卡"
        install_amd_driver "$use_dkms"
        success "AMD驱动安装完成"
    fi
    
    # 检查是否检测到显卡
    if ! echo "$GPU_INFO" | grep -iE "(nvidia|amd|radeon)" &> /dev/null; then
        warn "未检测到NVIDIA或AMD显卡"
        echo "检测到的显卡信息:"
        echo "$GPU_INFO"
        echo
        echo "如果您使用Intel集成显卡，通常不需要额外安装驱动"
        echo "如果您认为检测有误，请手动安装相应驱动"
    fi
    
    # 显示后续步骤
    echo
    echo -e "${CYAN}=== 安装完成 ===${NC}"
    if [[ "$use_dkms" == "true" ]]; then
        echo -e "${GREEN}✅ DKMS驱动安装完成${NC}"
        echo "• 内核更新时将自动重新编译驱动"
        echo "• 可以使用 'dkms status' 查看DKMS模块状态"
    else
        echo -e "${GREEN}✅ 预编译驱动安装完成${NC}"
        echo "• 内核更新后可能需要重新安装驱动"
    fi
    
    warn "显卡驱动更新需要重启系统才能生效"
    echo
    read -p "按Enter键继续..."
}

# 主程序
main() {
    # 检测系统
    detect_system
    
    while true; do
        show_main_menu
        read -p "请选择功能 (0-9): " choice
        
        case $choice in
            1)
                install_microcode
                ;;
            2)
                install_gpu_drivers
                ;;
            3)
                if [[ -f "$SCRIPT_DIR/modules/docker.sh" ]]; then
                    source "$SCRIPT_DIR/modules/docker.sh"
                    install_docker
                else
                    error "Docker模块文件不存在"
                fi
                ;;
            4)
                if [[ -f "$SCRIPT_DIR/modules/network.sh" ]]; then
                    source "$SCRIPT_DIR/modules/network.sh"
                    show_network_config
                else
                    error "网络模块文件不存在"
                fi
                ;;
            5)
                if [[ -f "$SCRIPT_DIR/modules/proxy.sh" ]]; then
                    source "$SCRIPT_DIR/modules/proxy.sh"
                    configure_transparent_proxy
                else
                    error "代理模块文件不存在"
                fi
                ;;
            6)
                if [[ -f "$SCRIPT_DIR/modules/kernel.sh" ]]; then
                    source "$SCRIPT_DIR/modules/kernel.sh"
                    install_custom_kernel
                else
                    error "内核模块文件不存在"
                fi
                ;;
            7)
                if [[ -f "$SCRIPT_DIR/modules/swap.sh" ]]; then
                    source "$SCRIPT_DIR/modules/swap.sh"
                    manage_swap
                else
                    error "Swap模块文件不存在"
                fi
                ;;
            8)
                if [[ -f "$SCRIPT_DIR/modules/process.sh" ]]; then
                    source "$SCRIPT_DIR/modules/process.sh"
                    manage_processes
                else
                    error "进程模块文件不存在"
                fi
                ;;
            9)
                log "更新系统..."
                if check_root; then
                    $UPDATE_CMD && success "系统更新完成"
                fi
                read -p "按Enter键继续..."
                ;;
            0)
                log "感谢使用Linux Toolkit!"
                exit 0
                ;;
            *)
                error "无效选择，请输入0-9"
                sleep 2
                ;;
        esac
    done
}

# 检查模块目录是否存在
if [[ ! -d "$SCRIPT_DIR/modules" ]]; then
    error "模块目录不存在: $SCRIPT_DIR/modules"
    error "请确保所有文件都在正确的位置"
    exit 1
fi

# 运行主程序
main "$@"
