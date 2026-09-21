import SwiftUI

// ============================================================================
// ZCIcons — 单线图标库（方头 1.6 stroke，印刷/制图风）。
// 逐条移植自 popup.html 的 <symbol> 定义（viewBox 0 0 24 24）。
// ============================================================================

enum ZCIconName: String, CaseIterable {
    case back, chevD = "chev-d", chevR = "chev-r", copy, lock, unlock
    case eye, eyeOff = "eye-off", gear, warn, info, check, x, clock, refresh
    case key, qr, send, recv, out, ul, dl, receipt, wallet
    case spade, ether, layers, file, swap, plus, trash, ext, flask
    case search, book, home, pen, bolt, people
    case zLogo = "z-logo"
}

/// 图标 Shape：24×24 设计坐标，方头 1.6 stroke。
struct ZCIconShape: Shape {
    let name: ZCIconName

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24, sy = rect.height / 24
        let pen = Pen(sx: sx, sy: sy)

        func M(_ x: CGFloat, _ y: CGFloat) { pen.move(x, y) }
        func L(_ x: CGFloat, _ y: CGFloat) { pen.line(x, y) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) { pen.rect(x, y, w, h) }
        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) { pen.circle(cx, cy, r) }

        switch name {
        case .back: M(15, 5); L(8, 12); L(15, 19)
        case .chevD: M(5, 9); L(12, 16); L(19, 9)
        case .chevR: M(9, 5); L(16, 12); L(9, 19)
        case .copy: box(4, 7, 12, 13); M(8, 7); L(8, 4); L(20, 4); L(20, 17); L(16, 17)
        case .lock: box(5, 11, 14, 9); M(8, 11); L(8, 8); pen.arc(cx: 12, cy: 8, r: 4, fromDeg: 180, toDeg: 0, cw: false); L(16, 11)
        case .unlock: box(5, 11, 14, 9); M(8, 11); L(8, 8); pen.arc(cx: 12, cy: 8, r: 4, fromDeg: 180, toDeg: 334.1, cw: false)
        case .eye:
            M(2, 12); pen.curve(cp1: (6, 5.5), cp2: (12, 5.5), to: (12, 5.5)); pen.curve(cp1: (18, 5.5), cp2: (22, 12), to: (22, 12))
            pen.curve(cp1: (18, 18.5), cp2: (12, 18.5), to: (12, 18.5)); pen.curve(cp1: (6, 18.5), cp2: (2, 12), to: (2, 12))
            circle(12, 12, 2.6)
        case .eyeOff:
            M(4, 4); L(20, 20)
            M(9.5, 5.8); pen.curve(cp1: (10.3, 5.6), cp2: (11.15, 5.5), to: (12, 5.5)); pen.curve(cp1: (18, 5.5), cp2: (22, 12), to: (22, 12))
            pen.curve(cp1: (20.9, 13.9), cp2: (19.5, 15.3), to: (18.8, 15.9))
            M(6.6, 7.9); pen.curve(cp1: (4.2, 9.6), cp2: (2, 12), to: (2, 12)); pen.curve(cp1: (6, 18.5), cp2: (12, 18.5), to: (12, 18.5))
            pen.curve(cp1: (12.65, 18.5), cp2: (13.27, 18.44), to: (14.8, 18.1))
            M(9.6, 10.2); pen.curve(cp1: (9.2, 10.9), cp2: (9.4, 11.9), to: (10.2, 12.7)); pen.curve(cp1: (11.1, 13.5), cp2: (12.6, 13.5), to: (13.8, 12.7))
        case .gear:
            circle(12, 12, 3.2)
            M(12, 2); L(12, 5); M(12, 19); L(12, 22); M(2, 12); L(5, 12); M(19, 12); L(22, 12)
            M(5, 5); L(7, 7); M(17, 17); L(19, 19); M(19, 5); L(17, 7); M(7, 17); L(5, 19)
        case .warn: M(12, 3); L(21, 20); L(3, 20); M(12, 9); L(12, 14); M(12, 17); pen.dot(12.01, 17)
        case .info: circle(12, 12, 9); M(12, 11); L(12, 17); M(12, 8); pen.dot(12.01, 8)
        case .check: M(4, 12); L(9, 17); L(20, 6)
        case .x: M(5, 5); L(19, 19); M(19, 5); L(5, 19)
        case .clock: circle(12, 12, 9); M(12, 7); L(12, 12.5); L(16, 14.5)
        case .refresh: pen.arc(cx: 12, cy: 12, r: 8, fromDeg: -19.6, toDeg: 247.4, cw: false); M(20, 4); L(20, 9); L(15, 9)
        case .key: circle(7.5, 12, 4); M(11.5, 12); L(21, 12); M(17.5, 12); L(17.5, 15.5); M(14.5, 12); L(14.5, 14.5)
        case .qr:
            box(4, 4, 6, 6); box(14, 4, 6, 6); box(4, 14, 6, 6)
            M(14, 14); L(16.5, 14); L(16.5, 16.5); L(14, 16.5); M(19, 14); L(20.5, 14)
            M(14, 19); L(16.5, 19); M(19, 18.5); L(19, 20)
        case .send: M(4, 12); L(17, 12); M(13, 6); L(19, 12); L(13, 18)
        case .recv: M(20, 12); L(7, 12); M(11, 6); L(5, 12); L(11, 18)
        case .out: M(12, 4); L(12, 15); M(8, 11); L(12, 15); L(16, 11); M(4, 20); L(20, 20)
        case .ul: M(12, 20); L(12, 8); M(8, 12); L(12, 8); L(16, 12); M(4, 4); L(20, 4)
        case .dl: M(12, 4); L(12, 16); M(8, 12); L(12, 16); L(16, 12); M(4, 20); L(20, 20)
        case .receipt: M(6, 3); L(18, 3); L(18, 21); L(15, 19); L(12, 21); L(9, 19); L(6, 21); M(9, 8); L(15, 8); M(9, 12); L(15, 12)
        case .wallet: box(3, 6, 18, 13); M(3, 10.5); L(21, 10.5); M(16, 15); L(18, 15)
        case .spade:
            M(12, 3.5); pen.curve(cp1: (12, 3.5), cp2: (5, 9.5), to: (5, 13.2))
            pen.arc(cx: 8.7, cy: 14.5, r: 3.7, fromDeg: 155, toDeg: 305, cw: false)
            L(10.6, 20.5); L(13.4, 20.5); L(12.8, 15.9)
            pen.arc(cx: 15.7, cy: 14.5, r: 3.7, fromDeg: 235, toDeg: 25, cw: false)
            pen.curve(cp1: (19, 9.5), cp2: (12, 3.5), to: (12, 3.5))
        case .ether: M(12, 3); L(4.5, 12.5); L(12, 16.6); L(19.5, 12.5); M(4.5, 14.2); L(12, 21.2); L(19.5, 14.2); L(12, 17.7)
        case .layers: M(12, 3); L(3, 8); L(12, 13); L(21, 8); M(3, 12.6); L(12, 17.6); L(21, 12.6); M(3, 17); L(12, 22); L(21, 17)
        case .file: M(6, 3); L(14, 3); L(18, 7); L(18, 21); L(6, 21); M(14, 3); L(14, 7); L(18, 7); M(9, 12); L(15, 12); M(9, 16); L(15, 16)
        case .swap: M(4, 8); L(17, 8); M(14, 5); L(17, 8); L(14, 11); M(20, 16); L(7, 16); M(10, 13); L(7, 16); L(10, 19)
        case .plus: M(12, 5); L(12, 19); M(5, 12); L(19, 12)
        case .trash: M(4, 7); L(20, 7); M(9, 7); L(9, 4); L(15, 4); L(15, 7); M(6.5, 7); L(7.5, 21); L(16.5, 21); L(17.5, 7)
        case .ext: M(14, 4); L(20, 4); L(20, 10); M(20, 4); L(12, 12); M(18, 13); L(18, 20); L(4, 20); L(4, 6); L(11, 6)
        case .flask: M(9, 3); L(15, 3); M(10, 3); L(10, 9); L(5, 20); L(19, 20); L(14, 9); L(14, 3); M(7.6, 15); L(16.4, 15)
        case .search: circle(10.5, 10.5, 6); M(15, 15); L(20, 20)
        case .book:
            M(4, 4); L(10.5, 4); pen.arc(cx: 12, cy: 5.5, r: 1.5, fromDeg: 180, toDeg: 270, cw: false); L(12, 20)
            pen.arc(cx: 10, cy: 20, r: 2, fromDeg: 270, toDeg: 180, cw: false); L(4, 18)
            M(20, 4); L(13.5, 4); pen.arc(cx: 12, cy: 5.5, r: 1.5, fromDeg: 0, toDeg: 90, cw: false); L(12, 20)
            pen.arc(cx: 14, cy: 20, r: 2, fromDeg: 270, toDeg: 0, cw: false); L(20, 18)
        case .home: M(4, 11); L(12, 4); L(20, 11); L(20, 20); L(4, 20); M(10, 20); L(10, 14); L(14, 14); L(14, 20)
        case .pen: M(4, 20); L(5.2, 15.8); L(16, 5); L(19, 8); L(8.2, 18.8)
        case .bolt: M(13, 3); L(5, 14); L(11, 14); L(10, 21); L(18, 10); L(12, 10)
        case .people:
            circle(9, 8, 3.4)
            M(3, 20); pen.curve(cp1: (3, 16.7), cp2: (5.7, 14.5), to: (9, 14.5)); pen.curve(cp1: (12.3, 14.5), cp2: (15, 16.7), to: (15, 20))
            M(16, 5.5); pen.arc(cx: 16.7, cy: 8.7, r: 3.4, fromDeg: 250, toDeg: 110, cw: false)
            M(18, 20); pen.curve(cp1: (18, 17.6), cp2: (17.1, 15.8), to: (15.6, 14.8))
        case .zLogo:
            // 64 viewBox 等比缩到 24 基准（k = 24/64）。
            let k: CGFloat = 24.0 / 64.0
            pen.roundedRect(x: 2 * k, y: 2 * k, w: 60 * k, h: 60 * k, r: 14 * k)
            M(17 * k, 21 * k); L(45 * k, 21 * k); L(24 * k, 43 * k); L(47 * k, 43 * k)
            pen.filledDiamond(cx: 46.5 * k, cy: 12.5 * k, r: 6.364 * k)
        }
        return pen.path
    }

    /// 笔画帮助结构（引用语义：内部持有唯一 Path）。把 24×24 设计坐标缩放到目标 rect。
    private final class Pen {
        var path = Path()
        let sx: CGFloat
        let sy: CGFloat
        var current: CGPoint = .zero

        init(sx: CGFloat, sy: CGFloat) {
            self.sx = sx
            self.sy = sy
        }

        func move(_ x: CGFloat, _ y: CGFloat) {
            current = CGPoint(x: x * sx, y: y * sy)
            path.move(to: current)
        }
        func line(_ x: CGFloat, _ y: CGFloat) {
            current = CGPoint(x: x * sx, y: y * sy)
            path.addLine(to: current)
        }
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
            path.addRect(CGRect(x: x * sx, y: y * sy, width: w * sx, height: h * sy))
        }
        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
            path.addEllipse(in: CGRect(x: (cx - r) * sx, y: (cy - r) * sy, width: r * 2 * sx, height: r * 2 * sy))
        }
        func roundedRect(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat) {
            path.addRoundedRect(in: CGRect(x: x * sx, y: y * sy, width: w * sx, height: h * sy), cornerSize: CGSize(width: r * sx, height: r * sy))
        }
        func arc(cx: CGFloat, cy: CGFloat, r: CGFloat, fromDeg: CGFloat, toDeg: CGFloat, cw: Bool) {
            path.addArc(center: CGPoint(x: cx * sx, y: cy * sy), radius: r * sx,
                        startAngle: .degrees(fromDeg), endAngle: .degrees(toDeg), clockwise: cw)
            current = path.currentPoint ?? current
        }
        func curve(cp1: (CGFloat, CGFloat), cp2: (CGFloat, CGFloat), to: (CGFloat, CGFloat)) {
            let end = CGPoint(x: to.0 * sx, y: to.1 * sy)
            path.addCurve(to: end,
                          control1: CGPoint(x: cp1.0 * sx, y: cp1.1 * sy),
                          control2: CGPoint(x: cp2.0 * sx, y: cp2.1 * sy))
            current = end
        }
        func dot(_ x: CGFloat, _ y: CGFloat) {
            // "h.01" 类微线段：以极短线段表达（方头笔触下呈 1.6px 点）。
            line(x + 0.01, y)
        }
        func filledDiamond(cx: CGFloat, cy: CGFloat, r: CGFloat) {
            var d = Path()
            d.move(to: CGPoint(x: cx * sx, y: (cy - r) * sy))
            d.addLine(to: CGPoint(x: (cx + r) * sx, y: cy * sy))
            d.addLine(to: CGPoint(x: cx * sx, y: (cy + r) * sy))
            d.addLine(to: CGPoint(x: (cx - r) * sx, y: cy * sy))
            d.closeSubpath()
            path.addPath(d)
        }
    }
}

