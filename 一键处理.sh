#!/bin/bash

# =============================================================================
# 🎯 AI OCR编码识别重命名工具 - 一键处理版
# =============================================================================
# 使用方法：
# 1. 双击运行此脚本
# 2. 将包含图片的文件夹拖拽到终端窗口
# 3. 按回车键开始处理
# =============================================================================

# 设置颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color
readonly BOLD='\033[1m'

# 清屏并显示欢迎界面
clear
echo -e "${BLUE}${BOLD}"
echo "███████╗███████╗██████╗     ████████╗ ██████╗  ██████╗ ██╗     "
echo "██╔══██║██╔════╝██╔══██╗    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     "
echo "██║  ██║██║     ██████╔╝       ██║   ██║   ██║██║   ██║██║     "
echo "██║  ██║██║     ██╔══██╗       ██║   ██║   ██║██║   ██║██║     "
echo "███████║███████╗██║  ██║       ██║   ╚██████╔╝╚██████╔╝███████╗"
echo "╚══════╝╚══════╝╚═╝  ╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "${CYAN}🎯 AI OCR编码识别重命名工具 - 一键处理版${NC}"
echo -e "${WHITE}=================================================${NC}"
echo ""

# 显示功能介绍
echo -e "${GREEN}📋 主要功能：${NC}"
echo -e "  ${YELLOW}•${NC} 智能识别图片中的产品编码"
echo -e "  ${YELLOW}•${NC} 自动检测系统文件标色进行分组"
echo -e "  ${YELLOW}•${NC} 批量重命名为标准格式"
echo -e "  ${YELLOW}•${NC} 支持 JPG、PNG、HEIC 等多种格式"
echo ""

echo -e "${GREEN}🎯 编码格式：${NC}${BOLD}A3422300021Y00R14.5${NC} (完整格式含尺寸)"
echo ""

# 环境检查
echo -e "${BLUE}🔍 正在检查运行环境...${NC}"

# 检查Swift是否可用
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Swift 未安装或不可用${NC}"
    echo -e "${YELLOW}💡 请确保已安装 Xcode 或 Command Line Tools${NC}"
    read -p "按回车键退出..." -r
    exit 1
fi

# 检查OCR工具是否存在
if [ ! -f "OCRRenamer_Optimized.swift" ]; then
    echo -e "${RED}❌ 找不到 OCRRenamer_Optimized.swift 文件${NC}"
    echo -e "${YELLOW}💡 请确保脚本和工具文件在同一目录${NC}"
    read -p "按回车键退出..." -r
    exit 1
fi

echo -e "${GREEN}✅ 环境检查通过${NC}"
echo ""

# 获取目录路径
directory=""
while [ -z "$directory" ] || [ ! -d "$directory" ]; do
    if [ -n "$directory" ]; then
        echo -e "${RED}❌ 路径无效，请重新输入${NC}"
        echo ""
    fi
    
    echo -e "${CYAN}📁 请选择包含图片的文件夹：${NC}"
    echo -e "${WHITE}方法1：${NC}直接拖拽文件夹到此窗口"
    echo -e "${WHITE}方法2：${NC}输入完整路径"
    echo ""
    echo -e "${YELLOW}💡 拖拽文件夹后按回车键继续...${NC}"
    
    read -r input_directory
    
    # 去除引号和前后空格
    directory=$(echo "$input_directory" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed "s/^['\"]//;s/['\"]$//")
    
    if [ -z "$directory" ]; then
        echo -e "${YELLOW}⚠️  请输入有效的文件夹路径${NC}"
        echo ""
        continue
    fi
done

echo ""
echo -e "${GREEN}📂 选择的目录：${NC}${BOLD}$directory${NC}"

# 预览文件
echo ""
echo -e "${BLUE}🔍 正在扫描文件...${NC}"

# 计算图片文件数量
image_count=0
for ext in jpg jpeg png heic heif tiff bmp JPG JPEG PNG HEIC HEIF TIFF BMP; do
    count=$(find "$directory" -maxdepth 1 -name "*.$ext" 2>/dev/null | wc -l)
    image_count=$((image_count + count))
done

if [ $image_count -eq 0 ]; then
    echo -e "${RED}❌ 未找到支持的图片文件${NC}"
    echo -e "${YELLOW}💡 支持的格式：JPG, PNG, HEIC, HEIF, TIFF, BMP${NC}"
    read -p "按回车键退出..." -r
    exit 1
fi

echo -e "${GREEN}📸 找到 ${BOLD}$image_count${NC}${GREEN} 个图片文件${NC}"

