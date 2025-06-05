import Foundation
import Vision
import CoreImage
import AppKit

/**
 * 基于苹果Vision最佳实践的OCR图片重命名工具
 * 
 * 参考苹果官方文档优化：
 * - 结合Fast和Accurate识别路径
 * - 使用regionOfInterest优化性能
 * - 智能文本候选策略
 * - 自适应语言校正
 * - 多重验证机制
 */
class AppleVisionOptimizedRenamer {
    
    /**
     * 识别策略配置
     */
    struct RecognitionConfig {
        let useFastPath: Bool
        let useLanguageCorrection: Bool
        let minimumTextHeight: Float
        let regionOfInterest: CGRect?
        let maxCandidates: Int
        
        static let fastConfig = RecognitionConfig(
            useFastPath: true,
            useLanguageCorrection: false,
            minimumTextHeight: 0.02,
            regionOfInterest: nil,
            maxCandidates: 3
        )
        
        static let accurateConfig = RecognitionConfig(
            useFastPath: false,
            useLanguageCorrection: true,
            minimumTextHeight: 0.01,
            regionOfInterest: nil,
            maxCandidates: 5
        )
    }
    
    /**
     * 颜色标记定义 - 基于macOS文件系统颜色标签
     */
    enum ColorMarker: String, CaseIterable {
        case red = "红色"
        case orange = "橙色" 
        case yellow = "黄色"
        case green = "绿色"
        case blue = "蓝色"
        case purple = "紫色"
        case gray = "灰色"
        case none = "无标记"
        
        // macOS颜色标签对应值
        static func fromMacOSLabel(_ label: Int) -> ColorMarker {
            switch label {
            case 0: return .none      // 无标记
            case 1: return .gray      // 灰色
            case 2: return .green     // 绿色  
            case 3: return .purple    // 紫色
            case 4: return .blue      // 蓝色
            case 5: return .yellow    // 黄色
            case 6: return .red       // 红色
            case 7: return .orange    // 橙色
            default: return .none
            }
        }
        
        static func detect(from texts: [String]) -> ColorMarker {
            // 保留原有的文字检测功能作为备用
            let colorKeywords = [
                ColorMarker.red: ["红", "red", "赤", "朱", "红色", "红标", "Red", "RED"],
                ColorMarker.green: ["绿", "green", "青", "翠", "绿色", "绿标", "Green", "GREEN"],
                ColorMarker.blue: ["蓝", "blue", "蔚", "靛", "蓝色", "蓝标", "Blue", "BLUE"],
                ColorMarker.yellow: ["黄", "yellow", "金", "黄色", "黄标", "金色", "Yellow", "YELLOW"],
                ColorMarker.orange: ["橙", "orange", "橘", "橙色", "橙标", "橘色", "Orange", "ORANGE"],
                ColorMarker.purple: ["紫", "purple", "紫色", "紫标", "Purple", "PURPLE"],
                ColorMarker.gray: ["灰", "gray", "灰色", "灰标", "Gray", "GRAY"]
            ]
            
            // 遍历所有文本，寻找颜色关键词
            for text in texts {
                let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                for (color, keywords) in colorKeywords {
                    for keyword in keywords {
                        let normalizedKeyword = keyword.lowercased()
                        
                        // 精确匹配
                        if normalizedText == normalizedKeyword {
                            print("🎯 精确匹配颜色: \(text) -> \(color.rawValue)")
                            return color
                        }
                        
                        // 包含匹配
                        if normalizedText.contains(normalizedKeyword) {
                            print("🎯 包含匹配颜色: \(text) -> \(color.rawValue)")
                            return color
                        }
                    }
                }
            }
            
            return .none
        }
    }
    
    /**
     * 文本候选结果
     */
    struct TextCandidate {
        let text: String
        let confidence: Float
        let boundingBox: CGRect
        let recognitionLevel: VNRequestTextRecognitionLevel
    }
    
    /**
     * 产品信息结构
     */
    struct ProductInfo {
        let code: String
        let confidence: Float
        let colorMarker: ColorMarker
        let imagePath: String
        let allCandidates: [TextCandidate]
        let extractionMethod: String
    }
    
