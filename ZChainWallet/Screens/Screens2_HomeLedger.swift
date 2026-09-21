import SwiftUI

// ============================================================================
// Screens2_HomeLedger — 05 三链总账（home）/ 06-08 账簿 · 三链（acct）
// ============================================================================

// MARK: - 总额块（.tot：账簿封面，带账格纸纹）

struct ZCTotBlock<Amount: View>: View {
    @EnvironmentObject var model: WalletModel
    let label: String
    var trailing: AnyView? = nil
    var sub: AnyView? = nil
    @ViewBuilder var amount: () -> Amount

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 9.5, design: .monospaced))
                    .kerning(0.15 * 9.5)
                    .textCase(.uppercase)
                    .foregroundColor(model.c.ink3)
                Spacer(minLength: 4)
                trailing
            }
            amount()
                .font(.system(size: 31, weight: .semibold, design: .monospaced))
                .kerning(-0.6)
                .foregroundColor(model.c.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 5)
            if let sub {
                sub.padding(.top, 9)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(model.c.cd)
        .cornerRadius(ZCMetrics.corner)
        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
        .background(RuledPaperPattern().padding(1).cornerRadius(ZCMetrics.corner))
        .padding(.bottom, 14)
    }
}

// MARK: - 05 三链总账

struct HomeScreen: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        ScreenScaffold {
            ZCDocHeader(
                kind: "General Ledger",
                netText: "zchain-devnet-1",
                netAction: { withAnimation(ZCAnim.std) { model.overlay = .init(kind: .networkPicker) } },
                addrText: "三层统一账户 · 已解锁 \(model.unlockCount.unlocked) / \(model.unlockCount.held)",
                lockAction: { model.lockAll(); model.go(.lock) }
            )
            ZCBody {
                hero
                ZCSectionTitle(text: "账户层")
                ZCCard(tight: true, rowsStyle: true) {
                    layerRow(chain: .zc, token: .spade, tokenTone: .felt, name: "ZChain 隐私层",
                             unlocked: model.layer(.zc).unlocked,
                             sub1: "PLAY \(model.amt(fmtDisplay(NSDecimalNumber(decimal: model.playTotal()).stringValue, kind: "play"))) · NATIVE \(model.amt(fmtDisplay(NSDecimalNumber(decimal: model.realTotal()).stringValue, kind: "native")))",
                             fiat: model.amt(model.fiat(model.realTotal(), price: model.priceNative)),
                             addr: shortAddr(model.layer(.zc).address, 10, 4))
                    layerRow(chain: .evm, token: .ether, tokenTone: .neutral, name: "EVM 多链",
                             unlocked: model.layer(.evm).unlocked,
                             sub1: "ETH \(model.amt(fmtDisplay(model.evmInfo?.balanceHuman ?? "—", kind: "eth"))) · Ethereum",
                             fiat: model.amt(model.fiat(Decimal(string: model.evmInfo?.balanceHuman ?? "0") ?? 0, price: model.priceETH)),
                             addr: shortAddr(model.layer(.evm).address, 6, 4))
                    layerRow(chain: .stk, token: .layers, tokenTone: .neutral, name: "Starknet",
                             unlocked: model.layer(.stk).unlocked,
                             sub1: "ETH \(model.amt(fmtDisplay(model.stkInfo?.balanceHuman ?? "1.2034", kind: "eth"))) · SN DevNet",
                             fiat: model.amt(model.fiat(Decimal(string: "1.2034") ?? 0, price: model.priceETH)),
                             addr: shortAddr(model.layer(.stk).address, 6, 4))
                }
                weakestCard
                todoCard
                ZCButton("全部锁定", style: .secondary, icon: .lock) {
                    model.lockAll()
                    model.go(.lock)
                }
                .padding(.top, 2)
                ZCFoot(text: "ZChain Wallet · 设计稿 v0.2 / Extension 0.6.1 · DevNet\nPlay / DevNet / v1.3")
            }
            ZCTabsBar()
        } footer: {}
    }

    /// 三链总资产 hero（≈$22,288.63；REAL 托管 chip；PLAY 不计价说明）。
    private var hero: some View {
        let real = model.realTotal()
        let evm = Decimal(string: model.evmInfo?.balanceHuman ?? "0") ?? 0
        let stk = Decimal(string: "1.2034") ?? 0
        let total = real * model.priceNative + (evm + stk) * model.priceETH
        return ZCTotBlock(label: "三链总资产",
                          trailing: AnyView(
                            ZCIcon(name: model.hideAmount ? .eyeOff : .eye, size: 15)
                                .asButton {
                                    model.hideAmount.toggle()
                                    model.persistPrefs()
                                }
                          ),
                          sub: AnyView(
                            HStack(spacing: 8) {
                                ZCChip("REAL 托管 \(model.amt(model.fiat(real, price: model.priceNative)))", tone: .real)
                                Text("PLAY 为测试筹码，不计价")
                                    .font(.ui(10.5))
                                    .foregroundColor(model.c.ink2)
                            }
                          )) {
            Text("≈ " + model.amt(model.fiat(total, price: 1)))
        }
    }

    private func layerRow(chain: Chain, token: ZCIconName, tokenTone: ZCChipTone, name: String,
                          unlocked: Bool, sub1: String, fiat: String, addr: String) -> some View {
        Button {
            model.go(.acct, chain: chain)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    ZCIcon(name: token, size: 12)
                        .foregroundColor(tokenTone == .felt ? model.c.felt : model.c.ink2)
                }
                .frame(width: 26, height: 26)
                .background(tokenTone == .felt ? model.c.feltW : model.c.cd2)
                .cornerRadius(ZCMetrics.chipCorner)
                .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner)
                    .stroke(tokenTone == .felt ? model.c.feltRl : model.c.rl2, lineWidth: 1))

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(name)
                            .font(.ui(12.5, .semibold))
                            .foregroundColor(model.c.ink)
                        ZCChip(unlocked ? "已解锁" : "已锁定", tone: unlocked ? .felt : .amb, xs: true)
                    }
                    Text(sub1)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(model.c.ink3)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(fiat)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(model.c.ink)
                    Text(addr)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(model.c.ink3)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
    }

    /// 最弱凭证卡（rail + 说明 + 查看）。
    private var weakestCard: some View {
        let ladder = model.realLadder()
        return ZCCard(title: "最弱凭证") {
            ZCRail(
                steps: ladder.steps,
                capLeft: ladder.total > 0 ? "\(ladder.total) 张 REAL note，短板 " : "暂无 REAL note（0.x 不开放入金 / 铸造）",
                capLeftBold: ladder.total > 0 ? (ladder.weakest?.rawValue ?? "") : nil,
                capLeftBoldColor: ladder.weakest == .finalized ? model.c.felt : model.c.amb,
                capRightButton: ("查看", { model.go(.proofs) })
            )
        }
        .padding(.bottom, 12)
    }

    /// 待办卡。
    private var todoCard: some View {
        let pending = model.pendingRequest
        return ZCCard(title: "待办", more: pending != nil ? "1 项" : nil, moreAction: { model.go(.zcConfirm) }) {
            if let p = pending {
                ZCMenuRow(icon: .pen,
                          iconTint: model.c.amb, iconTone: .amb,
                          title: "开桌签名请求 · 8♠ 桌",
                          sub: "\(p.origin) · \(remainText(p.expiresAt.timeIntervalSinceNow)) 后过期",
                          action: { model.go(.zcConfirm) })
            } else {
                ZCEmptyBox(text: "无待确认请求")
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - 06-08 账簿（一份结构 × 三链数据面）

struct LedgerScreen: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        ScreenScaffold {
            ZCDocHeader(
                kind: "Ledger · \(model.chain.kindWord)",
                netText: netText,
                netAction: { withAnimation(ZCAnim.std) { model.overlay = .init(kind: .networkPicker) } },
                addrText: shortAddr(model.layer(model.chain).address ?? "未创建", 12, 4),
                showCopy: model.layer(model.chain).address != nil,
                lockAction: { model.lockCurrent(); model.go(.lock) }
            )
            ZCBody {
                ZCChainSwitcher(counts: [2, 1, 1])
                switch model.chain {
                case .zc: ZCPane()
                case .evm: EvmPane()
                case .stk: StkPane()
                }
            }
            ZCTabsBar()
        } footer: {}
    }

    private var netText: String {
        switch model.chain {
        case .zc: return "zchain-devnet-1"
        case .evm: return "Ethereum · chainId 1"
        case .stk: return "SN DevNet · ZCDN"
        }
    }
}

// MARK: - ZChain 数据面

struct ZCPane: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 分库（跨域不轧差）
            HStack(spacing: 1) {
                splitCol(chip: ("GAME", .play), label: "可用筹码",
                         value: model.amt(fmtDisplay(NSDecimalNumber(decimal: model.playTotal()).stringValue, kind: "play")),
                         unit: "PLAY", valueColor: model.c.ink)
                splitCol(chip: ("REAL", .real), label: "托管映射",
                         value: model.amt(fmtDisplay(NSDecimalNumber(decimal: model.realTotal()).stringValue, kind: "native")),
                         unit: "NATIVE", valueColor: model.c.real)
            }
            .background(model.c.rl)
            .cornerRadius(ZCMetrics.corner)
            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
            .padding(.bottom, 14)

            ZCBanner(kind: .real, title: "托管映射资产",
                     body_: "REAL 域提现通道未开放；GAME 域筹码不上主网。")

            // 快捷动作条（收款 play / 提现 real）
            HStack(spacing: 1) {
                actCell(icon: .qr, label: "收款", tint: model.c.play, action: { model.overlay = .init(kind: .receive(chain: .zc)) })
                actCell(icon: .send, label: "转账", tint: model.c.ink2, action: { model.go(.zcSend) })
                actCell(icon: .out, label: "提现", tint: model.c.real, action: { model.go(.zcWithdraw) })
                actCell(icon: .search, label: "Portal", tint: model.c.ink2, action: { model.go(.zcPortal) })
            }
            .background(model.c.rl)
            .cornerRadius(ZCMetrics.corner)
            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
            .padding(.bottom, 14)

            // 资产卡
            ZCCard(title: "资产", more: "回执", moreAction: { model.go(.zcReceipts) }) {
                ZCAssetRow(token: "P", tokenTone: .play, name: "PLAY", nameChip: ("GAME", .play),
                           sub: "可用 \(model.amt(fmtDisplay(NSDecimalNumber(decimal: model.playTotal()).stringValue, kind: "play"))) · 桌上锁定 \(fmtDisplay(NSDecimalNumber(decimal: model.playLocked()).stringValue, kind: "play"))",
                           amount: model.amt(fmtDisplay(NSDecimalNumber(decimal: model.playTotal()).stringValue, kind: "play")))
                ZCAssetRow(token: "N", tokenTone: .real, name: "NATIVE", nameChip: ("REAL", .real),
                           sub: "托管映射 · 提现未开放",
                           amount: model.amt(fmtDisplay(NSDecimalNumber(decimal: model.realTotal()).stringValue, kind: "native")))
                ZCAssetRow(token: "U", name: "USDT / USDC", sub: "未接入", amount: "—", dim: true)
                    .opacity(0.55)
            }
            .padding(.bottom, 12)

            // 最新动态（最近 2 条回执）
            ZCCard(title: "最新动态", more: "查看全部", moreAction: { model.go(.zcReceipts) }) {
                let recent = Array(model.receipts.prefix(2))
                if recent.isEmpty {
                    ZCEmptyBox(text: "暂无回执（签名成功后登记）")
                } else {
                    ForEach(recent) { r in
                        receiptTxRow(r)
                    }
                }
            }
            .padding(.bottom, 12)

            // 会话密钥摘要（治理中的活跃绑定）
            sessionCard

            ZCFoot(text: "链=筛选器：三链共用同一账簿结构，只换数据面")
        }
    }

    /// 会话密钥摘要卡（活跃绑定 + meter）。
    private var sessionCard: some View {
        let gov = model.sessions.first { $0.status == .active } ?? model.sessions.first
        return ZCCard(title: "会话密钥 · SNIP-12", more: "管理", moreAction: { model.go(.zcSessions) }) {
            if let gov {
                ZCLedgerRow("origin", gov.origin)
                ZCLedgerRow("单笔 / 日累计", "≤\(gov.perTxLimit ?? "不限") · \(fmtAmount(gov.dailyUsed))/\(fmtAmount(gov.perDayLimit ?? "不限"))")
                if let p = gov.usagePercent {
                    ZCMeter(percent: p, warn: gov.status == .exhausted)
                        .padding(.top, 2)
                        .padding(.bottom, 6)
                }
                ZCLedgerRow("状态", gov.statusLabel)
            } else {
                ZCEmptyBox(text: "暂无授权：由 dapp 连接时按需建立")
            }
        }
        .padding(.bottom, 12)
    }

    private func splitCol(chip: (String, ZCChipTone), label: String, value: String, unit: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                ZCChip(chip.0, tone: chip.1, xs: true)
                Text(label)
                    .font(.system(size: 9, design: .monospaced))
                    .kerning(0.15 * 9)
                    .textCase(.uppercase)
                    .foregroundColor(model.c.ink3)
            }
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .kerning(-0.3)
                    .foregroundColor(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(unit)
                    .font(.system(size: 9.5, design: .monospaced))
                    .kerning(0.14 * 9.5)
                    .textCase(.uppercase)
                    .foregroundColor(model.c.ink3)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(model.c.cd)
    }

    private func actCell(icon: ZCIconName, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: 4) {
                ZCIcon(name: icon, size: 17)
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .kerning(0.05 * 10)
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(model.c.cd)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func receiptTxRow(_ r: ReceiptItem) -> some View {
        let chip = model.receiptChip(r)
        let icon: ZCIconName = r.status == .included ? .check : (r.status == .seen ? .receipt : .clock)
        let tone: ZCTxRow.IconTone = r.status == .included ? .ok : (r.status == .seen ? .blue : .warn)
        let amount: String?
        let amountTone: ZCAssetRow.AmountTone
        if let total = r.amountTotal {
            let isNeg = r.kind == "transfer" || r.kind == "buy_in"
            amount = (isNeg ? "-" : "+") + fmtDisplay(total, kind: "play")
            amountTone = isNeg ? .neg : .pos
        } else {
            amount = nil
            amountTone = .normal
        }
        return ZCTxRow(icon: icon, iconTone: tone,
                       name: "\(r.kindLabel) · \(r.tableId.map { "\($0) 桌" } ?? "")".trimmedSlash,
                       sub: "\(shortAddr(r.digest, 8, 2)) · \(relTime(r.signedAtMs))",
                       amount: amount, amountTone: amountTone,
                       chip: (chip.0, chip.1))
    }
}

