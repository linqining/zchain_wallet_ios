import SwiftUI

// ============================================================================
// ZCComponents — 账簿设计系统的原生 SwiftUI 组件（与 popup.css 逐类对应）。
// 标签方形不用胶囊、按钮方形 3px、印章 -4°、凭证条四态笔触。
// ============================================================================

// MARK: - Chip（方形标签）

struct ZCChip: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var tone: ZCChipTone = .neutral
    var xs: Bool = false

    /// 显式 init（无标签首参便于 `ZCChip("GAME", tone: .play)` 调用）。
    init(_ text: String, tone: ZCChipTone = .neutral, xs: Bool = false) {
        self.text = text
        self.tone = tone
        self.xs = xs
    }

    var body: some View {
        Text(text)
            .font(.system(size: xs ? 9 : 9.5, weight: .medium, design: .monospaced))
            .kerning((xs ? 0.06 : 0.09) * (xs ? 9 : 9.5))
            .textCase(.uppercase)
            .foregroundColor(fg)
            .padding(.init(top: xs ? 0 : 1.5, leading: xs ? 4 : 6, bottom: xs ? 0 : 1.5, trailing: xs ? 4 : 6))
            .background(bg)
            .cornerRadius(ZCMetrics.chipCorner)
            .overlay(
                RoundedRectangle(cornerRadius: ZCMetrics.chipCorner)
                    .stroke(border, lineWidth: 1)
            )
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private var fg: Color {
        switch tone {
        case .neutral: return model.c.ink2
        case .felt: return model.c.felt
        case .play: return model.c.play
        case .real: return model.c.real
        case .bad: return model.c.bad
        case .amb: return model.c.amb
        case .solid: return model.c.onInk
        }
    }
    private var bg: Color {
        switch tone {
        case .neutral: return model.c.cd
        case .felt: return model.c.feltW
        case .play: return model.c.playW
        case .real: return model.c.realW
        case .bad: return model.c.badW
        case .amb: return model.c.ambW
        case .solid: return model.c.ink
        }
    }
    private var border: Color {
        switch tone {
        case .neutral: return model.c.rl2
        case .felt: return model.c.feltRl
        case .play: return model.c.playRl
        case .real: return model.c.realRl
        case .bad: return model.c.badRl
        case .amb: return model.c.ambRl
        case .solid: return model.c.ink
        }
    }
}

enum ZCChipTone {
    case neutral, felt, play, real, bad, amb, solid
}

/// 语义凭证词 → chip 色（proven/finalized 绿，其余琥珀）。
func proofChipTone(_ proof: String) -> ZCChipTone {
    (proof == "finalized" || proof == "proven") ? .felt : .amb
}

// MARK: - 印章（-4° 方形章）

struct ZCSeal: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var tone: ZCSealTone = .ok
    var animate: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .kerning(0.13 * 9)
            .textCase(.uppercase)
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: ZCMetrics.chipCorner)
                    .stroke(color, lineWidth: 1.5)
            )
            .rotationEffect(.degrees(-4))
            .opacity(0.9)
            .scaleEffect(animate ? 1 : 1.08)
            .opacity(animate ? 1 : 0)
            .rotationEffect(.degrees(animate ? 0 : -4))
            .animation(animate ? ZCAnim.seal : nil, value: animate)
    }

    private var color: Color {
        switch tone {
        case .ok: return model.c.felt
        case .bad: return model.c.bad
        case .real: return model.c.real
        }
    }
}

enum ZCSealTone { case ok, bad, real }

// MARK: - 网络 / 圆点

struct ZCNetBadge: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(model.c.felt).frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundColor(model.c.ink2)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(model.c.cd)
        .cornerRadius(ZCMetrics.chipCorner)
        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(model.c.rl2, lineWidth: 1))
        .asButton(action: action ?? {})
    }
}

// MARK: - 按钮

enum ZCBtnStyle {
    case primary   // btn-p 绿毡
    case secondary // btn-s 墨描边
    case ghost     // btn-g
    case danger    // btn-d 朱红
    case outlineDanger // btn-o

    var bg: Color? {
        switch self {
        case .primary: return nil // 由 palette 决定
        case .secondary: return .clear
        case .ghost: return .clear
        case .danger: return nil
        case .outlineDanger: return .clear
        }
    }
}

struct ZCButton: View {
    @EnvironmentObject var model: WalletModel
    let label: String
    var style: ZCBtnStyle = .primary
    var large: Bool = false
    var small: Bool = false
    var icon: ZCIconName? = nil
    var disabled: Bool = false
    var action: () -> Void = {}

