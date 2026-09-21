import SwiftUI

// ============================================================================
// ZChainWalletApp — iOS 原生 SwiftUI 入口（方向 B「账簿 / Ledger」）。
// 布局骨架与设计稿一致：抬头（票据两行 + 齿孔线）/ 滚动正文 / 底部三 tab。
// ============================================================================

@main
struct ZChainWalletApp: App {
    @StateObject private var model = WalletModel()

    #if os(macOS)
    init() {
        if DemoShot.isEnabled {
            // 验收模式：用独立 model（init 内应用 ZC_* 环境钩子）离屏渲染后退出。
            let shotModel = WalletModel()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 600_000_000)
                DemoShot.renderAndExit(model: shotModel)
            }
        }
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        ZStack {
            model.c.pg.ignoresSafeArea()
            VStack(spacing: 0) {
                screenBody
                    .id(model.screen)
                    .transition(.opacity.combined(with: .offset(y: 4)))
            }
            overlayLayer
            toastLayer
        }
        // macOS 演示构建用手机比例窗口（iOS 上不生效，不影响真机布局）。
        #if os(macOS)
        .frame(width: 390, height: DemoShot.renderHeight)
        #endif
        .environment(\.colorScheme, model.ground == .night ? .dark : .light)
        .animation(ZCAnim.std, value: model.screen)
        .animation(ZCAnim.std, value: model.ground)
    }

    @ViewBuilder
    private var screenBody: some View {
        switch model.screen {
        case .welcome: WelcomeScreen()
        case .success: SuccessScreen()
        case .importScreen: ImportScreen()
        case .lock: LockScreen()
        case .home: HomeScreen()
        case .acct: LedgerScreen()
        case .zcSend: ZCSendScreen()
        case .zcWithdraw: ZCWithdrawScreen()
        case .zcConfirm: ZCConfirmScreen()
        case .zcSessions: ZCSessionsScreen()
        case .zcPortal: ZCPortalScreen()
        case .zcReceipts: ZCReceiptsScreen()
        case .send: ChainSendScreen()
        case .contract: ChainContractScreen()
        case .history: ChainHistoryScreen()
        case .manage: ChainManageScreen()
        case .proofs: ProofsScreen()
        case .settings: SettingsScreen()
        }
    }

    @ViewBuilder
    private var overlayLayer: some View {
        if let spec = model.overlay {
            ZStack {
                model.c.overlayBg
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(ZCAnim.out) { model.overlay = nil } }
                switch spec.kind {
                case .receive(let chain): ReceiveSheet(chain: chain)
                case .accountSwitch: AccountSwitchSheet()
                case .networkPicker: NetworkPickerSheet()
                case .revokeConfirm(let binding): RevokeModal(binding: binding)
                case .removeAccount(let chain): RemoveAccountModal(chain: chain)
                case .capabilityMatrix: CapabilityMatrixModal()
                }
            }
            .transition(.opacity)
            .zIndex(10)
        }
    }

    @ViewBuilder
    private var toastLayer: some View {
        if let msg = model.toastMsg {
            HStack(spacing: 8) {
                ZCIcon(name: .info, size: 14).foregroundColor(model.c.onInk)
                Text(msg)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(model.c.onInk)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(model.c.ink)
            .cornerRadius(ZCMetrics.corner)
            .padding(.horizontal, 14)
            .padding(.bottom, 66)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
            .zIndex(20)
            .transition(.opacity.combined(with: .offset(y: 6)))
        }
    }
}

// MARK: - 屏幕骨架

/// 通用骨架：抬头 + 滚动正文 + 底部（tab 或空）。
struct ScreenScaffold<Content: View, Footer: View>: View {
    @ViewBuilder var header: () -> Content
    @ViewBuilder var footer: () -> Footer

    init(@ViewBuilder header: @escaping () -> Content,
         @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }) {
        self.header = header
        self.footer = footer
    }

    var body: some View {
        VStack(spacing: 0) {
            header()
            footer()
        }
    }
}

/// 正文滚动容器（.body：padding 14/16/18）。
/// macOS 验收模式（ZC_SHOT 存在）下免滚动：ImageRenderer 对 ScrollView
/// 的离屏渲染不包含 viewport 内容，此处改为平铺布局保证可渲染。
struct ZCBody<Content: View>: View {
    @ViewBuilder var content: () -> Content

    private var inner: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(.top, 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        #if os(macOS)
        if DemoShot.isEnabled {
            inner
        } else {
            ScrollView(showsIndicators: false) { inner }
        }
        #else
        ScrollView(showsIndicators: false) { inner }
        #endif
    }
}