extension String {
    /// "结算 · 128 桌" 之类的尾缀清理（" · " 结尾空段）。
    var trimmedSlash: String {
        self.hasSuffix(" · ") ? String(dropLast(3)) : self
    }
}

// MARK: - EVM 数据面

struct EvmPane: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 总余额
            ZCTotBlock(label: "总余额 · ETH",
                       trailing: AnyView(
                         HStack(spacing: 8) {
                             Text("≈ " + model.fiat(Decimal(string: model.evmInfo?.balanceHuman ?? "0") ?? 0, price: model.priceETH))
                                 .font(.system(size: 10.5, design: .monospaced))
                                 .foregroundColor(model.c.ink2)
                             ZCIcon(name: .qr, size: 15).asButton { model.overlay = .init(kind: .receive(chain: .evm)) }
                             ZCIcon(name: .refresh, size: 15).asButton { model.refreshChain(.evm) }
                         }
                       ),
                       sub: AnyView(
                         HStack(spacing: 4) {
                             Text(shortAddr(model.layer(.evm).address ?? "", 10, 4))
                                 .font(.system(size: 10, design: .monospaced))
                                 .foregroundColor(model.c.ink2)
                             ZCIcon(name: .copy, size: 11)
                                 .asButton { model.copy(model.layer(.evm).address ?? "", kind: .address) }
                         }
                       )) {
                (Text(model.amt(fmtDisplay(model.evmInfo?.balanceHuman ?? "—", kind: "eth")))
                    .font(.system(size: 31, weight: .semibold, design: .monospaced))
                    .kerning(-0.6)
                    .foregroundColor(model.c.ink)
                + Text(" ETH")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .kerning(0.06 * 12)
                    .foregroundColor(model.c.ink3))
            }

            // 快捷条
            HStack(spacing: 1) {
                ZCPane.actCellStatic(icon: .send, label: "发送") { model.go(.send, chain: .evm) }
                ZCPane.actCellStatic(icon: .qr, label: "收款") { model.overlay = .init(kind: .receive(chain: .evm)) }
                ZCPane.actCellStatic(icon: .receipt, label: "历史") { model.go(.history, chain: .evm) }
                ZCPane.actCellStatic(icon: .file, label: "合约") { model.go(.contract, chain: .evm) }
            }
            .background(model.c.rl)
            .cornerRadius(ZCMetrics.corner)
            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
            .padding(.bottom, 14)

            // 网络卡
            ZCCard(title: "网络", more: "切换", moreAction: { model.overlay = .init(kind: .networkPicker) }) {
                ZCLedgerRow {
                    Text("chainId")
                } value: {
                    HStack(spacing: 5) {
                        Text("1")
                        ZCChip("校验通过", tone: .felt, xs: true)
                    }
                }
                ZCLedgerRow {
                    Text("gas")
                } value: {
                    HStack(spacing: 5) {
                        Text("\(model.evmInfo?.gasPriceGwei ?? "—") gwei")
                        ZCChip("偏低", tone: .neutral, xs: true)
                    }
                }
                ZCLedgerRow("nonce", model.evmInfo?.nonce ?? "—")
            }
            .padding(.bottom, 12)

            // 资产卡
            ZCCard(title: "资产") {
                ZCAssetRow(token: "Ξ", name: "ETH", sub: "原生币",
                           amount: model.amt(fmtDisplay(model.evmInfo?.balanceHuman ?? "—", kind: "eth")))
                ZCAssetRow(token: "U", name: "USDC", nameChip: ("只读", .neutral),
                           sub: "erc-20 · eth_call 读取", amount: "320.00")
            }
            .padding(.bottom, 12)

            // 最新动态
            ZCCard(title: "最新动态", more: "查看全部", moreAction: { model.go(.history, chain: .evm) }) {
                let txs = Array(model.evmTxs.prefix(2))
                if txs.isEmpty {
                    ZCEmptyBox(text: "暂无交易记录")
                } else {
                    ForEach(txs) { t in chainTxRow(t) }
                }
            }
            .padding(.bottom, 12)

            // 账户管理入口
            ZCCard(title: "账户管理", more: "进入", moreAction: { model.go(.manage, chain: .evm) }) {
                ZCLedgerRow("私钥 · 口令 · RPC", "危险区需二次确认", dim: true)
            }
            .padding(.bottom, 12)
        }
    }

    func chainTxRow(_ t: ChainTx) -> some View {
        let chip = t.statusChip
        let isIn = t.direction == "in"
        let icon: ZCIconName = t.kind == "contract" ? .file : (isIn ? .recv : .send)
        let tone: ZCTxRow.IconTone = chip.1 == .felt ? .ok : chip.1 == .amb ? .warn : chip.1 == .bad ? .bad : .blue
        return ZCTxRow(icon: icon, iconTone: tone,
                       name: "\(t.kind == "contract" ? (t.methodLabel ?? "合约调用") : (isIn ? "接收" : "发送")) · \(fmtAmount(t.valueHuman))",
                       sub: "\(shortAddr(t.hash, 8, 2)) · \(relTime(t.createdAt))",
                       amount: fmtSigned(t.valueHuman, positive: isIn, negative: !isIn),
                       amountTone: isIn ? .pos : .neg,
                       chip: (chip.0, chip.1))
    }
}