    /// 显式 init（无标签首参便于 `ZCButton("确认转账")` 调用）。
    init(_ label: String, style: ZCBtnStyle = .primary, large: Bool = false, small: Bool = false,
         icon: ZCIconName? = nil, disabled: Bool = false, action: @escaping () -> Void = {}) {
        self.label = label
        self.style = style
        self.large = large
        self.small = small
        self.icon = icon
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button {
            guard !disabled else { return }
            action()
        } label: {
            HStack(spacing: 7) {
                if let icon {
                    ZCIcon(name: icon, size: small ? 14 : 16)
                }
                Text(label)
                    .font(.system(size: small ? 12 : (large ? 13.5 : 13), weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: small ? ZCMetrics.btnSmHeight : (large ? ZCMetrics.btnLgHeight : ZCMetrics.btnHeight))
            .padding(.horizontal, small ? 12 : 16)
            .foregroundColor(fgColor)
            .background(bgColor)
            .cornerRadius(ZCMetrics.corner)
            .overlay(
                RoundedRectangle(cornerRadius: ZCMetrics.corner)
                    .strokeBorder(borderColor, style: StrokeStyle(lineWidth: 1, dash: disabled ? [3, 3] : []))
            )
            .opacity(disabled ? 0.42 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var fullWidth: Bool { !small }

    private var fgColor: Color {
        if disabled { return model.c.ink3 }
        switch style {
        case .primary: return model.c.onFelt
        case .secondary: return model.c.ink
        case .ghost: return model.c.ink2
        case .danger: return model.c.onBad
        case .outlineDanger: return model.c.bad
        }
    }
    private var bgColor: Color {
        if disabled { return model.c.pg2 }
        switch style {
        case .primary: return model.c.felt
        case .secondary: return .clear
        case .ghost: return .clear
        case .danger: return model.c.bad
        case .outlineDanger: return .clear
        }
    }
    private var borderColor: Color {
        if disabled { return model.c.rl2 }
        switch style {
        case .primary: return .clear
        case .secondary: return model.c.ink
        case .ghost: return .clear
        case .danger: return .clear
        case .outlineDanger: return model.c.badRl
        }
    }
}

/// 方形图标按钮（.ib / .ib.bare）。
struct ZCIconBtn: View {
    @EnvironmentObject var model: WalletModel
    let icon: ZCIconName
    var bare: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZCIcon(name: icon, size: bare ? 16 : 15)
                .foregroundColor(bare ? model.c.ink2 : model.c.ink2)
                .frame(width: bare ? 24 : 30, height: bare ? 24 : 30)
                .background(bare ? .clear : model.c.cd)
                .cornerRadius(ZCMetrics.corner)
                .overlay(
                    Group {
                        if !bare {
                            RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 卡片 / 区块标题

struct ZCCard<Content: View>: View {
    @EnvironmentObject var model: WalletModel
    var title: String? = nil
    var more: String? = nil
    var moreAction: (() -> Void)? = nil
    var tight: Bool = false
    var rowsStyle: Bool = false
    var emphasize: Bool = false   // 会话卡 active 的 1.5px 墨线
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 9.5, design: .monospaced))
                        .kerning(0.15 * 9.5)
                        .textCase(.uppercase)
                        .foregroundColor(model.c.ink3)
                    if let more {
                        Button {
                            moreAction?()
                        } label: {
                            HStack(spacing: 2) {
                                Text(more)
                                    .font(.system(size: 10, design: .monospaced))
                                ZCIcon(name: .chevR, size: 11)
                            }
                            .foregroundColor(model.c.felt)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
                .padding(.bottom, 8)
            }
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, tight ? 4 : 12)
        .background(model.c.cd)
        .cornerRadius(ZCMetrics.corner)
        .overlay(
            RoundedRectangle(cornerRadius: ZCMetrics.corner)
                .stroke(emphasize ? model.c.ink : model.c.rl, lineWidth: emphasize ? 1.5 : 1)
        )
        .shadow(color: ZCColor.rgba(20, 19, 15, 0.04), radius: 0, x: 0, y: 1)
    }
}

/// 区块标题（sec-t：mono 大写字距 + 细线延伸）。
struct ZCSectionTitle: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var danger: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 9.5, design: .monospaced))
                .kerning(0.16 * 9.5)
                .textCase(.uppercase)
                .foregroundColor(danger ? model.c.bad : model.c.ink3)
            Rectangle().fill(model.c.rl).frame(height: 1)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - 账簿行（label / value 细线对）

struct ZCLedgerRow<Key: View, Value: View>: View {
    @EnvironmentObject var model: WalletModel
    var dim: Bool = false
    @ViewBuilder var key: () -> Key
    @ViewBuilder var value: () -> Value

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            key()
                .font(.ui(12.5))
                .foregroundColor(model.c.ink2)
                .lineLimit(1)
                .layoutPriority(1)
            Spacer(minLength: 8)
            value()
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundColor(dim ? model.c.ink3 : model.c.ink)
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 7)
        .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
    }
}

extension ZCLedgerRow where Key == Text, Value == Text {
    init(_ k: String, _ v: String, dim: Bool = false) {
        self.init(dim: dim, key: { Text(k) }, value: { Text(v) })
    }
}

/// 哈希缩略（前缀 + 首尾保留）。
func shortAddr(_ a: String?, _ head: Int = 10, _ tail: Int = 6) -> String {
    guard let a, !a.isEmpty else { return "—" }
    if a.count <= head + tail + 1 { return a }
    let h = a.prefix(head)
    let t = a.suffix(tail)
    return "\(h)…\(t)"
}

/// 具名前缀缩略（tx 0xc41d…9b04）。
func idText(_ kind: String, _ value: String?) -> String {
    "\(kind) \(shortAddr(value))"
}

// MARK: - 凭证条（rail：pending → soft → proven → finalized）

struct ZCRail: View {
    @EnvironmentObject var model: WalletModel
    let steps: [RailStep]
    @State private var shown = false
    var capLeft: String? = nil
    var capLeftBold: String? = nil      // 彩色加粗段
    var capLeftBoldColor: Color? = nil
    var capRight: String? = nil
    var capRightButton: (label: String, action: () -> Void)? = nil
    var animate: Bool = false

    struct RailStep {
        let proof: String
        let state: RailNodeState
        let required: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                    node(s)
                        .scaleEffect(animate && !shown ? 0.7 : 1)
                        .opacity(animate && !shown ? 0 : 1)
                        .animation(animate ? ZCAnim.std.delay(Double(i) * 0.06) : nil, value: shown)
                    if i < steps.count - 1 {
                        Rectangle()
                            .fill(s.state == .done ? model.c.felt : model.c.rl2)
                            .frame(height: 1.5)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 2)
                            .padding(.top, -4)
                            .scaleEffect(x: animate && !shown ? 0.001 : 1, y: 1, anchor: .leading)
                            .animation(animate ? ZCAnim.std.delay(Double(i) * 0.06 + 0.06) : nil, value: shown)
                    }
                }
                .onAppear { shown = true }
            }
            if capLeft != nil || capLeftBold != nil || capRight != nil || capRightButton != nil {
                HStack(spacing: 8) {
                    (Text(capLeft ?? "")
                        .font(.ui(10.5))
                        .foregroundColor(model.c.ink2)
                        + Text(capLeftBold ?? "")
                        .font(.ui(10.5, .bold))
                        .foregroundColor(capLeftBoldColor ?? model.c.ink))
                    Spacer(minLength: 6)
                    if let b = capRightButton {
                        ZCButton(b.label, style: .secondary, small: true, action: b.action)
                    } else if let r = capRight {
                        Text(r)
                            .font(.ui(10.5))
                            .foregroundColor(model.c.ink2)
                    }
                }
                .padding(.top, 9)
            }
        }
    }

    @ViewBuilder
    private func node(_ s: RailStep) -> some View {
        VStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 0)
                .fill(fill(s.state))
                .frame(width: 9, height: 9)
                .overlay(Rectangle().stroke(border(s.state), lineWidth: 1.5))
            Text(s.proof)
                .font(.system(size: 8.5, weight: s.state == .cur ? .semibold : .regular, design: .monospaced))
                .kerning(0.05 * 8.5)
                .textCase(.uppercase)
                .foregroundColor(labelColor(s.state))
        }
        .frame(width: 52)
    }

    private func fill(_ s: RailNodeState) -> Color {
        switch s {
        case .done: return model.c.felt
        case .cur: return model.c.amb
        case .bad: return model.c.bad
        case .idle: return model.c.cd
        }
    }
    private func border(_ s: RailNodeState) -> Color {
        switch s {
        case .done: return model.c.felt
        case .cur: return model.c.amb
        case .bad: return model.c.bad
        case .idle: return model.c.rl2
        }
    }
    private func labelColor(_ s: RailNodeState) -> Color {
        switch s {
        case .done: return model.c.felt
        case .cur: return model.c.amb
        case .bad: return model.c.bad
        case .idle: return model.c.ink3
        }
    }
}

