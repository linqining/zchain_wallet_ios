import SwiftUI

// ============================================================================
// Screens1_Guide — 01 欢迎 / 02 创建成功 / 03 导入恢复 / 04 统一解锁
// ============================================================================

// MARK: - 封面容器（cover：账格纸纹背景）

struct ZCCover<Content: View>: View {
    @EnvironmentObject var model: WalletModel
    @ViewBuilder var content: () -> Content
    var foot: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RuledPaperPattern()
                content()
                    .padding(.horizontal, 22)
                    .padding(.top, 26)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            if let foot {
                Text(foot)
                    .font(.system(size: 9, design: .monospaced))
                    .kerning(0.08 * 9)
                    .textCase(.uppercase)
                    .foregroundColor(model.c.ink3)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(alignment: .top) { Rectangle().fill(model.c.rl).frame(height: 1) }
            }
        }
    }
}

// MARK: - 01 欢迎 · 一次创建三层

struct WelcomeScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var showAdvanced = false
    @State private var pw1 = ""
    @State private var pw2 = ""

    var body: some View {
        ScreenScaffold {
            ZCCover(foot: "设计稿 v0.2 · 对齐 Extension 0.6.1 · iOS · 继续即代表知悉测试网风险\nPlay / DevNet / v1.3") {
                VStack(alignment: .leading, spacing: 0) {
                    ZCChip("DevNet", tone: .solid)
                        .padding(.bottom, 12)
                    ZCLogo(size: 44)
                    Text("ZChain Wallet")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(model.c.ink)
                        .padding(.top, 14)
                    Text("桌上飞快，结算可证")
                        .font(.ui(12.5))
                        .foregroundColor(model.c.ink2)
                        .padding(.top, 3)
                    Text("FAST AT THE TABLE. VERIFIABLE AT SETTLEMENT.")
                        .font(.system(size: 9.5, design: .monospaced))
                        .kerning(0.14 * 9.5)
                        .foregroundColor(model.c.ink3)
                        .padding(.top, 5)

                    // 三格 meta（细线分隔）
                    HStack(spacing: 1) {
                        metaCell("3", "账户层")
                        metaCell("2 套 KDF", "本地加密")
                        metaCell("STARK", "可复验")
                    }
                    .background(model.c.rl)
                    .cornerRadius(ZCMetrics.corner)
                    .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl, lineWidth: 1))
                    .padding(.top, 18)

                    HStack(spacing: 6) {
                        ZCChip("ZChain 隐私层", tone: .felt)
                        ZCChip("EVM 多链", tone: .neutral)
                        ZCChip("Starknet", tone: .neutral)
                    }
                    .padding(.top, 14)

                    Spacer(minLength: 0)

                    VStack(spacing: 8) {
                        ZCButton("一键创建钱包", icon: .plus, action: { model.quickCreate() })
                        ZCButton("导入或恢复钱包", style: .secondary) { model.go(.importScreen) }

                        ZCDisclosure(summary: "高级：自定义解锁口令创建") {
                            VStack(alignment: .leading, spacing: 0) {
                                ZCField(label: "自定义口令") {
                                    ZCInput(placeholder: "≥ 8 位", text: $pw1, secure: true)
                                }
                                ZCField(label: "确认口令") {
                                    ZCInput(placeholder: "再次输入", text: $pw2, secure: true)
                                }
                                ZCButton("用自定义口令创建", style: .secondary) {
                                    if pw1.count < 8 {
                                        model.showToast("口令太短（≥ 8 字符）")
                                    } else if pw1 != pw2 {
                                        model.showToast("两次口令不一致")
                                    } else {
                                        model.quickCreate()
                                    }
                                }
                                .padding(.top, 2)
                            }
                        }

                        Text("一次创建三层账户：ZChain 隐私层 + EVM 多链 + Starknet")
                            .font(.ui(10.5))
                            .foregroundColor(model.c.ink3)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            }
        } footer: {}
    }

    private func metaCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(model.c.ink)
            Text(label)
                .font(.system(size: 8.5, design: .monospaced))
                .kerning(0.1 * 8.5)
                .textCase(.uppercase)
                .foregroundColor(model.c.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(model.c.cd)
    }
}

// MARK: - 02 创建成功 · 解锁口令只显示一次