/// 单线图标视图（stroke 用 currentColor）。
struct ZCIcon: View {
    let name: ZCIconName
    var size: CGFloat = 18
    var strokeWidth: CGFloat = 1.6

    var body: some View {
        ZCIconShape(name: name)
            .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .square, lineJoin: .miter, miterLimit: 4))
            .frame(width: size, height: size)
    }
}

/// ZChain 品牌单色 logo（圆角方框 + Z 笔画 + 菱形点；Z 笔画与方框为圆头粗笔）。
struct ZCLogo: View {
    var size: CGFloat = 44
    @EnvironmentObject var model: WalletModel

    var body: some View {
        let s = size / 64
        ZStack {
            // 圆角方框（4/64 stroke）
            RoundedRectangle(cornerRadius: 14 * s)
                .stroke(model.c.ink, lineWidth: 4 * s)
                .frame(width: 60 * s, height: 60 * s)
            // Z 笔画（6/64，圆头圆角）
            ZStrokeShape(scale: s)
                .stroke(style: StrokeStyle(lineWidth: 6 * s, lineCap: .round, lineJoin: .round))
            // 菱形点
            DiamondShape(scale: s)
                .fill(model.c.ink)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("ZChain logo")
    }

    private struct ZStrokeShape: Shape {
        var scale: CGFloat
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: 17 * scale, y: 21 * scale))
            p.addLine(to: CGPoint(x: 45 * scale, y: 21 * scale))
            p.addLine(to: CGPoint(x: 24 * scale, y: 43 * scale))
            p.addLine(to: CGPoint(x: 47 * scale, y: 43 * scale))
            return p
        }
    }

    private struct DiamondShape: Shape {
        var scale: CGFloat
        func path(in rect: CGRect) -> Path {
            let cx: CGFloat = 46.5 * scale, cy: CGFloat = 12.5 * scale
            let r: CGFloat = 6.364 * scale
            var p = Path()
            p.move(to: CGPoint(x: cx, y: cy - r))
            p.addLine(to: CGPoint(x: cx + r, y: cy))
            p.addLine(to: CGPoint(x: cx, y: cy + r))
            p.addLine(to: CGPoint(x: cx - r, y: cy))
            p.closeSubpath()
            return p
        }
    }
}