enum RailNodeState: Equatable {
    case done, cur, bad, idle
}

// MARK: - 资产行 / 交易行 / 菜单行

struct ZCTokenBadge: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var tone: ZCChipTone = .neutral

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .frame(width: 26, height: 26)
            .background(bg)
            .cornerRadius(ZCMetrics.chipCorner)
            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(border, lineWidth: 1))
    }
    private var color: Color {
        switch tone {
        case .neutral: return model.c.ink2
        case .play: return model.c.play
        case .real: return model.c.real
        case .felt: return model.c.felt
        default: return model.c.ink2
        }
    }
    private var bg: Color {
        switch tone {
        case .neutral: return model.c.cd2
        case .play: return model.c.playW
        case .real: return model.c.realW
        case .felt: return model.c.feltW
        default: return model.c.cd2
        }
    }
    private var border: Color {
        switch tone {
        case .neutral: return model.c.rl2
        case .play: return model.c.playRl
        case .real: return model.c.realRl
        case .felt: return model.c.feltRl
        default: return model.c.rl2
        }
    }
}

struct ZCAssetRow: View {
    @EnvironmentObject var model: WalletModel
    let token: String
    var tokenTone: ZCChipTone = .neutral
    let name: String
    var nameChip: (String, ZCChipTone)? = nil
    var sub: String? = nil
    var amount: String
    var amountTone: AmountTone = .normal
    var dim: Bool = false
    var action: (() -> Void)? = nil

