import SwiftUI

// ============================================================================
// ZCTheme — 方向 B「账簿 / Ledger」设计系统（token 与 design/zchain-wallet-ui-b-ledger.html
// 及 extension/popup/popup.css 逐值一致）。
//
// 设计立场：卖的不是「牌桌」而是可被审计的账簿：纸白底、细线账格、方形印章、
// 等宽数字右对齐。双底色：纸白（默认）/ 夜场，由 WalletModel.ground 切换。
// 品牌合规硬规则：零 webfont（system + monospaced）、哈希/地址/金额等宽、
// 不用描边字/发光字、金色只用于 REAL 强调。
// ============================================================================

/// 底色（纸白 / 夜场）。设置页可切换并持久化。
enum ZCGround: String, Codable, CaseIterable {
    case paper
    case night

    var next: ZCGround { self == .night ? .paper : .night }
    var label: String { self == .night ? "夜场" : "纸白" }
}

/// 语义 token 集合（css 变量逐条对应）。
struct ZCPalette {
    let pg: Color       // 页面底
    let pg2: Color      // 页面底-次级
    let cd: Color       // 卡片底
    let cd2: Color      // 卡片底-次级
    let ink: Color      // 主墨
    let ink2: Color     // 次墨
    let ink3: Color     // 弱墨
    let rl: Color       // 细线
    let rl2: Color      // 细线-深
    let felt: Color     // 绿毡（主操作/成功）
    let feltW: Color    // 绿毡弱底
    let feltRl: Color   // 绿毡线
    let onFelt: Color   // 绿毡上的字
    let play: Color     // 蓝墨（GAME/PLAY 域）
    let playW: Color
    let playRl: Color
    let real: Color     // 金墨（REAL 域）
    let realW: Color
    let realRl: Color
    let bad: Color      // 朱红（危险/失败）
    let badW: Color
    let badRl: Color
    let onBad: Color
    let amb: Color      // 琥珀（进行中/警示）
    let ambW: Color
    let ambRl: Color
    let onInk: Color    // 墨底上的字
    let code: Color     // 代码底
    let rulePaper: Color // 账格纸纹
    let overlayBg: Color // 浮层遮罩

    /// 底色 A：纸白（默认）。
    static let paper = ZCPalette(
        pg: ZCColor.hex(0xF5F2EA), pg2: ZCColor.hex(0xEAE5D9), cd: ZCColor.hex(0xFFFDF7), cd2: ZCColor.hex(0xF8F5EC),
        ink: ZCColor.hex(0x14130F), ink2: ZCColor.hex(0x4B4840), ink3: ZCColor.hex(0x666256),
        rl: ZCColor.hex(0xDDD6C6), rl2: ZCColor.hex(0xC3BBA7),
        felt: ZCColor.hex(0x0B6B45), feltW: ZCColor.hex(0xE6EFE8), feltRl: ZCColor.hex(0xA8C8B6), onFelt: ZCColor.hex(0xFFFDF7),
        play: ZCColor.hex(0x15507F), playW: ZCColor.hex(0xE5ECF3), playRl: ZCColor.hex(0xA9C0D6),
        real: ZCColor.hex(0x7D5308), realW: ZCColor.hex(0xF6EBD4), realRl: ZCColor.hex(0xD8BD85),
        bad: ZCColor.hex(0xA83226), badW: ZCColor.hex(0xF7E6E2), badRl: ZCColor.hex(0xDDA9A1),
        onBad: ZCColor.hex(0xFFFDF7),
        amb: ZCColor.hex(0x8A5A12), ambW: ZCColor.hex(0xF6EEDA), ambRl: ZCColor.hex(0xDCC796),
        onInk: ZCColor.hex(0xF5F2EA), code: ZCColor.hex(0xEFEADE),
        rulePaper: ZCColor.rgba(20, 19, 15, 0.045), overlayBg: ZCColor.rgba(20, 19, 15, 0.42)
    )

