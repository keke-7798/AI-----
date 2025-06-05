#!/bin/bash

# 苹果Vision优化OCR图片重命名工具
# 基于苹果官方文档的最佳实践

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 打印苹果风格标题
print_header() {
    echo -e "${WHITE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║             🍎 苹果Vision优化OCR工具                 ║${NC}"
    echo -e "${WHITE}║                                                      ║${NC}"
    echo -e "${CYAN}║  🚀 基于苹果官方最佳实践优化：                      ║${NC}"
    echo -e "${CYAN}║  • Fast + Accurate 双路径识别                       ║${NC}"
    echo -e "${CYAN}║  • 智能候选文本合并策略                             ║${NC}"
    echo -e "${CYAN}║  • 多因素综合评分算法                               ║${NC}"
    echo -e "${CYAN}║  • 自适应语言校正                                   ║${NC}"
    echo -e "${CYAN}║  • 区域感兴趣优化（待实现）                         ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 显示苹果Vision优化特性
show_apple_features() {
    echo -e "${PURPLE}🔬 苹果Vision技术特性:${NC}"
    echo -e "${BLUE}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│  Fast路径   │ 字符检测 + 小型ML模型 (传统OCR)      │${NC}"
    echo -e "${BLUE}│  Accurate路径│ 神经网络 + 文本行分析 (类人识别)      │${NC}"
    echo -e "${BLUE}│  双路径合并  │ 优先精确路径，补充快速路径独有结果     │${NC}"
    echo -e "${BLUE}│  智能评分    │ 置信度+优先级+长度+方法综合评分       │${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${PURPLE}📊 评分算法 (基于苹果推荐):${NC}"
    echo -e "  • 置信度评分: 40% (OCR识别置信度)"
    echo -e "  • 优先级评分: 30% (编码模式重要性)"
    echo -e "  • 长度评分:   20% (编码长度权重)"
    echo -e "  • 方法加分:   10% (Accurate模式加分)"
    echo ""
}

# 显示编码识别策略
show_recognition_strategy() {
    echo -e "${PURPLE}🎯 编码识别策略 (优先级排序):${NC}"
    echo -e "${GREEN}  1. 完整编码含尺寸${NC} - A3422300021Y00R14.5 (包含小数点尺寸)"
    echo -e "${GREEN}  2. 长字母数字编码${NC} - A1243100395WDBN42 (8位以上)"
    echo -e "${GREEN}  3. 复合编码格式${NC}   - 字母开头+数字+字母数字+尺寸"
    echo -e "${GREEN}  4. 小数点编码${NC}     - 13.2, 15.6 (数字.数字)"
    echo -e "${GREEN}  5. 特殊分隔符编码${NC} - A-123, B_456 (含分隔符)"
    echo -e "${GREEN}  6. 纯数字编码${NC}     - 123456, 789 (2位以上数字)"
    echo -e "${GREEN}  7. 字母数字混合${NC}   - AB123, C45 (字母+数字)"
    echo ""
}

# 检查系统环境
check_environment() {
    echo -e "${CYAN}🔍 检查系统环境...${NC}"
    
    # 检查 Swift
    if ! command -v swift &> /dev/null; then
        echo -e "${RED}❌ 错误: 未找到 Swift 编译器${NC}"
        echo -e "${YELLOW}请安装 Xcode 或 Swift 工具链${NC}"
        exit 1
    fi
    
    # 检查 macOS 版本
    local macos_version=$(sw_vers -productVersion)
    echo -e "${GREEN}✅ macOS 版本: $macos_version${NC}"
    
    # 检查是否支持 Vision 框架
    if [[ $(echo "$macos_version" | cut -d. -f1) -lt 10 ]] || 
       [[ $(echo "$macos_version" | cut -d. -f1) -eq 10 && $(echo "$macos_version" | cut -d. -f2) -lt 15 ]]; then
        echo -e "${YELLOW}⚠️  警告: macOS 版本可能不支持最新 Vision 特性${NC}"
        echo -e "${YELLOW}   建议使用 macOS 10.15 或更高版本${NC}"
    fi
    
    echo -e "${GREEN}✅ Swift 编译器检查通过${NC}"
    echo ""
}

# 获取目录路径
get_directory() {
    if [ $# -eq 1 ]; then
        DIRECTORY="$1"
    else
        echo -e "${BLUE}📁 请拖拽图片文件夹到此处，然后按回车:${NC}"
        read -r DIRECTORY
        
        # 清理路径
        DIRECTORY=$(echo "$DIRECTORY" | sed 's/^["'\'']//' | sed 's/["'\'']$//' | sed 's/\\\([^\\]\)/\1/g')
    fi
    
    # 验证目录
    if [ ! -d "$DIRECTORY" ]; then
        echo -e "${RED}❌ 错误: 目录不存在: $DIRECTORY${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 目录路径: $DIRECTORY${NC}"
    echo ""
}

# 检查图片文件
check_images() {
    local count=$(find "$DIRECTORY" -maxdepth 1 \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" \) | wc -l)
    
    if [ "$count" -eq 0 ]; then
        echo -e "${RED}❌ 错误: 目录中没有找到图片文件${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 找到 $count 个图片文件${NC}"
    echo -e "${CYAN}📋 支持格式: JPG, JPEG, PNG, HEIC${NC}"
    echo ""
}

# 显示处理预览
show_preview() {
    echo -e "${PURPLE}🔮 处理预览:${NC}"
    echo -e "${BLUE}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│  1. 使用Fast路径快速扫描所有图片                    │${NC}"
    echo -e "${BLUE}│  2. 使用Accurate路径精确分析所有图片                │${NC}"
    echo -e "${BLUE}│  3. 智能合并两个路径的识别结果                      │${NC}"
    echo -e "${BLUE}│  4. 应用苹果推荐的多因素评分算法                    │${NC}"
    echo -e "${BLUE}│  5. 选择最佳编码候选并进行分组                      │${NC}"
    echo -e "${BLUE}│  6. 按照时间顺序执行重命名                          │${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# 运行苹果优化OCR
run_apple_optimized_ocr() {
    echo -e "${CYAN}🚀 启动苹果Vision优化处理...${NC}"
    echo ""
    
    # 编译并运行 Swift 程序
    if swift AppleVisionOptimizedRenamer.swift "$DIRECTORY"; then
        echo -e "${GREEN}🎉 苹果Vision优化处理完成!${NC}"
        echo ""
        show_completion_stats
    else
        echo -e "${RED}❌ 程序执行失败${NC}"
        exit 1
    fi
}

# 显示完成统计
show_completion_stats() {
    echo -e "${WHITE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                  🎯 处理完成统计                     ║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  使用技术: 苹果Vision双路径优化                      ║${NC}"
    echo -e "${CYAN}║  识别策略: Fast + Accurate 路径合并                 ║${NC}"
    echo -e "${CYAN}║  评分算法: 多因素综合评分                           ║${NC}"
    echo -e "${CYAN}║  排序方式: 按文件修改时间排序                       ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════╝${NC}"
}

# 显示使用建议
show_tips() {
    echo -e "${YELLOW}💡 苹果Vision优化建议:${NC}"
    echo ""
    echo -e "${PURPLE}📸 图片拍摄建议:${NC}"
    echo -e "  • 确保编码文字清晰、光线充足"
    echo -e "  • 尽量垂直拍摄，避免倾斜角度"
    echo -e "  • 编码区域占图片的合适比例"
    echo ""
    echo -e "${PURPLE}🔧 技术优势:${NC}"
    echo -e "  • 双路径识别提供更全面的候选结果"
    echo -e "  • 智能评分算法选择最佳编码"
    echo -e "  • 自适应语言校正优化识别准确性"
    echo ""
}

# 主程序
main() {
    print_header
    show_apple_features
    show_recognition_strategy
    show_tips
    check_environment
    get_directory "$@"
    check_images
    show_preview
    
    echo -e "${WHITE}🎬 开始苹果Vision优化处理...${NC}"
    echo ""
    
    run_apple_optimized_ocr
}

# 错误处理
set -e
trap 'echo -e "${RED}❌ 发生错误，程序终止${NC}"' ERR

# 运行主程序
main "$@" 