    enum AmountTone { case normal, pos, neg, bad, dim }

    var body: some View {
        let core = HStack(spacing: 10) {
            ZCTokenBadge(text: token, tone: tokenTone)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(name)
                        .font(.ui(12.5, .semibold))
                        .foregroundColor(model.c.ink)
                        .lineLimit(1)
                    if let chip = nameChip {
                        ZCChip(chip.0, tone: chip.1, xs: true)
                    }
                }
                if let sub {
                    Text(sub)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(model.c.ink3)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 3) {
                Text(amount)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(amountColor)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 9)

        Group {
            if let action {
                Button(action: action) { core.frame(maxWidth: .infinity, alignment: .leading) }
                    .buttonStyle(.plain)
            } else {
                core
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
    }

    private var amountColor: Color {
        if dim || amountTone == .dim { return model.c.ink3 }
        switch amountTone {
        case .pos: return model.c.felt
        case .bad: return model.c.bad
        default: return model.c.ink
        }
    }
}

struct ZCTxRow: View {
    @EnvironmentObject var model: WalletModel
    let icon: ZCIconName
    var iconTone: IconTone = .neutral
    let name: String
    var sub: String? = nil
    var amount: String? = nil
    var amountTone: ZCAssetRow.AmountTone = .normal
    var chip: (String, ZCChipTone)? = nil
    var forceIncludeDisabled: Bool = false

    enum IconTone { case neutral, ok, warn, bad, blue }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                iconBox
                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.ui(12.5, .semibold))
                        .foregroundColor(model.c.ink)
                        .lineLimit(1)
                    if let sub {
                        Text(sub)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(model.c.ink3)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 3) {
                    if let amount {
                        Text(amount)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(amountColor)
                            .lineLimit(1)
                    }
                    if let chip {
                        ZCChip(chip.0, tone: chip.1, xs: true)
                    }
                    if forceIncludeDisabled {
                        ZCButton("ForceInclude 未开放", style: .ghost, small: true, disabled: true)
                    }
                }
            }
            .padding(.vertical, 9)
            if forceIncludeDisabled {
                // 设计：超期回执行下的禁用按钮占位已并入右侧；这里留空
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
    }

    private var iconBox: some View {
        ZCIcon(name: icon, size: 12)
            .foregroundColor(iconColor)
            .frame(width: 22, height: 22)
            .background(iconBg)
            .cornerRadius(ZCMetrics.chipCorner)
            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(iconBorder, lineWidth: 1))
    }
    private var iconColor: Color {
        switch iconTone {
        case .neutral: return model.c.ink2
        case .ok: return model.c.felt
        case .warn: return model.c.amb
        case .bad: return model.c.bad
        case .blue: return model.c.play
        }
    }
    private var iconBg: Color {
        switch iconTone {
        case .neutral: return model.c.cd2
        case .ok: return model.c.feltW
        case .warn: return model.c.ambW
        case .bad: return model.c.badW
        case .blue: return model.c.playW
        }
    }
    private var iconBorder: Color {
        switch iconTone {
        case .neutral: return model.c.rl2
        case .ok: return model.c.feltRl
        case .warn: return model.c.ambRl
        case .bad: return model.c.badRl
        case .blue: return model.c.playRl
        }
    }
    private var amountColor: Color {
        switch amountTone {
        case .pos: return model.c.felt
        case .bad: return model.c.bad
        case .dim: return model.c.ink3
        default: return model.c.ink
        }
    }
}