// MARK: - Starknet 数据面

struct StkPane: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZCBanner(kind: .amb, title: "本层已锁定",
                     body_: "解锁后才能发起 invoke；当前余额为链上只读数据。")

            ZCTotBlock(label: "总余额 · ETH",
                       trailing: AnyView(
                         HStack(spacing: 8) {
                             Text("≈ " + model.fiat(Decimal(string: model.stkInfo?.balanceHuman ?? "1.2034") ?? 0, price: model.priceETH))
                                 .font(.system(size: 10.5, design: .monospaced))
                                 .foregroundColor(model.c.ink2)
                             ZCIcon(name: .qr, size: 15).asButton { model.overlay = .init(kind: .receive(chain: .stk)) }
                             ZCIcon(name: .refresh, size: 15).asButton { model.refreshChain(.stk) }
                         }
                       ),
                       sub: AnyView(
                         HStack(spacing: 4) {
                             Text(shortAddr(model.layer(.stk).address ?? "", 10, 4))
                                 .font(.system(size: 10, design: .monospaced))
                                 .foregroundColor(model.c.ink2)
                             ZCIcon(name: .copy, size: 11)
                                 .asButton { model.copy(model.layer(.stk).address ?? "", kind: .address) }
                         }
                       )) {
                (Text(model.amt(fmtDisplay(model.stkInfo?.balanceHuman ?? "1.2034", kind: "eth")))
                    .font(.system(size: 31, weight: .semibold, design: .monospaced))
                    .kerning(-0.6)
                    .foregroundColor(model.c.ink)
                + Text(" ETH")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .kerning(0.06 * 12)
                    .foregroundColor(model.c.ink3))
            }

            HStack(spacing: 1) {
                ZCPane.actCellStatic(icon: .send, label: "发送") { model.go(.send, chain: .stk) }
                ZCPane.actCellStatic(icon: .qr, label: "收款") { model.overlay = .init(kind: .receive(chain: .stk)) }
                ZCPane.actCellStatic(icon: .flask, label: "水龙头") { model.showToast("SN DevNet 水龙头：注册账户 + 领取测试币（演示态）") }
                ZCPane.actCellStatic(icon: .receipt, label: "历史") { model.go(.history, chain: .stk) }
            }
            .background(model.c.rl)
            .cornerRadius(ZCMetrics.corner)
            .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
            .padding(.bottom, 14)

            ZCCard(title: "网络", more: "切换", moreAction: { model.overlay = .init(kind: .networkPicker) }) {
                ZCLedgerRow {
                    Text("chainId")
                } value: {
                    HStack(spacing: 5) {
                        Text("ZCDN")
                        ZCChip("校验通过", tone: .felt, xs: true)
                    }
                }
                ZCLedgerRow("nonce", model.stkInfo?.nonce ?? "7")
                ZCLedgerRow("UDC 地址", "0x41a7…8e02（公式推导）")
            }
            .padding(.bottom, 12)

            ZCCard(title: "资产") {
                ZCAssetRow(token: "Ξ", name: "ETH", sub: "ERC-20 · u256 形状",
                           amount: model.amt(fmtDisplay(model.stkInfo?.balanceHuman ?? "1.2034", kind: "eth")))
            }
            .padding(.bottom, 12)

            ZCCard(title: "最新动态") {
                let txs = Array(model.stkTxs.prefix(2))
                if txs.isEmpty {
                    ZCEmptyBox(text: "暂无交易记录")
                } else {
                    ForEach(txs) { t in
                        let chip = t.statusChip
                        let isIn = t.direction == "in"
                        return ZCTxRow(icon: isIn ? .recv : .send,
                                       iconTone: chip.1 == .felt ? .ok : .blue,
                                       name: t.methodLabel ?? (isIn ? "接收" : "发送"),
                                       sub: "\(shortAddr(t.hash, 8, 2)) · \(relTime(t.createdAt))",
                                       amount: fmtSigned(t.valueHuman, positive: isIn, negative: !isIn),
                                       amountTone: isIn ? .pos : .neg,
                                       chip: (isIn ? "dev" : chip.0, isIn ? .play : chip.1))
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }
}

// MARK: - 静态快捷格（供 EVM/STK pane 复用）

extension ZCPane {
    static func actCellStatic(icon: ZCIconName, label: String, action: @escaping () -> Void) -> some View {
        ZCQuickCell(icon: icon, label: label, action: action)
    }
}

/// 快捷动作格（acts 里的按钮；独立类型避免依赖 pane 实例）。
struct ZCQuickCell: View {
    @EnvironmentObject var model: WalletModel
    let icon: ZCIconName
    let label: String
    var tint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 4) {
                ZCIcon(name: icon, size: 17)
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .kerning(0.05 * 10)
            }
            .foregroundColor(tint ?? model.c.ink2)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(model.c.cd)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