/// 票据抬头（.dh：两行 + 齿孔线）。
struct ZCDocHeader: View {
    @EnvironmentObject var model: WalletModel
    let kind: String
    let netText: String?
    var netAction: (() -> Void)? = nil
    let addrText: String
    var showCopy: Bool = false
    var lockAction: (() -> Void)? = nil
    var mainTitle: String? = nil       // 覆盖默认（walletLabel）
    var mainSeal: String? = nil        // 凭证簿用 seal 替代头像
    var sealTone: ZCSealTone = .ok

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // 第一行：kind + 网络 + 右侧动作
                HStack(spacing: 8) {
                    Text(kind)
                        .font(.system(size: 9.5, design: .monospaced))
                        .kerning(0.16 * 9.5)
                        .textCase(.uppercase)
                        .foregroundColor(model.c.ink3)
                        .lineLimit(1)
                    if let netText {
                        ZCNetBadge(text: netText, action: netAction)
                    }
                    Spacer(minLength: 4)
                    ZCIconBtn(icon: model.hideAmount ? .eyeOff : .eye, bare: true) {
                        model.hideAmount.toggle()
                        model.persistPrefs()
                    }
                    ZCIconBtn(icon: .gear, bare: true) { model.go(.settings) }
                }
                .frame(height: 20)
                // 第二行：头像 + 账户名 + 地址 + 复制/锁定
                HStack(spacing: 9) {
                    if let seal = mainSeal {
                        ZCSeal(text: seal, tone: sealTone)
                    } else {
                        Text(String((mainTitle ?? model.walletLabel).prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(model.c.onInk)
                            .frame(width: 30, height: 30)
                            .background(model.c.ink)
                            .cornerRadius(ZCMetrics.chipCorner)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            Text(mainTitle ?? model.walletLabel)
                                .font(.ui(13.5, .semibold))
                                .foregroundColor(model.c.ink)
                                .lineLimit(1)
                            ZCIcon(name: .chevD, size: 12).foregroundColor(model.c.ink3)
                        }
                        Text(addrText)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(model.c.ink3)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer(minLength: 4)
                    if showCopy {
                        ZCIconBtn(icon: .copy) {
                            model.copy(addrText, kind: .address)
                        }
                    }
                    if let lockAction {
                        ZCIconBtn(icon: .lock, action: lockAction)
                    }
                }
                .padding(.top, 3)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 14)
            .padding(.top, 9)
            .background(model.c.cd)
            PerforationLine()
                .padding(.top, 2)
                .background(model.c.pg)
        }
        .background(model.c.cd)
    }
}

/// 子页栏（.sub：方形返回 + 居中标题 + 右槽 + 齿孔线）。
struct ZCSubHeader: View {
    @EnvironmentObject var model: WalletModel
    let title: String
    var closeIcon: Bool = false
    @ViewBuilder var right: () -> AnyView

    init(title: String, closeIcon: Bool = false, right: @escaping () -> AnyView = { AnyView(EmptyView()) }) {
        self.title = title
        self.closeIcon = closeIcon
        self.right = right
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ZCIconBtn(icon: closeIcon ? .x : .back, bare: true) { model.back() }
                Text(title)
                    .font(.ui(14, .semibold))
                    .foregroundColor(model.c.ink)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                right()
                    .frame(width: 56, alignment: .trailing)
            }
            .frame(height: 46)
            .padding(.horizontal, 10)
            .background(model.c.cd)
            PerforationLine()
                .padding(.top, 2)
                .background(model.c.pg)
        }
        .zIndex(2)
    }
}

/// 底部三 tab（总账 / 账簿 / 证明）。
struct ZCTabsBar: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        HStack(spacing: 0) {
            tab(.home, title: "总账", icon: .home)
            tab(.acct, title: "账簿", icon: .book)
            tab(.proofs, title: "证明", icon: .file)
        }
        .frame(height: 52)
        .background(model.c.cd)
        .overlay(alignment: .top) { Rectangle().fill(model.c.rl2).frame(height: 1) }
    }

    private func tab(_ kind: TabKind, title: String, icon: ZCIconName) -> some View {
        let on = model.screen.tab == kind
        return Button {
            switch kind {
            case .home: model.go(.home)
            case .acct: model.go(.acct, chain: model.chain)
            case .proofs: model.go(.proofs)
            }
        } label: {
            VStack(spacing: 3) {
                ZCIcon(name: icon, size: 17)
                Text(title)
                    .font(.system(size: 10.5, weight: on ? .semibold : .regular, design: .monospaced))
                    .kerning(0.04 * 10.5)
            }
            .foregroundColor(on ? model.c.ink : model.c.ink3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if on {
                    Rectangle().fill(model.c.felt)
                        .frame(width: 34, height: 3)
                        .offset(y: -1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