struct ZCMenuRow: View {
    @EnvironmentObject var model: WalletModel
    let icon: ZCIconName
    var iconTint: Color? = nil
    var iconTone: ZCChipTone = .neutral
    let title: String
    var sub: String? = nil
    var right: RightItem = .chevron
    var danger: Bool = false
    var action: (() -> Void)? = nil

    enum RightItem { case chevron, none, chip(String, ZCChipTone), custom(AnyView) }

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    ZCIcon(name: icon, size: 12)
                        .foregroundColor(iconColor)
                }
                .frame(width: 24, height: 24)
                .background(iconBg)
                .cornerRadius(ZCMetrics.chipCorner)
                .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(iconBorder, lineWidth: 1))

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.ui(12.5, .semibold))
                        .foregroundColor(danger ? model.c.bad : model.c.ink)
                        .lineLimit(1)
                    if let sub {
                        Text(sub)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(model.c.ink3)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 6)
                switch right {
                case .chevron:
                    ZCIcon(name: .chevR, size: 14).foregroundColor(model.c.ink3)
                case .none:
                    EmptyView()
                case .chip(let text, let tone):
                    ZCChip(text, tone: tone, xs: true)
                case .custom(let view):
                    view
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
    }

    private var iconColor: Color { iconTint ?? (danger ? model.c.bad : model.c.ink2) }
    private var iconBg: Color {
        switch iconTone {
        case .amb: return model.c.ambW
        case .bad: return model.c.badW
        case .felt: return model.c.feltW
        default: return model.c.cd2
        }
    }
    private var iconBorder: Color {
        switch iconTone {
        case .amb: return model.c.ambRl
        case .bad: return model.c.badRl
        case .felt: return model.c.feltRl
        default: return model.c.rl2
        }
    }
}

// MARK: - 提示条（banner）

struct ZCBanner: View {
    @EnvironmentObject var model: WalletModel
    let kind: Kind
    let title: String
    var body_: String? = nil

    enum Kind { case ok, bad, info, amb, real }

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            ZCIcon(name: iconName, size: 17)
                .foregroundColor(color)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.ui(12, .semibold))
                    .foregroundColor(color)
                if let body_ {
                    Text(body_)
                        .font(.ui(11.5))
                        .foregroundColor(model.c.ink2)
                        .lineSpacing(2.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
        .cornerRadius(ZCMetrics.corner)
        .overlay(
            RoundedRectangle(cornerRadius: ZCMetrics.corner)
                .stroke(border, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            Rectangle().fill(color).frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: ZCMetrics.corner))
        .padding(.bottom, 12)
    }

    private var iconName: ZCIconName {
        switch kind {
        case .bad, .real: return .warn
        case .ok: return .check
        case .amb: return .lock
        case .info: return .info
        }
    }
    private var color: Color {
        switch kind {
        case .ok: return model.c.felt
        case .bad: return model.c.bad
        case .info: return model.c.play
        case .amb: return model.c.amb
        case .real: return model.c.real
        }
    }
    private var bg: Color {
        switch kind {
        case .ok: return model.c.feltW
        case .bad: return model.c.badW
        case .info: return model.c.playW
        case .amb: return model.c.ambW
        case .real: return model.c.realW
        }
    }
    private var border: Color {
        switch kind {
        case .ok: return model.c.feltRl
        case .bad: return model.c.badRl
        case .info: return model.c.playRl
        case .amb: return model.c.ambRl
        case .real: return model.c.realRl
        }
    }
}

/// 不可提交原因行（rsn）。
struct ZCReasonRow: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var qualifier: String? = nil
    var qualifierTone: ZCChipTone = .amb
    var real: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            ZCIcon(name: real ? .lock : .x, size: 13)
                .foregroundColor(real ? model.c.real : model.c.bad)
                .padding(.top, 2)
            Text(text)
                .font(.ui(11.5))
                .foregroundColor(model.c.ink2)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let qualifier {
                ZCChip(qualifier, tone: qualifierTone, xs: true)
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - 空状态 / meter / 步骤

struct ZCEmptyBox: View {
    @EnvironmentObject var model: WalletModel
    let text: String

    var body: some View {
        Text(text)
            .font(.ui(11.5))
            .foregroundColor(model.c.ink3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 14)
            .background(model.c.cd)
            .cornerRadius(ZCMetrics.corner)
            .overlay(
                RoundedRectangle(cornerRadius: ZCMetrics.corner)
                    .strokeBorder(model.c.rl2, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
    }
}

struct ZCMeter: View {
    @EnvironmentObject var model: WalletModel
    let percent: Double
    var warn: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(model.c.pg2)
                Rectangle()
                    .fill(warn ? model.c.amb : model.c.felt)
                    .frame(width: max(0, min(100, percent)) / 100 * geo.size.width)
            }
        }
        .frame(height: 4)
        .cornerRadius(1)
        .overlay(Rectangle().stroke(model.c.rl, lineWidth: 1))
        .animation(ZCAnim.std, value: percent)
    }
}