struct SuccessScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var saved = false

    var body: some View {
        ScreenScaffold {
            ZCBody {
                if let created = model.generatedPassword {
                    VStack(spacing: 0) {
                        ZCSeal(text: "已创建", tone: .ok, animate: true)
                            .padding(.top, 22)
                        Text("钱包已创建")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(model.c.ink)
                            .padding(.top, 14)
                        Text("三层账户已就绪，先保存好解锁口令。")
                            .font(.ui(12))
                            .foregroundColor(model.c.ink2)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)

                    if created.generated {
                        ZCBanner(kind: .bad, title: "解锁口令只显示这一次",
                                 body_: "钱包不存储口令；丢失后仅能通过加密备份恢复。")
                        ZCPassBox(text: created.password, copyKind: .password,
                                  warn: "复制到剪贴板后，其他可读剪贴板的应用都可能拿到这串口令。请立即保存并清空剪贴板——钱包不存储口令，丢失只能靠加密备份恢复。")
                            .padding(.bottom, 12)
                    }

                    ZCCard(title: "三层地址") {
                        addressRow("ZChain", created.zc)
                        addressRow("EVM", created.evm)
                        addressRow("Starknet", created.stk)
                    }

                    ZCCheckbox(text: "我已将口令保存在安全的地方（密码管理器 / 纸质备份）", on: $saved)
                        .padding(.vertical, 2)
                        .padding(.bottom, 14)

                    ZCButton("我已保存，开始使用", large: true, disabled: !saved) {
                        model.generatedPassword = nil
                        model.go(.home)
                    }
                }
            }
        } footer: {}
    }

    private func addressRow(_ label: String, _ addr: String) -> some View {
        ZCLedgerRow {
            Text(label)
        } value: {
            HStack(spacing: 4) {
                Text(addr)
                ZCIcon(name: .copy, size: 12)
                    .asButton { model.copy(addr, kind: .address) }
            }
        }
    }
}

// MARK: - 03 导入 / 恢复