    /// 底色 B：夜场（token 逐字取自 media-kit/v0.1/brand.css）。
    static let night = ZCPalette(
        pg: ZCColor.hex(0x070D0A), pg2: ZCColor.hex(0x0B1410), cd: ZCColor.hex(0x101C15), cd2: ZCColor.hex(0x152418),
        ink: ZCColor.hex(0xF0F7F1), ink2: ZCColor.hex(0xABC3B6), ink3: ZCColor.hex(0x7D9A8B),
        rl: ZCColor.hex(0x1D3326), rl2: ZCColor.hex(0x2A4A37),
        felt: ZCColor.hex(0x37E39C), feltW: ZCColor.rgba(55, 227, 156, 0.11), feltRl: ZCColor.rgba(55, 227, 156, 0.35), onFelt: ZCColor.hex(0x05130C),
        play: ZCColor.hex(0x66C4FF), playW: ZCColor.rgba(102, 196, 255, 0.11), playRl: ZCColor.rgba(102, 196, 255, 0.35),
        real: ZCColor.hex(0xFFC75A), realW: ZCColor.rgba(255, 199, 90, 0.11), realRl: ZCColor.rgba(255, 199, 90, 0.38),
        bad: ZCColor.hex(0xFF9483), badW: ZCColor.rgba(255, 148, 131, 0.10), badRl: ZCColor.rgba(255, 148, 131, 0.35),
        onBad: ZCColor.hex(0x1A0A08),
        amb: ZCColor.hex(0xFFD166), ambW: ZCColor.rgba(255, 209, 102, 0.10), ambRl: ZCColor.rgba(255, 209, 102, 0.35),
        onInk: ZCColor.hex(0x070D0A), code: ZCColor.hex(0x0A120D),
        rulePaper: ZCColor.rgba(240, 247, 241, 0.05), overlayBg: ZCColor.rgba(0, 0, 0, 0.62)
    )
}

enum ZCColor {
    static func hex(_ value: UInt32, alpha: Double = 1) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255,
              green: Double((value >> 8) & 0xFF) / 255,
              blue: Double(value & 0xFF) / 255,
              opacity: alpha)
    }
    static func rgba(_ r: Int, _ g: Int, _ b: Int, _ a: Double) -> Color {
        Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: a)
    }
}

// MARK: - 字体（零 webfont：system 栈 + 等宽数字）

enum ZCFont {
    /// ui 正文 13px。
    static func ui(_ size: CGFloat = 13, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
    /// mono（金额/哈希/地址/标签）。
    static func mono(_ size: CGFloat = 13, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Font {
    /// 点语法便捷入口（.font(.ui(13)) / .font(.mono(11))——参数为 Font? 时经
    /// 隐式成员查找命中这里的 static func）。
    static func ui(_ size: CGFloat = 13, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
    static func mono(_ size: CGFloat = 13, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - 几何 token

enum ZCMetrics {
    static let corner: CGFloat = 3       // --r
    static let cornerL: CGFloat = 6      // --r-l
    static let chipCorner: CGFloat = 2
    static let inputHeight: CGFloat = 42
    static let btnHeight: CGFloat = 42
    static let btnLgHeight: CGFloat = 46
    static let btnSmHeight: CGFloat = 32
    static let amountInputHeight: CGFloat = 56
}

/// 账格纸纹（.tot / .cover / .cfm 的横线 repeating-linear-gradient）。
struct RuledPaperPattern: View {
    @EnvironmentObject var model: WalletModel
    var lineSpacing: CGFloat = 25
    var body: some View {
        GeometryReader { geo in
            let step: CGFloat = lineSpacing
            let rows = Int(geo.size.height / step) + 1
            Path { p in
                for i in 1...max(rows, 1) {
                    let y = CGFloat(i) * step
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(model.c.rulePaper, lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

/// 齿孔线（.dh/.sub 底部的打孔虚线：3px 实段 + 5px 空）。
struct PerforationLine: View {
    @EnvironmentObject var model: WalletModel
    var body: some View {
        GeometryReader { geo in
            Path { p in
                let y: CGFloat = 3
                var x: CGFloat = 0
                while x < geo.size.width {
                    p.move(to: CGPoint(x: x, y: y))
                    p.addLine(to: CGPoint(x: min(x + 3, geo.size.width), y: y))
                    x += 8
                }
            }
            .stroke(model.c.rl2, lineWidth: 1)
        }
        .frame(height: 7)
        .opacity(0.85)
        .allowsHitTesting(false)
    }
}