struct ZCStepRow: View {
    @EnvironmentObject var model: WalletModel
    let index: Int
    let state: StepState
    let title: String
    var sub: String? = nil
    var spinning: Bool = false

    enum StepState { case idle, done, run, bad }

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            badge
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.ui(12, .semibold))
                    .foregroundColor(model.c.ink)
                if let sub {
                    Text(sub)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(model.c.ink3)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
    }

    @ViewBuilder
    private var badge: some View {
        Group {
            switch state {
            case .done:
                ZStack { RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).fill(model.c.felt)
                    ZCIcon(name: .check, size: 10).foregroundColor(model.c.onFelt) }
            case .run:
                ZStack { RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).fill(model.c.ambW)
                    ZCIcon(name: .refresh, size: 10).foregroundColor(model.c.amb) }
                    .modifier(SpinEffect(active: spinning))
            case .bad:
                ZStack { RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).fill(model.c.badW)
                    ZCIcon(name: .x, size: 10).foregroundColor(model.c.bad) }
            case .idle:
                ZStack { RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).fill(model.c.cd2)
                    Text("\(index)").font(.system(size: 9.5, design: .monospaced)).foregroundColor(model.c.ink3) }
            }
        }
        .frame(width: 18, height: 18)
        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner)
            .stroke(state == .done ? model.c.felt : state == .run ? model.c.amb : state == .bad ? model.c.bad : model.c.rl2, lineWidth: 1))
    }
}

struct SpinEffect: ViewModifier {
    var active: Bool
    @State private var spinning = false
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .onAppear { if active { spinning = true } }
            .onDisappear { spinning = false }
            .animation(active ? .linear(duration: 1.2).repeatForever(autoreverses: false) : nil, value: spinning)
    }
}

// MARK: - 表单

struct ZCFieldLabel: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var aux: String? = nil
    var auxButton: (String, () -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .kerning(0.05 * 11)
                .textCase(.uppercase)
                .foregroundColor(model.c.ink2)
            Spacer(minLength: 4)
            if let aux {
                Text(aux)
                    .font(.system(size: 10.5, design: .monospaced))
                    .textCase(.none)
                    .foregroundColor(model.c.ink3)
            }
            if let (label, action) = auxButton {
                Button(action: action) {
                    Text(label)
                        .font(.system(size: 10.5, design: .monospaced))
                        .underline()
                        .foregroundColor(model.c.felt)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 5)
    }
}

struct ZCField<Content: View>: View {
    var label: String? = nil
    var aux: String? = nil
    var auxButton: (String, () -> Void)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label {
                ZCFieldLabel(text: label, aux: aux, auxButton: auxButton)
            } else if let aux {
                ZCFieldLabel(text: " ", aux: aux, auxButton: auxButton)
                    .hidden()
                    .frame(height: 0)
            }
            content()
        }
        .padding(.bottom, 13)
    }
}

/// 普通输入框（42px、3px 圆角、细线描边，聚焦转墨线）。
struct ZCInput: View {
    @EnvironmentObject var model: WalletModel
    var placeholder: String = ""
    var text: Binding<String>
    var secure: Bool = false
    var mono: Bool = false
    var smallFont: Bool = false
    var keyboardType: UIKeyboardTypeCompat = .default

    enum UIKeyboardTypeCompat { case `default`, decimal, numberPad, emailAddress, url }

    var body: some View {
        // macOS 验收模式：AppKit TextField 无法被 ImageRenderer 离屏渲染
        // （显示为黄色占位块），改用同款式的静态文本。
        #if os(macOS)
        if DemoShot.isEnabled {
            chrome {
                Text(text.wrappedValue.isEmpty ? placeholder : text.wrappedValue)
                    .font(mono ? .system(size: smallFont ? 11.5 : 13, design: .monospaced) : .ui(13))
                    .foregroundColor(text.wrappedValue.isEmpty ? model.c.ink3 : model.c.ink)
            }
        } else {
            chrome { editable }
        }
        #else
        chrome { editable }
        #endif
    }

    @ViewBuilder
    private var editable: some View {
        if secure {
            SecureField(placeholder, text: text)
        } else {
            TextField(placeholder, text: text)
        }
    }

