# 🛠️ Linux 系统管理工具集

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Multi-Distro](https://img.shields.io/badge/Multi--Distro-Support-blue.svg)](#支持的发行版)
[![Docker](https://img.shields.io/badge/Docker-Supported-2496ED.svg)](https://www.docker.com/)

一个功能强大的 Linux 系统管理工具集，支持多种发行版，提供硬件管理、网络配置、容器化支持等全方位的系统管理功能。

## ✨ 主要特性

### 🌍 **多发行版支持**
- 🐧 **Arch Linux** (pacman) - 完全支持，包括AUR提示
- 🟠 **Ubuntu/Debian** (apt) - 完全支持，包括PPA管理
- 🔵 **Fedora** (dnf) - 完全支持，包括RPM Fusion
- 🔴 **CentOS/RHEL** (yum) - 完全支持，包括EPEL
- 🦎 **openSUSE** (zypper) - 完全支持，包括OBS
- 🟣 **Gentoo** (emerge) - 完全支持，包括USE标志配置

### 🔧 **核心功能**
- 🖥️ **硬件管理** - CPU微码、显卡驱动自动检测安装，支持DKMS动态编译
- 🐳 **容器化支持** - Docker完整安装配置和镜像加速器
- 🌐 **网络诊断** - 完整的网络配置、故障排除和性能测试
- ⚙️ **系统优化** - 内核管理、Swap优化、进程监控
- 📦 **模块化设计** - 独立功能模块，便于维护和扩展
- 🔒 **透明代理** - 网络代理配置和管理
- 🔧 **DKMS支持** - 动态内核模块支持，自动适配内核更新

## 🎯 支持的发行版

| 发行版 | 包管理器 | 特殊支持 | 状态 |
|--------|----------|----------|------|
| **Arch Linux** | `pacman` | AUR提示、mkinitcpio配置 | ✅ 完全支持 |
| **Gentoo** | `emerge` | USE标志、内核编译指导 | ✅ 完全支持 |
| **Ubuntu/Debian** | `apt` | PPA管理、snap支持 | ✅ 完全支持 |
| **Fedora** | `dnf` | RPM Fusion、Flatpak | ✅ 完全支持 |
| **CentOS/RHEL** | `yum` | EPEL仓库、企业支持 | ✅ 完全支持 |
| **openSUSE** | `zypper` | OBS仓库、Tumbleweed | ✅ 完全支持 |

## 📁 项目结构

```
linux-tools/
├── 📄 linux-toolkit.sh            # 主工具脚本
├── 📁 modules/                     # 功能模块
│   ├── 🐳 docker.sh              # Docker管理
│   ├── 🌐 network.sh             # 网络配置
│   ├── 🔒 proxy.sh               # 透明代理
│   ├── 🔧 kernel.sh              # 内核管理
│   ├── 💾 swap.sh                # Swap管理
│   └── ⚙️ process.sh             # 进程管理
└── 📖 README.md                  # 项目说明
```

## 🚀 快速开始

### 1. 下载工具

#### 方法一：Git克隆（推荐）
```bash
git clone https://github.com/Tehsky/linux-toolkit.git
cd linux-toolkit
```

#### 方法二：直接下载
```bash
curl -L https://github.com/Tehsky/linux-toolkit/archive/main.zip -o linux-toolkit.zip
unzip linux-toolkit.zip
cd linux-toolkit-main
```

#### 方法三：单独下载主脚本
```bash
curl -O https://raw.githubusercontent.com/Tehsky/linux-toolkit/main/linux-toolkit.sh
chmod +x linux-toolkit.sh
```

### 2. 运行工具

```bash
# 给脚本执行权限
chmod +x linux-toolkit.sh

# 运行主工具（需要root权限）
sudo ./linux-toolkit.sh
```

### 3. 选择功能

工具会显示交互式菜单，选择您需要的功能：

```
=== Linux 系统管理工具 ===
1. 📦 安装处理器微码 (自动识别Intel/AMD)
2. 🎮 安装显卡驱动 (AMD开源/NVIDIA闭源)
3. 🐳 安装Docker并配置加速器
4. 🌐 查看网络配置 (IP/网关/DNS)
5. 🔒 配置透明代理 (主流翻墙软件)
6. 🔧 安装第三方内核
7. 💾 Swap管理
8. ⚙️ 系统进程管理
9. 🔄 系统更新
0. 🚪 退出
```

**🔒 透明代理菜单 (选项5)**：
```
=== 透明代理配置 ===
1. 🦄 V2Ray/Xray (推荐)
2. 🐱 Clash/Clash Meta
3. 🔒 Shadowsocks + iptables
4. 🌐 Trojan-Go
5. 📡 Hysteria
6. ⚡ SingBox
7. 🔧 自定义透明代理规则
8. 🌐 配置TUN模式代理
9. 💻 配置终端代理环境
10. 📊 查看代理状态
11. 🔍 检查依赖项
12. 🗑️ 卸载代理软件
0. 返回主菜单
```

## 🔧 功能详解

### 🖥️ 硬件管理

<details>
<summary><strong>📦 处理器微码管理</strong></summary>

**功能说明**：
- ✅ 自动检测 Intel/AMD 处理器
- ✅ 安装对应的微码更新
- ✅ 自动更新引导配置

**支持的微码**：
- **Intel**: `intel-ucode` (Arch), `intel-microcode` (Debian), `microcode_ctl` (RHEL)
- **AMD**: `amd-ucode` (Arch), `amd64-microcode` (Debian), `linux-firmware` (Gentoo)

**使用场景**：修复处理器安全漏洞，提升系统稳定性
</details>

<details>
<summary><strong>🎮 显卡驱动管理 - 全新DKMS支持</strong></summary>

**🆕 新增功能**：
- ✅ **DKMS支持** - 内核更新时自动重新编译驱动模块
- ✅ **智能依赖检测** - 自动检查和安装编译工具链
- ✅ **多模式选择** - 预编译驱动 vs DKMS驱动
- ✅ **详细状态显示** - 实时显示安装进度和状态

**功能说明**：
- ✅ 自动检测显卡类型 (NVIDIA/AMD/Intel)
- ✅ 智能选择最佳驱动安装方式
- ✅ 配置必要的系统设置和内核模块
- ✅ 支持多内核版本并存

**DKMS (Dynamic Kernel Module Support)**：
- 🔧 **自动编译** - 内核更新时自动重新编译驱动
- 🔧 **多内核支持** - 支持多个内核版本同时使用
- 🔧 **依赖管理** - 自动检测并安装必要的编译工具
- 🔧 **错误恢复** - 编译失败时提供预编译驱动备选方案

**NVIDIA 支持**：
- **预编译模式**: 快速安装，适合稳定环境
  - `nvidia` (Arch), `nvidia-driver-470` (Ubuntu)
- **DKMS模式**: 自动适配内核更新
  - `nvidia-dkms` (Arch), `nvidia-dkms-470` (Ubuntu)
  - `akmod-nvidia` (Fedora) - 类DKMS自动编译
- 自动配置内核模块和mkinitcpio
- 支持 CUDA 和 OpenGL
- 完整的多发行版支持

**AMD 支持**：
- 安装开源 Mesa 驱动生态
- 支持 Vulkan 和 OpenGL
- 硬件视频加速配置
- AMDGPU 内核模块自动配置
- 注：AMD开源驱动已集成在内核中，通常不需要DKMS

**安装选项**：
```
选择安装方式:
1. 🚀 预编译驱动 (推荐，快速安装)
2. 🔧 DKMS驱动 (自动适配内核更新)
3. 📋 显示详细信息后选择
```

**DKMS优势**：
- ✅ 内核升级后驱动自动可用
- ✅ 支持自定义内核 (Xanmod, Zen等)
- ✅ 多内核版本并存支持
- ✅ 减少手动维护工作

**预编译优势**：
- ⚡ 安装速度极快
- 💾 不占用编译资源
- 🛡️ 稳定性更高
- 📦 包管理器直接管理

**发行版特殊支持**：
- **Arch Linux**: 完整DKMS支持，自动配置mkinitcpio hooks
- **Gentoo**: USE标志自动配置，提供内核编译指导
- **Ubuntu/Debian**: PPA源管理，DKMS包自动安装
- **Fedora**: akmod自动编译系统 (类似DKMS)
- **openSUSE**: KMP (Kernel Module Package) 支持

**使用场景建议**：
- **选择DKMS**: 频繁更新内核、使用多个内核、开发环境
- **选择预编译**: 生产环境、稳定系统、快速部署
</details>

### 🐳 Docker 容器化

<details>
<summary><strong>Docker 完整管理</strong></summary>

**安装功能**：
- ✅ 一键安装 Docker 和 Docker Compose
- ✅ 自动启用和启动服务
- ✅ 用户组权限配置

**镜像加速器**：
- 🇨🇳 中科大镜像 (推荐)
- 🇨🇳 网易镜像
- 🇨🇳 百度镜像
- 🇨🇳 腾讯云镜像
- 🇨🇳 阿里云镜像 (需注册)
- 🔧 自定义镜像地址
- 📊 镜像拉取速度测试

**管理功能**：
- 查看 Docker 状态和容器
- 清理未使用的资源
- 配置备份和恢复
- 故障排除工具

**Gentoo 特殊支持**：
- 自动添加 Docker USE 标志
- OpenRC 服务配置
- 编译优化设置
</details>

### 🌐 网络管理

<details>
<summary><strong>网络配置和诊断</strong></summary>

**网络信息**：
- ✅ IP 地址和网关信息
- ✅ DNS 配置查看
- ✅ 网络接口状态
- ✅ 路由表显示

**连接测试**：
- ✅ 网络连通性测试
- ✅ DNS 解析测试
- ✅ 网络速度测试 (需要 speedtest-cli)
- ✅ 延迟和丢包检测

**故障排除**：
- ✅ 网络服务重启
- ✅ DNS 刷新
- ✅ 网络配置重置
- ✅ 防火墙状态检查
</details>

### 🔒 透明代理

<details>
<summary><strong>代理配置管理 - 全新升级</strong></summary>

**🆕 新增功能**：
- ✅ **自动依赖检测** - 智能检测并安装缺失的组件
- ✅ **多源安装** - 支持多个下载源，提高安装成功率
- ✅ **终端代理配置** - 一键配置终端环境变量
- ✅ **TUN模式支持** - 支持TUN网卡透明代理
- ✅ **错误恢复** - 安装失败时自动重试和备用方案

**支持的代理软件**：
- 🦄 **V2Ray/Xray** (推荐) - 功能强大的代理工具
- 🐱 **Clash/Clash Meta** - 现代化代理客户端
- 🔒 **Shadowsocks** - 轻量级代理协议
- 🌐 **Trojan-Go** - 伪装流量代理
- 📡 **Hysteria** - 基于QUIC的高速代理
- ⚡ **SingBox** - 通用代理平台

**代理模式**：
- **透明代理模式** - iptables规则自动配置
- **TUN模式** - 虚拟网卡流量劫持
- **HTTP/HTTPS代理** - 标准代理协议
- **SOCKS5代理** - 通用代理协议

**智能功能**：
- 🔍 **依赖检查** - 自动检测curl、wget、iptables等必需工具
- 🔄 **重试机制** - 下载失败时自动尝试备用源
- ⚙️ **错误处理** - 完善的错误恢复和回退机制
- 📊 **状态监控** - 实时查看代理服务状态
- 💻 **终端集成** - 自动配置shell环境变量

**终端代理管理**：
```bash
px      # 开启代理
pxoff   # 关闭代理
pxs     # 查看代理状态
```

**使用场景**：
- 网络访问优化和加速
- 开发环境代理配置
- 服务器透明代理部署
- 网络流量管理和监控
</details>

### ⚙️ 系统优化

<details>
<summary><strong>🔧 内核管理</strong></summary>

**内核安装**：
- ✅ **Xanmod 内核** - 高性能优化内核
- ✅ **Zen 内核** - 桌面优化内核  
- ✅ **LTS 内核** - 长期支持稳定内核
- ✅ **自定义内核** - 用户自定义配置

**内核管理**：
- 查看已安装内核列表
- 删除旧版本内核
- 内核参数配置
- 引导配置更新

**Gentoo 特殊支持**：
- 内核源码管理
- 编译配置指导
- USE 标志优化
- 手动编译步骤
</details>

<details>
<summary><strong>💾 Swap 管理</strong></summary>

**Swap 配置**：
- ✅ 创建 Swap 文件
- ✅ 调整 Swap 大小
- ✅ Swap 优先级设置
- ✅ Swappiness 调优

**性能优化**：
- 内存使用监控
- Swap 使用统计
- 性能建议
- 自动优化配置

**使用场景**：
- 内存不足系统
- 休眠功能需求
- 性能调优
- 服务器优化
</details>

<details>
<summary><strong>⚙️ 进程管理</strong></summary>

**进程监控**：
- ✅ 实时进程查看
- ✅ CPU 和内存使用率
- ✅ 进程树显示
- ✅ 资源占用排序

**进程控制**：
- 进程启动和停止
- 信号发送
- 优先级调整
- 服务管理

**系统监控**：
- 系统负载查看
- 资源使用统计
- 性能瓶颈分析
- 故障诊断
</details>

## 📋 使用示例

### 基本使用流程

```bash
# 1. 下载并运行工具
sudo ./linux-toolkit.sh

# 2. 选择功能（例如：安装Docker）
# 选择菜单项 3 - Docker管理

# 3. 按照提示完成配置
# 工具会自动检测系统并安装相应软件包
```

### 高级使用技巧

```bash
# 直接运行特定模块
sudo bash modules/docker.sh

# 检查系统兼容性
./linux-toolkit.sh --check

# 查看详细日志
./linux-toolkit.sh --verbose
```

## 🛠️ 故障排除

### 常见问题

<details>
<summary><strong>❓ 包管理器检测失败</strong></summary>

**可能原因**：
- 不支持的发行版
- 包管理器未安装
- 权限不足

**解决方案**：
```bash
# 检查发行版信息
cat /etc/os-release

# 检查包管理器
which pacman apt dnf yum zypper emerge

# 确保以root权限运行
sudo ./linux-toolkit.sh
```
</details>

<details>
<summary><strong>❓ Docker安装失败</strong></summary>

**解决方案**：
```bash
# 检查系统架构
uname -m

# 清理旧的Docker安装
sudo apt remove docker docker-engine docker.io containerd runc  # Debian/Ubuntu
sudo pacman -R docker docker-compose  # Arch Linux

# 重新运行安装
sudo ./linux-toolkit.sh
```
</details>

<details>
<summary><strong>❓ 网络功能异常</strong></summary>

**解决方案**：
```bash
# 检查网络服务
sudo systemctl status NetworkManager
sudo systemctl status systemd-networkd

# 重启网络服务
sudo systemctl restart NetworkManager

# 检查防火墙
sudo ufw status  # Ubuntu
sudo firewall-cmd --state  # RHEL/Fedora
```
</details>

<details>
<summary><strong>❓ 透明代理安装失败</strong></summary>

**可能原因**：
- 网络连接问题
- GitHub访问受限
- 依赖项缺失
- 权限不足

**解决方案**：
```bash
# 检查网络连接
ping -c 3 github.com

# 手动检查依赖项
sudo ./linux-toolkit.sh
# 选择 5 -> 11 (检查依赖项)

# 清理失败的安装
sudo systemctl stop v2ray xray clash 2>/dev/null
sudo rm -f /usr/local/bin/{v2ray,xray,clash}

# 使用代理安装（如果有其他代理）
export http_proxy=http://127.0.0.1:8080
sudo -E ./linux-toolkit.sh
```
</details>

<details>
<summary><strong>❓ TUN设备不可用</strong></summary>

**解决方案**：
```bash
# 检查TUN模块
lsmod | grep tun

# 加载TUN模块
sudo modprobe tun

# 永久加载TUN模块
echo 'tun' | sudo tee -a /etc/modules-load.d/tun.conf

# 检查TUN设备
ls -la /dev/net/tun

# 如果设备不存在，创建设备节点
sudo mkdir -p /dev/net
sudo mknod /dev/net/tun c 10 200
sudo chmod 666 /dev/net/tun
```
</details>

<details>
<summary><strong>❓ 终端代理环境变量无效</strong></summary>

**解决方案**：
```bash
# 重新加载配置文件
source /etc/profile.d/proxy.sh

# 检查环境变量
echo $http_proxy
echo $https_proxy
echo $all_proxy

# 手动设置代理
export http_proxy=http://127.0.0.1:8080
export https_proxy=http://127.0.0.1:8080
export all_proxy=socks5://127.0.0.1:1080

# 测试代理连接
curl -I --proxy $http_proxy https://www.google.com
```
</details>

<details>
<summary><strong>❓ Gentoo编译问题</strong></summary>

**解决方案**：
```bash
# 更新Portage树
sudo emerge --sync

# 检查USE标志
emerge --info | grep USE

# 查看编译日志
tail -f /var/tmp/portage/*/temp/build.log

# 清理失败的编译
sudo emerge --clean
```
</details>

## 🔧 自定义配置

### 添加新的发行版支持

```bash
# 在主脚本中添加包管理器检测
if command -v your_package_manager &> /dev/null; then
    PKG_MANAGER="your_package_manager"
    INSTALL_CMD="your_install_command"
    # ... 其他配置
fi
```

### 创建自定义模块

```bash
# 创建新模块文件
cat > modules/custom.sh << 'EOF'
#!/bin/bash

# 自定义功能函数
custom_function() {
    echo "执行自定义功能..."
    # 您的代码
}
EOF

# 在主脚本中调用
source "$SCRIPT_DIR/modules/custom.sh"
custom_function
```

## 🤝 贡献指南

欢迎贡献代码和建议！

### 如何贡献
1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 开发规范
- 使用 Bash 编写脚本
- 添加详细的注释
- 遵循现有代码风格
- 测试所有支持的发行版
- 更新相关文档

### 报告问题
- 使用 [GitHub Issues](https://github.com/Tehsky/linux-toolkit/issues)
- 提供详细的错误信息
- 包含系统环境信息
- 附上相关日志文件

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- 各 Linux 发行版社区
- Docker 开发团队
- 开源软件贡献者
- 所有用户和贡献者

## ⭐ Star History

如果这个项目对您有帮助，请给个 Star ⭐

---

<div align="center">

**🛠️ 让 Linux 系统管理更简单！**

[⬆️ 回到顶部](#️-linux-系统管理工具集)

</div>