    /**
     * 处理指定目录中的图片 - 新的三步逻辑
     * 第一步：按照文件名排序
     * 第二步：根据颜色标签智能分组  
     * 第三步：识别编码给组文件重命名
     */
    func processImages(in directoryPath: String) {
        print("🔍 开始处理目录: \(directoryPath)")
        print("📖 使用苹果Vision优化策略 - 新三步工作流程")
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directoryPath) else {
            print("❌ 目录不存在: \(directoryPath)")
            return
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directoryPath)
            let imageFiles = contents.filter { file in
                let lowercased = file.lowercased()
                return lowercased.hasSuffix(".jpg") ||
                       lowercased.hasSuffix(".jpeg") ||
                       lowercased.hasSuffix(".png") ||
                       lowercased.hasSuffix(".heic")
            }
            
            guard !imageFiles.isEmpty else {
                print("❌ 目录中没有找到图片文件")
                return
            }
            
            // 🔧 第一步：按文件名排序（符合拍摄顺序）
            let sortedImageFiles = imageFiles.sorted()
            print("📸 找到 \(sortedImageFiles.count) 个图片文件")
            print("📋 第一步：按文件名排序完成（符合拍摄顺序）")
            
            // 🎨 第二步：根据颜色标签智能分组 - 修正版
            print("\n🎨 第二步：开始智能产品分组...")
            let productGroups = groupImagesByColorLabels(imageFiles: sortedImageFiles, directoryPath: directoryPath)
            
