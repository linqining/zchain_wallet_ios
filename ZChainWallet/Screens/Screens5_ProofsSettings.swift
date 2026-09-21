import SwiftUI

// ============================================================================
// Screens5_ProofsSettings — 18 凭证簿（proofs）/ 19 设置 · 能力矩阵（settings）
// ============================================================================

// MARK: - 18 凭证簿

struct ProofsScreen: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        ScreenScaffold {
            ZCDocHeader(
                kind: "Proofs",
                netText: "engine stwo",
                addrText: "最近 24 小时 · 5 份结算证明",
                lockAction: nil,
                mainTitle: "本机凭证簿",
                mainSeal: "独立可验"
            )
            ZCBody {
                distributionCard

                ZCSectionTitle(text: "待复验")
                waitCard
                    .padding(.bottom, 4)

                ZCSectionTitle(text: "已复验")
                verifiedCard
                    .padding(.bottom, 4)

                ZCBanner(kind: .info, title: "验证在本地完成",
                         body_: "证明文件与结算明细由网关拉取，复验在 wallet-core（wasm）本地执行；不依赖服务端「已验证」结论。")

                Text("阶梯是凭证状态（锚定在 note 上）；回执的 signed → seen → included 是投递状态。两者刻意用不同笔触。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.bottom, 10)

                ZCButton("打开 Proof Portal", style: .secondary, icon: .search) {
                    model.go(.zcPortal)
                }
            }
            ZCTabsBar()
        } footer: {}
    }

    /// 凭证分布卡（rail + 两行账）。
    private var distributionCard: some View {
        let ladder = model.realLadder()
        let finalized = model.realNotes.filter { $0.proof == .finalized }.count
        let soft = model.realNotes.filter { $0.proof == .soft }.count
        return ZCCard(title: "凭证分布", more: "阶梯") {
            ZCRail(steps: ladder.steps,
                   capLeft: "阶梯锚定在 note 上：pending → soft → proven → finalized")
            ZCLedgerRow("\(finalized) 份已达 finalized", "可提现")
            if soft > 0 {
                ZCLedgerRow {
                    Text("\(soft) 份停在 soft")
                } value: {
                    ZCChip("未达 REAL 门槛", tone: .amb, xs: true)
                }
            }
        }
        .padding(.bottom, 4)
    }

    /// 待复验列表（未 included 的回执）。
    private var waitCard: some View {
        let buckets = model.receiptBuckets
        let waiting = Array(buckets.pend.prefix(5))
        return ZCCard {
            if waiting.isEmpty {
                ZCEmptyBox(text: "无待复验项：所有回执都已登记为 included")
            } else {
                ForEach(waiting) { r in
                    ZCMenuRow(icon: r.pastDeadline ? .bolt : .receipt,
                              iconTint: r.pastDeadline ? model.c.amb : nil,
                              iconTone: r.pastDeadline ? .amb : .neutral,
                              title: "\(r.tableId.map { "\($0) 桌" } ?? "") · \(r.kindLabel)".trimmedSlash,
                              sub: r.pastDeadline
                                ? "\(shortAddr(r.digest, 8, 2)) · 可 ForceInclude"
                                : "\(shortAddr(r.digest, 8, 2)) · \(r.status.rawValue) 未 included",
                              action: { model.go(.zcPortal) })
                }
            }
        }
    }

    /// 已复验明细。
    private var verifiedCard: some View {
        let log = model.proofLog
        return ZCCard {
            if log.isEmpty {
                ZCEmptyBox(text: "本设备还没有复验记录：在 Proof Portal 输入 hand binding 验证一手牌")
            } else {
                ForEach(Array(log.prefix(6).enumerated()), id: \.element.id) { _, e in
                    ZCLedgerRow {
                        Text("8♠ 桌 #127")
                    } value: {
                        HStack(spacing: 4) {
                            Text("verified · ")
                            ZCChip("\(e.elapsedMS)ms", tone: .felt, xs: true)
                        }
                    }
                    ZCLedgerRow("校验耗时", String(format: "%.2fs（本地 stwo）", Double(e.elapsedMS) / 1000), dim: true)
                    ZCLedgerRow {
                        Text("payout_root")
                            .font(.system(size: 11, design: .monospaced))
                    } value: {
                        Text("0x8c3f…d210")
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
            }
        }
    }
}

// MARK: - 19 设置 · 能力矩阵

struct SettingsScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var showTestnet = true

    var body: some View {
        ScreenScaffold {
            ZCSubHeader(title: "设置")
            ZCBody {
                ZCSectionTitle(text: "通用")
                ZCCard {
                    ZCMenuRow(icon: .clock, title: "自动锁定",
                              sub: "无操作 15 分钟，或后台页面被系统回收（即 fail-closed）",
                              right: .chip("15 min", .neutral),
                              action: { model.showToast("自动锁定 15 分钟：由常量 AUTO_LOCK_MS 决定，本版本不提供改写") })
                    HStack(spacing: 10) {
                        ZCIcon(name: .book, size: 12)
                            .foregroundColor(model.c.ink2)
                            .frame(width: 24, height: 24)
                            .background(model.c.cd2)
                            .cornerRadius(ZCMetrics.chipCorner)
                            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(model.c.rl2, lineWidth: 1))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("显示测试网")
                                .font(.ui(12.5, .semibold))
                                .foregroundColor(model.c.ink)
                            Text("关闭后隐藏 devnet 资产")
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(model.c.ink3)
                        }
                        Spacer(minLength: 6)
                        ZCSwitch(on: $showTestnet)
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
                    ZCMenuRow(icon: .wallet, title: "货币计价",
                              sub: "USD（仅展示，非托管承诺）",
                              right: .chip("USD", .neutral),
                              action: { model.showToast("演示行情：NATIVE $1.012 / ETH $3,360 · 真实价格源未接入") })
                    ZCMenuRow(icon: .eye, title: "外观底面",
                              sub: "纸白账簿 / 夜场账簿（同一套 token 的两种底色）",
                              right: .chip(model.ground.label, .neutral),
                              action: {
                                  model.ground = model.ground.next
                                  model.persistPrefs()
                              })
                }
                .padding(.bottom, 4)

                ZCSectionTitle(text: "安全与备份")
                ZCCard {
                    ZCMenuRow(icon: .ul, title: "备份导出（.zcbk）",
                              sub: "仅 ZChain 层 REAL/PLAY 双库 · 备份口令独立",
                              action: { model.showToast("演示态：ZCBK v1 导出（Argon2id + ChaCha20-Poly1305 加密）") })
                    ZCMenuRow(icon: .dl, title: "从备份恢复",
                              sub: "Argon2id 本地解密",
                              action: { model.go(.importScreen) })
                    ZCMenuRow(icon: .key, title: "授权簿 / 会话密钥",
                              sub: "按 origin 撤销 dapp 授权",
                              action: { model.go(.zcSessions) })
                    ZCMenuRow(icon: .file, title: "能力矩阵",
                              sub: "各层能力与红线的如实说明",
                              action: { withAnimation(ZCAnim.std) { model.overlay = .init(kind: .capabilityMatrix) } })
                }
                .padding(.bottom, 4)

                ZCSectionTitle(text: "关于")
                ZCCard {
                    HStack(spacing: 10) {
                        ZCIcon(name: .info, size: 12)
                            .foregroundColor(model.c.ink2)
                            .frame(width: 24, height: 24)
                            .background(model.c.cd2)
                            .cornerRadius(ZCMetrics.chipCorner)
                            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(model.c.rl2, lineWidth: 1))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("版本")
                                .font(.ui(12.5, .semibold))
                                .foregroundColor(model.c.ink)
                            Text("iOS 原生 · DevNet 形态 · 对齐 Extension 0.6.1")
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(model.c.ink3)
                        }
                        Spacer(minLength: 6)
                        ZCChip("0.6.1", tone: .neutral, xs: true)
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
                    ZCMenuRow(icon: .ext, title: "文档与源码",
                              sub: "docs / website",
                              action: { model.showToast("见仓库 README：设计出处与边界说明") })
                }
                .padding(.bottom, 4)

                ZCBanner(kind: .bad, title: "未通过第三方审计",
                         body_: "「可验证」指密码学与结算证明可被独立复核，不等于已审计；本界面不出现任何审计徽章。")

                ZCFoot(text: "ZChain Wallet · 桌上飞快，结算可证\nFast at the table. Verifiable at settlement.\nPlay / DevNet / v1.3")
            }
        } footer: {}
    }
}