    private func chrome<Inner: View>(@ViewBuilder inner: () -> Inner) -> some View {
        inner()
            .font(mono ? .system(size: smallFont ? 11.5 : 13, design: .monospaced) : .ui(13))
            .foregroundColor(model.c.ink)
            .padding(.horizontal, 12)
            .frame(height: ZCMetrics.inputHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(model.c.cd)
            .cornerRadius(ZCMetrics.corner)
            .overlay(
                RoundedRectangle(cornerRadius: ZCMetrics.corner)
                    .stroke(model.c.rl2, lineWidth: 1)
            )
            .autocorrectionDisabled()
            .platformInputModifiers(keyboardType)
    }
}

/// 金额大字输入（56px mono + 右侧单位块 tsel）。
struct ZCAmountInput: View {
    @EnvironmentObject var model: WalletModel
    var text: Binding<String>
    let unit: String
    var unitTone: ZCChipTone = .neutral
    var placeholder: String = "0"

    private var editable: some View {
        TextField(placeholder, text: text)
            .font(.system(size: 24, weight: .semibold, design: .monospaced))
            .foregroundColor(model.c.ink)
            .padding(.leading, 12)
            .frame(height: ZCMetrics.amountInputHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(model.c.cd)
            .cornerRadius(ZCMetrics.corner)
            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
            .autocorrectionDisabled()
            .platformInputModifiers(.decimal)
    }

    private var staticDemo: some View {
        Text(text.wrappedValue.isEmpty ? placeholder : text.wrappedValue)
            .font(.system(size: 24, weight: .semibold, design: .monospaced))
            .foregroundColor(text.wrappedValue.isEmpty ? model.c.ink3 : model.c.ink)
            .padding(.leading, 12)
            .frame(height: ZCMetrics.amountInputHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        ZStack {
            #if os(macOS)
            if DemoShot.isEnabled { staticDemo } else { editable }
            #else
            editable
            #endif
            HStack {
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    ZCTokenBadge(text: String(unit.prefix(1)), tone: unitTone)
                        .frame(width: 18, height: 18)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                    Text(unit)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(model.c.ink)
                }
                .padding(.horizontal, 9)
                .frame(height: 44)
                .background(model.c.pg2)
                .cornerRadius(ZCMetrics.chipCorner)
                .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(model.c.rl2, lineWidth: 1))
                .padding(6)
            }
            .allowsHitTesting(false)
        }
    }
}

/// fiat 说明行。
struct ZCFiatNote: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 10.5, design: .monospaced))
            .foregroundColor(model.c.ink3)
            .padding(.top, 5)
    }
}

/// 方形勾选（chk / cb）。
struct ZCCheckbox: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    @Binding var on: Bool

    var body: some View {
        Button {
            on.toggle()
        } label: {
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    if on { ZCIcon(name: .check, size: 10).foregroundColor(model.c.onInk) }
                }
                .frame(width: 17, height: 17)
                .background(on ? model.c.ink : model.c.cd)
                .cornerRadius(ZCMetrics.chipCorner)
                .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner)
                    .stroke(on ? model.c.ink : model.c.ink3, lineWidth: 1.5))
                Text(text)
                    .font(.ui(11.5))
                    .foregroundColor(model.c.ink2)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 方形开关（sw2）。
struct ZCSwitch: View {
    @EnvironmentObject var model: WalletModel
    @Binding var on: Bool

    var body: some View {
        Button {
            on.toggle()
        } label: {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: ZCMetrics.chipCorner)
                    .fill(on ? model.c.feltW : model.c.pg2)
                    .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner)
                        .stroke(on ? model.c.felt : model.c.rl2, lineWidth: 1))
                RoundedRectangle(cornerRadius: 1)
                    .fill(on ? model.c.felt : model.c.ink3)
                    .frame(width: 14, height: 14)
                    .offset(x: on ? 20 : 2)
            }
            .frame(width: 38, height: 20)
        }
        .buttonStyle(.plain)
        .animation(ZCAnim.std, value: on)
    }
}