struct ImportScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var seg = 0
    @State private var backupPw = ""
    @State private var importKey = ""
    @State private var importPw = ""
    @State private var layer = "evm"
    @State private var fileName: String? = nil
    @State private var okMsg = ""

    var body: some View {
        ScreenScaffold {
            ZCSubHeader(title: "导入 / 恢复")
            ZCBody {
                ZCSegmented(items: ["备份恢复", "私钥导入"], selection: $seg)

                if seg == 0 {
                    Button {
                        model.showToast("演示态：请在「设置 → 备份导出」先生成 .zcbk（本版本不读写文件）")
                    } label: {
                        VStack(spacing: 0) {
                            ZCIcon(name: .ul, size: 18).foregroundColor(model.c.ink2)
                            Text("选择 .zcbk 备份文件")
                                .font(.ui(13, .semibold))
                                .foregroundColor(model.c.ink)
                                .padding(.top, 7)
                            Text("由「设置 → 备份导出」生成 · 仅 ZChain 层 note 库")
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(model.c.ink3)
                                .padding(.top, 3)
                            if let fileName {
                                Text("已选择：\(fileName)")
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundColor(model.c.ink3)
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(model.c.cd)
                        .cornerRadius(ZCMetrics.corner)
                        .overlay(
                            RoundedRectangle(cornerRadius: ZCMetrics.corner)
                                .strokeBorder(model.c.rl2, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 10)

                    ZCField(label: "备份口令") {
                        ZCInput(placeholder: "≥ 8 位，与钱包解锁口令相互独立", text: $backupPw, secure: true)
                    }
                    ZCButton("恢复钱包") {
                        guard !backupPw.isEmpty else {
                            model.showToast("请输入备份口令")
                            return
                        }
                        okMsg = "恢复完成：新增锁定账户（3 commitments / 3 nullifiers）。用备份口令解锁该账户即可使用。"
                        model.showToast("恢复成功：新账户为锁定态")
                        backupPw = ""
                    }
                    ZCBanner(kind: .info, title: "只覆盖 ZChain 层",
                             body_: "ZCBK v1 含 REAL/PLAY 双库与 keystore 信封，不含 EVM / Starknet 账户——那两层请在各自管理页导出私钥。解密全程本地完成，备份口令不离开设备。")
                } else {
                    ZCField(label: "目标层") {
                        HStack(spacing: 1) {
                            layerOption("evm", "EVM · secp256k1")
                            layerOption("stk", "Starknet · STARK curve")
                        }
                        .background(model.c.rl2)
                        .cornerRadius(ZCMetrics.corner)
                        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
                    }
                    ZCField(label: "私钥（hex）", aux: "默认掩码显示 · ") {
                        ZCInput(placeholder: "0x… 或裸 hex", text: $importKey, secure: true, mono: true, smallFont: true)
                    }
                    Text("私钥以明文交给本层解锁会话，不落盘；肩窥与截屏风险由你自己承担——这是导入私钥固有的暴露面。")
                        .font(.ui(10.5))
                        .foregroundColor(model.c.ink3)
                        .lineSpacing(2)
                        .padding(.bottom, 10)
                    ZCField(label: "加密口令") {
                        ZCInput(placeholder: "用于本地 keystore 加密（≥ 8 位）", text: $importPw, secure: true)
                    }
                    ZCButton("导入到所选层") {
                        guard !importKey.isEmpty, !importPw.isEmpty else {
                            model.showToast("请填写私钥与加密口令")
                            return
                        }
                        let addr = layer == "evm" ? "0x" + String(importKey.suffix(8)) : "0x" + String(importKey.suffix(8))
                        okMsg = "已导入 \(layer == "evm" ? "EVM" : "Starknet") 账户 \(shortAddr(addr))（锁定态，需口令解锁）。"
                        model.showToast("导入成功：已新增账户（锁定态）")
                        importKey = ""
                        importPw = ""
                    }
                    Text("ZChain note 层不支持私钥导入：note 库由 wallet-core 派生，只能经 .zcbk 备份恢复。")
                        .font(.ui(10.5))
                        .foregroundColor(model.c.ink3)
                        .lineSpacing(2)
                        .padding(.top, 12)
                }

                ZCResultLine(text: okMsg, ok: true)
            }
        } footer: {}
    }

    private func layerOption(_ value: String, _ label: String) -> some View {
        let on = layer == value
        return Button {
            layer = value
        } label: {
            Text(label)
                .font(.system(size: 11.5, weight: on ? .semibold : .regular, design: .monospaced))
                .foregroundColor(on ? model.c.onInk : model.c.ink2)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(on ? model.c.ink : model.c.cd)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 04 锁定 · 统一解锁

struct LockScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var pw = ""

    var body: some View {
        ScreenScaffold {
            ZCCover(foot: "统一解锁三层 · ZChain 层 Argon2id + ChaCha20-Poly1305，EVM / Starknet 层 PBKDF2-SHA256(600k) + AES-256-GCM") {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text(String(model.walletLabel.prefix(1)))
                        .font(.system(size: 19, weight: .bold, design: .monospaced))
                        .foregroundColor(model.c.onInk)
                        .frame(width: 52, height: 52)
                        .background(model.c.ink)
                        .cornerRadius(ZCMetrics.chipCorner)
                    Text(model.walletLabel)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(model.c.ink)
                        .padding(.top, 12)
                    Text(shortAddr(model.layers["zchain"]?.address ?? "", 10, 4))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(model.c.ink3)
                        .padding(.top, 2)
                    HStack(spacing: 6) {
                        ZCChip("已锁定", tone: .amb)
                        let n = model.unlockCount
                        ZCChip("已解锁 \(n.unlocked) / \(n.held)", tone: .neutral)
                        if model.pendingRequest != nil {
                            ZCChip("1 项待确认", tone: .bad)
                        }
                    }
                    .padding(.top, 12)

                    VStack(spacing: 0) {
                        ZCInput(placeholder: "解锁口令", text: $pw, secure: true)
                        ZCButton("解锁三层") {
                            if model.quickUnlock(password: pw) {
                                pw = ""
                                model.go(.home)
                            } else {
                                model.showToast("请输入解锁口令")
                            }
                        }
                        .padding(.top, 10)
                        if model.pendingRequest != nil {
                            ZCButton("查看 1 项待确认", style: .secondary) { model.go(.zcConfirm) }
                                .padding(.top, 4)
                        } else {
                            ZCButton("忘记口令？使用备份恢复", style: .ghost) { model.go(.importScreen) }
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 22)
                    .frame(maxWidth: 282)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            }
        } footer: {}
    }
}