# 显示文件预览（最多显示10个）
echo ""
echo -e "${CYAN}📋 文件预览：${NC}"
file_list=$(find "$directory" -maxdepth 1 \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.heic" -o -name "*.heif" -o -name "*.tiff" -o -name "*.bmp" -o -name "*.JPG" -o -name "*.JPEG" -o -name "*.PNG" -o -name "*.HEIC" -o -name "*.HEIF" -o -name "*.TIFF" -o -name "*.BMP" \) 2>/dev/null | head -10)

count=0
while IFS= read -r file; do
    if [ -n "$file" ]; then
        filename=$(basename "$file")
        echo -e "  ${YELLOW}•${NC} $filename"
        count=$((count + 1))
    fi
done <<< "$file_list"

if [ $image_count -gt 10 ]; then
    echo -e "  ${PURPLE}... 还有 $((image_count - 10)) 个文件${NC}"
fi

echo ""

# 操作提示
echo -e "${WHITE}📋 操作说明：${NC}"
echo -e "  ${YELLOW}1.${NC} 工具会自动识别每张图片中的编码"
echo -e "  ${YELLOW}2.${NC} 检测系统文件标色进行智能分组"
echo -e "  ${YELLOW}3.${NC} 重命名为 ${BOLD}编码-标签.jpg${NC} 或 ${BOLD}编码-1.jpg${NC} 格式"
echo -e "  ${YELLOW}4.${NC} 识别失败时使用 ${BOLD}产品1-标签.jpg${NC} 备用格式"
echo ""

# 安全提示
echo -e "${RED}⚠️  安全提醒：${NC}"
echo -e "${RED}   • 此操作会重命名您的图片文件${NC}"
echo -e "${RED}   • 建议先备份重要文件${NC}"
echo -e "${RED}   • 处理过程中请勿关闭终端${NC}"
echo ""

# 确认处理
echo -e "${CYAN}🚀 准备开始处理...${NC}"
echo ""
read -p "$(echo -e ${GREEN}确认开始处理？${NC} [y/N]: )" -r confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⏹️  操作已取消${NC}"
    read -p "按回车键退出..." -r
    exit 0
fi

echo ""
echo -e "${BLUE}${BOLD}🔄 开始处理图片...${NC}"
echo "=================================================="

# 记录开始时间
start_time=$(date +%s)

# 运行OCR工具
swift OCRRenamer_Optimized.swift "$directory"

# 记录结束时间
end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo "=================================================="
echo -e "${GREEN}${BOLD}🎉 处理完成！${NC}"
echo ""

# 显示处理统计
echo -e "${CYAN}📊 处理统计：${NC}"
echo -e "  ${YELLOW}•${NC} 处理时间：${BOLD}${duration}秒${NC}"
echo -e "  ${YELLOW}•${NC} 文件总数：${BOLD}$image_count 个${NC}"

# 计算平均速度
if [ $duration -gt 0 ]; then
    avg_speed=$(echo "scale=1; $image_count / $duration" | bc 2>/dev/null || echo "N/A")
    echo -e "  ${YELLOW}•${NC} 平均速度：${BOLD}$avg_speed 张/秒${NC}"
fi

echo ""

# 查看结果提示
echo -e "${GREEN}📁 查看结果：${NC}"
echo -e "${WHITE}在 Finder 中打开处理的文件夹查看重命名结果${NC}"
echo ""

# 询问是否打开文件夹
read -p "$(echo -e ${CYAN}是否在 Finder 中打开结果文件夹？${NC} [Y/n]: )" -r open_finder

if [[ ! $open_finder =~ ^[Nn]$ ]]; then
    open "$directory"
    echo -e "${GREEN}✅ 已在 Finder 中打开文件夹${NC}"
else
    echo -e "${YELLOW}💡 您可以手动打开文件夹查看结果${NC}"
fi

echo ""

# 使用提示
echo -e "${PURPLE}💡 使用提示：${NC}"
echo -e "  ${YELLOW}•${NC} 检查重命名结果是否符合预期"
echo -e "  ${YELLOW}•${NC} 如有问题可手动调整个别文件名"
echo -e "  ${YELLOW}•${NC} 建议保存此工具以备后续使用"
echo ""

# 再次运行提示
echo -e "${CYAN}🔄 需要处理其他文件夹？${NC}"
read -p "$(echo -e ${GREEN}是否再次运行工具？${NC} [y/N]: )" -r restart

if [[ $restart =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}🚀 重新启动工具...${NC}"
    sleep 1
    exec "$0"  # 重新执行脚本
fi

echo ""
echo -e "${GREEN}${BOLD}感谢使用 AI OCR编码识别重命名工具！${NC}"
echo -e "${YELLOW}再见！👋${NC}"
echo ""

read -p "按回车键退出..." -r 