/// 分段器（seg）。
struct ZCSegmented: View {
    @EnvironmentObject var model: WalletModel
    let items: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                Button {
                    selection = i
                } label: {
                    Text(item)
                        .font(.system(size: 11.5, weight: selection == i ? .semibold : .regular, design: .monospaced))
                        .foregroundColor(selection == i ? model.c.onInk : model.c.ink2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(selection == i ? model.c.ink : model.c.cd)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(model.c.rl2)
        .cornerRadius(ZCMetrics.corner)
        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
        .padding(.bottom, 13)
    }
}

/// 链切换器（csw：三链一格，链=筛选器）。
struct ZCChainSwitcher: View {
    @EnvironmentObject var model: WalletModel
    let counts: [Int]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Chain.allCases.enumerated()), id: \.offset) { i, chain in
                let on = model.chain == chain
                Button {
                    model.selectChain(chain)
                } label: {
                    HStack(spacing: 4) {
                        Text(chain.label)
                            .font(.system(size: 11, weight: on ? .semibold : .regular, design: .monospaced))
                        if counts.indices.contains(i) {
                            Text("\(counts[i])")
                                .font(.system(size: 9, design: .monospaced))
                                .opacity(0.7)
                        }
                    }
                    .foregroundColor(on ? model.c.onInk : model.c.ink2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(on ? model.c.ink : model.c.cd)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if i < Chain.allCases.count - 1 {
                    Rectangle().fill(model.c.ink).frame(width: 1)
                }
            }
        }
        .frame(height: 34)
        .background(model.c.ink)
        .cornerRadius(ZCMetrics.corner)
        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.ink, lineWidth: 1))
        .padding(.bottom, 14)
    }
}

/// 口令/地址展示条（pass 块 + 复制按钮）。
struct ZCPassBox: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var copyKind: CopyKind = .text
    var warn: String? = nil

    enum CopyKind { case text, password, privatekey, address }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Text(text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(model.c.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ZCIconBtn(icon: .copy) {
                    model.copy(text, kind: copyKind)
                }
            }
            .padding(11)
            if let warn {
                Text(warn)
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 11)
                    .padding(.bottom, 10)
            }
        }
        .background(model.c.code)
        .cornerRadius(ZCMetrics.corner)
        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
    }
}

/// 原始摘要块（raw）。
struct ZCRawBox: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 9.5, design: .monospaced))
            .foregroundColor(model.c.ink3)
            .lineSpacing(2)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(model.c.code)
            .cornerRadius(ZCMetrics.chipCorner)
            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(model.c.rl, lineWidth: 1))
    }
}

/// 错误行 / 成功行（errx / okx）。
struct ZCResultLine: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var code: String? = nil
    var ok: Bool = false

    var body: some View {
        if !text.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(text)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(ok ? model.c.felt : model.c.bad)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                if let code {
                    Text(code)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(ok ? model.c.felt : model.c.bad)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 0.5)
                        .background(ok ? model.c.feltW : model.c.badW)
                        .cornerRadius(ZCMetrics.chipCorner)
                        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(ok ? model.c.feltRl : model.c.badRl, lineWidth: 1))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
        }
    }
}

/// 页脚小字（foot）。
struct ZCFoot: View {
    @EnvironmentObject var model: WalletModel
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 9.5, design: .monospaced))
            .kerning(0.06 * 9.5)
            .foregroundColor(model.c.ink3)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
    }
}

/// 详情折叠（details/summary）。
struct ZCDisclosure<Content: View>: View {
    @EnvironmentObject var model: WalletModel
    let summary: String
    @ViewBuilder var content: () -> Content
    @State private var open = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Button {
                withAnimation(ZCAnim.std) { open.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(open ? "▾" : "▸")
                        .font(.system(size: 9, design: .monospaced))
                    Text(summary)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(model.c.ink3)
                }
            }
            .buttonStyle(.plain)
            if open { content() }
        }
        .padding(.top, 12)
    }
}

// MARK: - 布局辅助

extension View {
    func asButton(action: @escaping () -> Void) -> some View {
        Button(action: action) { self.contentShape(Rectangle()) }
            .buttonStyle(.plain)
    }
    /// 平台相关输入修饰（键盘类型 + 不自动大写；macOS 下 no-op）。
    func platformInputModifiers(_ type: ZCInput.UIKeyboardTypeCompat) -> some View {
        #if canImport(UIKit)
        switch type {
        case .default: return AnyView(self.keyboardType(.default).textInputAutocapitalization(.never))
        case .decimal: return AnyView(self.keyboardType(.decimalPad).textInputAutocapitalization(.never))
        case .numberPad: return AnyView(self.keyboardType(.numberPad).textInputAutocapitalization(.never))
        case .emailAddress: return AnyView(self.keyboardType(.emailAddress).textInputAutocapitalization(.never))
        case .url: return AnyView(self.keyboardType(.URL).textInputAutocapitalization(.never))
        }
        #else
        _ = type
        return AnyView(self)
        #endif
    }
}

/// 动效时长词汇（§7：std 进入、out 离场、seal 印章过冲 ≤1.06）。
enum ZCAnim {
    static let std = Animation.timingCurve(0.2, 0, 0.38, 1, duration: 0.16)
    static let out = Animation.timingCurve(0, 0, 0.3, 1, duration: 0.14)
    static let seal = Animation.timingCurve(0.34, 1.3, 0.64, 1, duration: 0.26)
}