            // 🏷️ 第三步：处理每个颜色分组，识别编码并重命名
            print("\n🏷️ 第三步：开始编码识别和重命名...")
            processColorGroups(productGroups: productGroups, directoryPath: directoryPath)
            
        } catch {
            print("❌ 读取目录失败: \(error)")
        }
    }
    
    /**
     * 使用苹果Vision策略分析图片
     */
    private func analyzeImageWithAppleStrategy(at imagePath: String) -> ProductInfo? {
        guard let image = NSImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("❌ 无法加载图片: \(imagePath)")
            return nil
        }
        
        // 策略1: 快速路径识别（用于实时性要求高的场景）
        let fastCandidates = performTextRecognition(
            on: cgImage,
            config: RecognitionConfig.fastConfig
        )
        
        // 策略2: 精确路径识别（用于准确性要求高的场景）
        let accurateCandidates = performTextRecognition(
            on: cgImage,
            config: RecognitionConfig.accurateConfig
        )
        
        // 合并并去重候选结果
        let allCandidates = mergeCandidates(fast: fastCandidates, accurate: accurateCandidates)
        
        print("📝 识别结果统计:")
        print("   快速路径: \(fastCandidates.count) 个候选")
        print("   精确路径: \(accurateCandidates.count) 个候选")
        print("   合并后: \(allCandidates.count) 个候选")
        
        // 显示所有候选文本
        for (index, candidate) in allCandidates.enumerated() {
            let method = candidate.recognitionLevel == .fast ? "快速" : "精确"
            print("   \(index + 1). \(candidate.text) (置信度: \(String(format: "%.2f", candidate.confidence)), 方法: \(method))")
        }
        
        // 检测颜色标记
        let allTexts = allCandidates.map { $0.text }
        let colorMarker = ColorMarker.detect(from: allTexts)
        
        // 使用苹果推荐的智能编码提取
        if let codeInfo = extractCodeWithAppleStrategy(from: allCandidates) {
            return ProductInfo(
                code: codeInfo.code,
                confidence: codeInfo.confidence,
                colorMarker: colorMarker,
                imagePath: imagePath,
                allCandidates: allCandidates,
                extractionMethod: codeInfo.method
            )
        }
        
        return nil
    }
    
    /**
     * 执行文本识别（支持fast和accurate两种模式）
     */
    private func performTextRecognition(
        on cgImage: CGImage,
        config: RecognitionConfig
    ) -> [TextCandidate] {
        
        let request = VNRecognizeTextRequest()
        
        // 根据苹果文档配置请求
        request.recognitionLevel = config.useFastPath ? .fast : .accurate
        request.usesLanguageCorrection = config.useLanguageCorrection
        request.minimumTextHeight = config.minimumTextHeight
        request.recognitionLanguages = ["en-US", "zh-Hans"]
        
        // 设置感兴趣区域（苹果推荐用于性能优化）
        if let roi = config.regionOfInterest {
            request.regionOfInterest = roi
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("❌ OCR处理失败: \(error)")
            return []
        }
        
        guard let observations = request.results else {
            return []
        }
        
        var candidates: [TextCandidate] = []
        
        for observation in observations {
            let topCandidates = observation.topCandidates(config.maxCandidates)
            for candidate in topCandidates {
                candidates.append(TextCandidate(
                    text: candidate.string,
                    confidence: candidate.confidence,
                    boundingBox: observation.boundingBox,
                    recognitionLevel: request.recognitionLevel
                ))
            }
        }
        
        return candidates
    }
    
    /**
     * 合并快速和精确路径的候选结果
     */
    private func mergeCandidates(fast: [TextCandidate], accurate: [TextCandidate]) -> [TextCandidate] {
        var merged: [TextCandidate] = []
        var textSet: Set<String> = []
        
        // 优先添加精确路径的结果
        for candidate in accurate {
            let normalizedText = candidate.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !normalizedText.isEmpty && !textSet.contains(normalizedText) {
                merged.append(candidate)
                textSet.insert(normalizedText)
            }
        }
        
        // 补充快速路径独有的结果
        for candidate in fast {
            let normalizedText = candidate.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !normalizedText.isEmpty && !textSet.contains(normalizedText) {
                merged.append(candidate)
                textSet.insert(normalizedText)
            }
        }
        
        return merged
    }
    
    /**
     * 使用苹果策略提取产品编码
     */
    private func extractCodeWithAppleStrategy(from candidates: [TextCandidate]) -> (code: String, confidence: Float, method: String)? {
        
        // 苹果推荐的编码匹配策略 - 更新版本，支持完整编码格式
        struct CodePattern {
            let name: String
            let regex: String
            let priority: Int
            let minLength: Int
            let description: String
        }
        
        let patterns = [
            CodePattern(
                name: "完整编码含尺寸",
                regex: "^[A-Za-z0-9]{10,}\\d+\\.\\d+$",
                priority: 1,
                minLength: 12,
                description: "完整编码格式，末尾含尺寸小数点，如A3422300021Y00R14.5"
            ),
            CodePattern(
                name: "长字母数字编码",
                regex: "^[A-Za-z0-9]{8,}$",
                priority: 2,
                minLength: 8,
                description: "包含字母和数字的长编码"
            ),
            CodePattern(
                name: "复合编码格式",
                regex: "^[A-Za-z]\\d{8,}[A-Za-z0-9]+\\d+\\.\\d+$",
                priority: 3,
                minLength: 10,
                description: "复合编码：字母开头+数字+字母数字+尺寸"
            ),
            CodePattern(
                name: "小数点编码",
                regex: "^\\d+\\.\\d+$",
                priority: 4,
                minLength: 3,
                description: "包含小数点的数字编码"
            ),
            CodePattern(
                name: "特殊分隔符编码",
                regex: "^[A-Za-z0-9]+[-_][A-Za-z0-9]+$",
                priority: 5,
                minLength: 3,
                description: "包含分隔符的编码"
            ),
            CodePattern(
                name: "纯数字编码",
                regex: "^\\d{2,}$",
                priority: 6,
                minLength: 2,
                description: "纯数字编码"
            ),
            CodePattern(
                name: "字母数字混合",
                regex: "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z0-9]{3,}$",
                priority: 7,
                minLength: 3,
                description: "字母数字混合编码"
            )
        ]
        
        var bestMatches: [(candidate: TextCandidate, pattern: CodePattern, score: Float)] = []
        
        for candidate in candidates {
            let text = candidate.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            for pattern in patterns {
                if text.range(of: pattern.regex, options: .regularExpression) != nil &&
                   text.count >= pattern.minLength {
                    
                    // 计算综合评分（苹果推荐的多因素评分）
                    let lengthScore = min(Float(text.count) / 20.0, 1.0)  // 长度评分
                    let confidenceScore = candidate.confidence  // 置信度评分
                    let priorityScore = Float(8 - pattern.priority) / 7.0  // 优先级评分（更新为8级）
                    let methodBonus: Float = candidate.recognitionLevel == .accurate ? 0.1 : 0.0  // 精确模式加分
                    
                    // 特殊加分：完整编码格式
                    let formatBonus: Float = pattern.name.contains("完整编码") ? 0.15 : 0.0
                    
                    // 分步计算最终评分
                    let confidencePart = confidenceScore * 0.35  // 降低置信度权重
                    let priorityPart = priorityScore * 0.35      // 提高优先级权重
                    let lengthPart = lengthScore * 0.2
                    let finalScore = confidencePart + priorityPart + lengthPart + methodBonus + formatBonus
                    
                    bestMatches.append((candidate, pattern, finalScore))
                }
            }
        }
        
        // 按评分排序
        bestMatches.sort { $0.score > $1.score }
        
        if let bestMatch = bestMatches.first {
            let method = "苹果Vision-\(bestMatch.pattern.name)"
            print("🎯 最佳匹配: \(bestMatch.candidate.text)")
            print("📋 匹配模式: \(bestMatch.pattern.description)")
            print("📊 综合评分: \(String(format: "%.3f", bestMatch.score))")
            
            return (
                code: bestMatch.candidate.text.trimmingCharacters(in: .whitespacesAndNewlines),
                confidence: bestMatch.candidate.confidence,
                method: method
            )
        }
        
        return nil
    }
    
    /**
     * 第二步：根据颜色标签智能分组 - 修正版
     * 每次遇到颜色标记就开始一个新产品组
     */
    private func groupImagesByColorLabels(imageFiles: [String], directoryPath: String) -> [String: [String]] {
        print("🎨 开始智能产品分组...")
        print("📋 工作流程：标签图(有颜色标记) → 产品角度图(无颜色标记)")
        
        var productGroups: [String: [String]] = [:]
        var currentGroupName: String? = nil
        var currentGroup: [String] = []
        var groupIndex = 1
        
        for imageFile in imageFiles {
            let imagePath = "\(directoryPath)/\(imageFile)"
            print("\n🔍 分析图片: \(imageFile)")
            
            // 检测当前图片的颜色标记
            let detectedColor = detectColorMarkerInImage(at: imagePath)
            print("🎨 检测到颜色: \(detectedColor.rawValue)")
            
            if detectedColor != .none {
                // 发现颜色标签 = 新产品的开始
                print("🏷️ 发现产品标签: \(detectedColor.rawValue)")
                
                // 先保存之前的产品组
                if let groupName = currentGroupName, !currentGroup.isEmpty {
                    productGroups[groupName] = currentGroup
                    print("📦 完成产品组: \(groupName) (\(currentGroup.count) 张图片)")
                    for (index, img) in currentGroup.enumerated() {
                        print("   \(index + 1). \(img)")
                    }
                }
                
                // 开始新的产品组
                currentGroupName = "产品组\(groupIndex)-\(detectedColor.rawValue)"
                currentGroup = [imageFile]
                groupIndex += 1
                
                print("🎨 开始新产品组: \(currentGroupName!)")
                
            } else {
                // 产品角度图，添加到当前产品组
                if currentGroupName != nil {
                    currentGroup.append(imageFile)
                    print("📦 角度图加入当前产品组: \(currentGroupName!)")
                } else {
                    // 第一张图片就没有颜色标记，创建默认组
                    currentGroupName = "产品组\(groupIndex)-无标记"
                    currentGroup = [imageFile]
                    groupIndex += 1
                    print("📦 创建默认产品组: \(currentGroupName!)")
                }
            }
        }
        
        // 处理最后一个产品组
        if let groupName = currentGroupName, !currentGroup.isEmpty {
            productGroups[groupName] = currentGroup
            print("\n📦 完成最后产品组: \(groupName) (\(currentGroup.count) 张图片)")
            for (index, img) in currentGroup.enumerated() {
                print("   \(index + 1). \(img)")
            }
        }
        
        // 显示最终分组结果
        print("\n🎨 智能产品分组结果:")
        for (groupName, images) in productGroups.sorted(by: { $0.key < $1.key }) {
            print("   🎨 \(groupName): \(images.count) 张图片")
            for (index, image) in images.enumerated() {
                print("      \(index + 1). \(image)")
            }
        }
        
        return productGroups
    }
    
    /**
     * 检测单张图片的颜色标记 - 读取macOS文件颜色标签
     */
    private func detectColorMarkerInImage(at imagePath: String) -> ColorMarker {
        let fileURL = URL(fileURLWithPath: imagePath)
        
        do {
            // 读取文件的macOS颜色标签
            let resourceValues = try fileURL.resourceValues(forKeys: [.labelNumberKey])
            if let labelNumber = resourceValues.labelNumber {
                let colorMarker = ColorMarker.fromMacOSLabel(labelNumber)
                if colorMarker != .none {
                    print("🎨 macOS颜色标签: \(labelNumber) -> \(colorMarker.rawValue)")
                    return colorMarker
                }
            }
        } catch {
            print("⚠️ 读取文件颜色标签失败: \(error)")
        }
        
        // 如果没有macOS颜色标签，作为备用方案，尝试OCR文字检测
        guard let image = NSImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("❌ 无法加载图片进行OCR检测: \(imagePath)")
            return .none
        }
        
        // 使用快速路径检测颜色标记（备用方案）
        let candidates = performTextRecognition(
            on: cgImage,
            config: RecognitionConfig.fastConfig
        )
        
        let texts = candidates.map { $0.text }
        let ocrResult = ColorMarker.detect(from: texts)
        
        if ocrResult != .none {
            print("🔍 OCR备用检测到颜色: \(ocrResult.rawValue)")
        }
        
        return ocrResult
    }
    
    /**
     * 第三步：处理每个颜色分组，识别编码并重命名
     */
    private func processColorGroups(productGroups: [String: [String]], directoryPath: String) {
        print("🏷️ 开始处理各颜色分组...")
        
        var totalProcessed = 0
        var totalCodes = 0
        
        for (groupName, images) in productGroups.sorted(by: { $0.key < $1.key }) {
            print("\n🎨 处理产品组: \(groupName)")
            
            // 寻找该产品组的代表编码
            let groupCode = findGroupCode(for: images, directoryPath: directoryPath, groupName: groupName)
            
            if let code = groupCode {
                print("✅ 产品组 \(groupName) 的编码: \(code)")
                
                // 重命名该产品组的所有图片
                renameColorGroup(images: images, code: code, groupName: groupName, directoryPath: directoryPath)
                totalCodes += 1
            } else {
                print("⚠️ 产品组 \(groupName) 未找到有效编码")
                
                // 使用产品组名称作为备用编码
                let backupCode = groupName
                print("🔄 使用产品组名称作为编码: \(backupCode)")
                renameColorGroup(images: images, code: backupCode, groupName: groupName, directoryPath: directoryPath)
                totalCodes += 1
            }
            
            totalProcessed += images.count
        }
        
        print("\n🎉 产品分组处理完成！")
        print("📊 处理统计:")
        print("   - 产品分组: \(productGroups.count) 个")
        print("   - 总计处理: \(totalProcessed) 张图片")
        print("   - 识别编码: \(totalCodes) 个")
        print("   - 工作流程: 产品分组 → 编码识别 → 智能重命名")
    }
    
    /**
     * 寻找产品组的代表编码
     */
    private func findGroupCode(for images: [String], directoryPath: String, groupName: String) -> String? {
        print("🔍 寻找产品组 \(groupName) 的编码...")
        
        var bestCode: String?
        var bestConfidence: Float = 0.0
        
        // 检查该组中的每张图片，寻找最佳编码
        for imageFile in images {
            let imagePath = "\(directoryPath)/\(imageFile)"
            print("   🔍 检查图片: \(imageFile)")
            
            if let productInfo = analyzeImageWithAppleStrategy(at: imagePath) {
                print("   ✅ 发现编码: \(productInfo.code) (置信度: \(String(format: "%.2f", productInfo.confidence)))")
                
                if productInfo.confidence > bestConfidence {
                    bestCode = productInfo.code
                    bestConfidence = productInfo.confidence
                    print("   🎯 更新最佳编码: \(productInfo.code)")
                }
            } else {
                print("   ⚠️ 未找到编码")
            }
        }
        
        if let code = bestCode {
            print("🏆 产品组 \(groupName) 最佳编码: \(code) (置信度: \(String(format: "%.2f", bestConfidence)))")
        } else {
            print("❌ 产品组 \(groupName) 未找到任何编码")
        }
        
        return bestCode
    }
    
    /**
     * 重命名颜色组的所有图片
     */
    private func renameColorGroup(images: [String], code: String, groupName: String, directoryPath: String) {
        print("🔄 重命名产品组: \(groupName) -> 编码: \(code)")
        
        let fileManager = FileManager.default
        var hasLabelImage = false
        var productIndex = 1
        
        for imageFile in images {
            let oldPath = "\(directoryPath)/\(imageFile)"
            let fileExtension = URL(fileURLWithPath: oldPath).pathExtension
            
            // 检测是否为标签图片（包含颜色标记或编码）
            let isLabelImage = detectIfLabelImage(at: oldPath)
            
            let newFileName: String
            if isLabelImage && !hasLabelImage {
                // 第一张标签图片
                newFileName = "\(code)-标签.\(fileExtension)"
                hasLabelImage = true
                print("🏷️ 标签图片: \(imageFile) -> \(newFileName)")
            } else {
                // 产品图片
                newFileName = "\(code)-\(productIndex).\(fileExtension)"
                productIndex += 1
                print("📦 产品图片: \(imageFile) -> \(newFileName)")
            }
            
            let newPath = "\(directoryPath)/\(newFileName)"
            
            do {
                // 如果目标文件已存在且与源文件相同，跳过
                if fileManager.fileExists(atPath: newPath) && newPath == oldPath {
                    print("⏭️ \(imageFile) 已是正确名称，跳过")
                    continue
                }
                
                if fileManager.fileExists(atPath: newPath) {
                    try fileManager.removeItem(atPath: newPath)
                }
                
                try fileManager.moveItem(atPath: oldPath, toPath: newPath)
                print("✅ \(imageFile) -> \(newFileName)")
            } catch {
                print("❌ 重命名失败: \(imageFile) -> \(newFileName)")
                print("   错误: \(error)")
            }
        }
    }
    
    /**
     * 检测是否为标签图片
     */
    private func detectIfLabelImage(at imagePath: String) -> Bool {
        // 检查文件的macOS颜色标签
        let fileURL = URL(fileURLWithPath: imagePath)
        
        do {
            let resourceValues = try fileURL.resourceValues(forKeys: [.labelNumberKey])
            if let labelNumber = resourceValues.labelNumber, labelNumber != 0 {
                // 有macOS颜色标签的就是标签图片
                print("🏷️ 检测到macOS颜色标签: \(labelNumber)")
                return true
            }
        } catch {
            print("⚠️ 读取文件颜色标签失败: \(error)")
        }
        
        // 备用方案：OCR检测是否包含编码
        guard let image = NSImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }
        
        let candidates = performTextRecognition(
            on: cgImage,
            config: RecognitionConfig.accurateConfig
        )
        
        // 检查是否包含编码
        if let _ = extractCodeWithAppleStrategy(from: candidates) {
            print("🏷️ OCR检测到编码，判定为标签图片")
            return true
        }
        
        return false
    }
}

// MARK: - 主程序入口
func main() {
    let arguments = CommandLine.arguments
    
    print("🍎 苹果Vision优化OCR重命名工具")
    print("📖 基于苹果官方最佳实践")
    
    if arguments.count < 2 {
        print("❌ 请提供图片目录路径")
        print("用法: swift AppleVisionOptimizedRenamer.swift <图片目录路径>")
        exit(1)
    }
    
    let directoryPath = arguments[1]
    let renamer = AppleVisionOptimizedRenamer()
    renamer.processImages(in: directoryPath)
}

// 执行主程序
main() 