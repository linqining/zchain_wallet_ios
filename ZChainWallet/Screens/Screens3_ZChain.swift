import SwiftUI

// ============================================================================
// Screens3_ZChain — 09 转账 · 贪心选币 / 10 REAL 提现 fail-closed
//                   11 dapp 签名请求 / 12 会话密钥 / 13 Proof Portal / 14 回执
// ============================================================================

// MARK: - 09 转账 · 贪心选币

struct ZCSendScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var amount = ""
    @State private var owner = ""
    @State private var err = ""

    var body: some View {
        ScreenScaffold {
            ZCSubHeader(title: "转账") {
                AnyView(ZCChip("GAME", tone: .play, xs: true))
            }
            ZCBody {
                ZCField(label: "金额",
                        aux: "可用 \(fmtAmount(NSDecimalNumber(decimal: model.playTotal()).stringValue)) · ",
                        auxButton: ("MAX", { amount = NSDecimalNumber(decimal: model.playTotal()).stringValue })) {
                    ZCAmountInput(text: $amount, unit: "PLAY", unitTone: .play)
                }
                ZCField(label: "收款 owner") {
                    ZCInput(placeholder: "0x… / zc1q…", text: $owner, mono: true, smallFont: true)
                }
                ZCFiatNote(text: "测试筹码 · 不计价 · 不可与 REAL 域兑换")
                    .padding(.bottom, 4)

                if let p = model.transferPreview {
                    selectionCard(p)
                    feeCard(p)
                    railCard(p)
                } else {
                    ZCCard(title: "贪心选币") {
                        ZCEmptyBox(text: "填入金额与收款 owner 后生成选币预览")
                    }
                    .padding(.bottom, 12)
                }

                ZCButton("生成预览", style: .secondary) {
                    err = ""
                    model.transferPreview = nil
                    guard let amt = Decimal(string: amount.trimmingCharacters(in: .whitespaces)), amt > 0 else {
                        err = "金额不合法"
                        return
                    }
                    guard !owner.trimmingCharacters(in: .whitespaces).isEmpty else {
                        err = "收款地址格式不合法"
                        return
                    }
                    if let p = model.makeTransferPreview(amountRaw: amount, owner: owner) {
                        model.transferPreview = p
                    } else {
                        err = "可用余额不足（note 全额消费，不支持部分花费）"
                    }
                }
                .padding(.bottom, 9)

                ZCButton("确认转账", large: true, disabled: model.transferPreview?.canSubmit != true) {
                    model.confirmTransfer()
                    amount = ""
                    owner = ""
                }

                ZCResultLine(text: err)

                Text("note 全额消费：不足额时自动多输出一条找零回本账户。提交后可在「证明 → 回执」跟踪状态。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.top, 10)
            }
        } footer: {}
    }

    /// 贪心选币卡（消耗 note + 找零）。
    private func selectionCard(_ p: TransferPreview) -> some View {
        ZCCard(title: "贪心选币 · 消耗 \(p.inputs.count) 张 note") {
            ForEach(Array(p.inputs.enumerated()), id: \.offset) { _, n in
                ZCLedgerRow {
                    Text(shortAddr(n.commitment, 6, 4))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(model.c.ink2)
                } value: {
                    HStack(spacing: 4) {
                        Text(n.amount)
                        ZCChip(n.proof.rawValue, tone: proofChipTone(n.proof.rawValue), xs: true)
                    }
                }
            }
            ZCLedgerRow("找零 note", p.change == 0 ? "0.00（本次无找零）" : "\(fmtAmount(NSDecimalNumber(decimal: p.change).stringValue))（回本账户）",
                        dim: p.change == 0)
            ZCLedgerRow("守恒核对", "Σin \(fmtAmount(NSDecimalNumber(decimal: p.totalIn).stringValue)) = Σout \(fmtAmount(NSDecimalNumber(decimal: p.amount + p.change).stringValue))")
        }
        .padding(.bottom, 12)
    }

    private func feeCard(_ p: TransferPreview) -> some View {
        ZCCard {
            ZCLedgerRow {
                Text("网络费")
            } value: {
                HStack(spacing: 4) {
                    Text("网关代付 ")
                    ZCChip("免费", tone: .felt, xs: true)
                }
            }
            ZCLedgerRow("回执路径", "signed → seen → included", dim: true)
            ZCLedgerRow("凭证门槛", "\(p.worstProof.rawValue) → 要求 \(p.requiredProof.rawValue)", dim: !p.reached)
            ZCLedgerRow {
                Text("签名摘要")
                    .font(.system(size: 11, design: .monospaced))
            } value: {
                Text(shortAddr(p.digest, 12, 10))
                    .font(.system(size: 10.5, design: .monospaced))
            }
        }
        .padding(.bottom, 12)
    }

    private func railCard(_ p: TransferPreview) -> some View {
        let outcome = model.ladderOutcome(weakest: p.worstProof, required: p.requiredProof,
                                          canSubmit: p.canSubmit, spendable: p.inputs.count)
        return ZCCard {
            ZCRail(
                steps: model.ladderSteps(current: p.worstProof, outcome: outcome, required: p.requiredProof),
                capLeft: "支出 note 短板 ",
                capLeftBold: p.worstProof.rawValue,
                capLeftBoldColor: p.reached ? model.c.felt : model.c.bad,
                capRight: p.reached ? "· 满足 GAME 域要求" : "· 未达 \(p.requiredProof.rawValue)"
            )
        }
        .padding(.bottom, 12)
    }
}

// MARK: - 10 REAL 提现预览 · fail-closed

struct ZCWithdrawScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var amount = ""
    @State private var owner = ""
    @State private var err = ""

    var body: some View {
        ScreenScaffold {
            ZCSubHeader(title: "提现（预览）") {
                AnyView(ZCChip("REAL", tone: .real, xs: true))
            }
            ZCBody {
                ZCBanner(kind: .real, title: "托管警示",
                         body_: "REAL 域由运营方托管映射。以下为模拟预览，不会提交任何链上交易。")

                ZCField(label: "提现金额",
                        aux: "REAL 可用 \(fmtAmount(NSDecimalNumber(decimal: model.realTotal()).stringValue))") {
                    ZCAmountInput(text: $amount, unit: "NATIVE", unitTone: .real)
                }
                ZCField(label: "收款 owner（L1 地址）") {
                    ZCInput(placeholder: "0x…", text: $owner, mono: true, smallFont: true)
                }

                if let p = model.withdrawPreviewData(amount: amount, owner: owner) {
                    ZCCard(title: "贪心选币 · \(p.inputs.count) 张 note") {
                        ForEach(Array(p.inputs.enumerated()), id: \.offset) { _, n in
                            ZCLedgerRow {
                                Text(shortAddr(n.commitment, 6, 4))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(model.c.ink2)
                            } value: {
                                HStack(spacing: 4) {
                                    Text(n.amount)
                                    ZCChip(n.proof.rawValue, tone: proofChipTone(n.proof.rawValue), xs: true)
                                }
                            }
                        }
                        ZCLedgerRow("合计", fmtAmount(NSDecimalNumber(decimal: p.totalIn).stringValue))
                    }
                    .padding(.bottom, 12)

                    ZCCard(title: "finality 检查", more: "?") {
                        ZCRail(steps: model.withdrawSteps(p))
                        ZCLedgerRow("所需证明", "finalized")
                        ZCLedgerRow("最弱凭证", "\(p.worstProof.rawValue)（未达标）", dim: true)
                    }
                    .padding(.bottom, 12)

                    ZCCard(title: "暂不可提交 · 原因") {
                        ForEach(Array(p.reasons.enumerated()), id: \.offset) { _, r in
                            ZCReasonRow(text: r.0, qualifier: r.1, qualifierTone: r.2)
                        }
                        ZCReasonRow(text: "托管：real_is_custodial", real: true)
                    }
                    .padding(.bottom, 12)
                } else {
                    ZCCard(title: "贪心选币") {
                        ZCEmptyBox(text: "填入金额与 owner 后生成预览")
                    }
                    .padding(.bottom, 12)
                }

                ZCButton("生成预览", style: .secondary) {
                    err = ""
                    guard let amt = Decimal(string: amount.trimmingCharacters(in: .whitespaces)), amt > 0 else {
                        err = "金额不合法"
                        return
                    }
                    model.withdrawMakePreview(amount: amount, owner: owner)
                }
                .padding(.bottom, 9)

                ZCButton("提交提现", large: true, disabled: true)

                ZCResultLine(text: err)

                Text("fail-closed：原因消除前，提交入口保持禁用（虚线即「不可用」的专用笔触）。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.top, 10)
            }
        } footer: {}
    }
}

extension WalletModel {
    /// REAL 提现预览（fail-closed：canSubmit 恒 false）。
    func withdrawPreviewData(amount: String, owner: String) -> WithdrawPreview? {
        guard let amt = Decimal(string: amount.trimmingCharacters(in: .whitespaces)), amt > 0,
              let sel = greedySelect(amount: amt, notes: realNotes) else { return nil }
        let weakest = sel.inputs.map { $0.proof }.min { rank($0) < rank($1) }
        return WithdrawPreviewPreviewFactory.make(amount: amt, owner: owner, inputs: sel.inputs,
                                                  change: sel.change, totalIn: sel.totalIn, weakest: weakest)
    }

    func withdrawMakePreview(amount: String, owner: String) {
        withdrawPreview = withdrawPreviewData(amount: amount, owner: owner)
    }

    func withdrawSteps(_ p: WithdrawPreview) -> [ZCRail.RailStep] {
        ladderSteps(current: p.worstProof, outcome: .blocked, required: p.requiredProof)
    }
}

/// WithdrawPreview 的装配（canSubmit 恒 false 红线在此钉住）。
enum WithdrawPreviewPreviewFactory {
    static func make(amount: Decimal, owner: String, inputs: [Note], change: Decimal, totalIn: Decimal, weakest: ProofLevel?) -> WithdrawPreview {
        WithdrawPreviewFactory.build(amount: amount, owner: owner, inputs: inputs,
                                     change: change, totalIn: totalIn, weakest: weakest ?? .pending)
    }
}

/// 演示装配层：WithdrawPreview 全部为 let，这里集中构造。
enum WithdrawPreviewFactory {
    static func build(amount: Decimal, owner: String, inputs: [Note], change: Decimal, totalIn: Decimal, weakest: ProofLevel) -> WithdrawPreview {
        WithdrawPreview(amount: amount, owner: owner, inputs: inputs, change: change, totalIn: totalIn, worstProof: weakest)
    }
}

// MARK: - 11 dapp 签名请求

struct ZCConfirmScreen: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        ScreenScaffold {
            ZCSubHeader(title: "签名请求", closeIcon: true) {
                AnyView(
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        if let p = model.pendingRequest {
                            let left = p.expiresAt.timeIntervalSince(ctx.date)
                            ZCChip(remainText(left), tone: .amb, xs: true)
                        }
                    }
                )
            }
            ZCBody {
                if let p = model.pendingRequest {
                    // dapp 头
                    HStack(spacing: 9) {
                        ZStack {
                            ZCIcon(name: .spade, size: 12).foregroundColor(model.c.ink2)
                        }
                        .frame(width: 26, height: 26)
                        .background(model.c.pg2)
                        .cornerRadius(ZCMetrics.chipCorner)
                        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(model.c.rl2, lineWidth: 1))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(p.origin)
                                .font(.ui(12, .semibold))
                                .foregroundColor(model.c.ink)
                                .lineLimit(1)
                            Text(p.sessionPath ? "请求签名 · 会话密钥路径" : "请求签名")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(model.c.ink3)
                        }
                        Spacer(minLength: 4)
                        ZCChip("已授权 origin", tone: .felt, xs: true)
                    }
                    .padding(10)
                    .background(model.c.cd)
                    .cornerRadius(ZCMetrics.corner)
                    .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl, lineWidth: 1))
                    .padding(.bottom, 12)

                    // 确认块（cfm：开桌买入 -500.00）
                    VStack(spacing: 0) {
                        Text("开桌买入")
                            .font(.system(size: 9.5, design: .monospaced))
                            .kerning(0.15 * 9.5)
                            .textCase(.uppercase)
                            .foregroundColor(model.c.ink3)
                        Text("-" + fmtAmount(p.amount))
                            .font(.system(size: 28, weight: .semibold, design: .monospaced))
                            .kerning(-0.5)
                            .foregroundColor(model.c.ink)
                            .padding(.top, 4)
                        Text("PLAY · 8♠ 桌 · GAME 域 · 不动 REAL 资产")
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(model.c.ink2)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(model.c.cd)
                    .cornerRadius(ZCMetrics.corner)
                    .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.rl2, lineWidth: 1))
                    .background(RuledPaperPattern().padding(1).cornerRadius(ZCMetrics.corner))
                    .padding(.bottom, 12)

                    ZCCard(title: "请求内容") {
                        ZCLedgerRow("链", p.chainId)
                        ZCLedgerRow("桌 table_id", p.tableId)
                        ZCLedgerRow {
                            Text("资产")
                        } value: {
                            HStack(spacing: 4) {
                                Text(p.asset)
                                ZCChip("GAME", tone: .play)
                            }
                        }
                        ZCLedgerRow("rake", p.rake)
                        ZCLedgerRow {
                            Text("过期")
                        } value: {
                            HStack(spacing: 4) {
                                Text("120 秒")
                                ZCChip("倒计时中", tone: .amb, xs: true)
                            }
                        }
                    }
                    .padding(.bottom, 12)

                    ZCCard(title: "授权对象") {
                        ZCLedgerRow("收款 owner", p.owner)
                        ZCLedgerRow("hand_binding", p.handBinding)
                        ZCLedgerRow("request_id", p.requestId)
                        ZCLedgerRow("证明", "结算后可在 Portal 完整验证", dim: true)
                    }
                    .padding(.bottom, 12)

                    if p.sessionPath {
                        ZCBanner(kind: .ok, title: "将使用会话密钥签名",
                                 body_: "在单笔限额（≤ 1,000 PLAY）内，无需输入口令。")
                    }

                    HStack(spacing: 9) {
                        ZCButton("拒绝", style: .danger) { model.decidePending(false) }
                        ZCButton("批准签名") { model.decidePending(true) }
                    }
                    .padding(.top, 2)

                    ZCDisclosure(summary: "原始摘要（SNIP-12）") {
                        ZCRawBox(text: p.digest)
                    }
                } else {
                    ZCEmptyBox(text: "无待确认请求")
                        .padding(.bottom, 12)
                    ZCButton("返回账簿", style: .secondary) { model.go(.acct, chain: model.chain) }
                }
            }
        } footer: {}
    }
}

// MARK: - 12 会话密钥 · SNIP-12

struct ZCSessionsScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var seg = 0

    var body: some View {
        ScreenScaffold {
            ZCSubHeader(title: "会话密钥") {
                AnyView(ZCChip("SNIP-12", tone: .neutral, xs: true))
            }
            ZCBody {
                ZCSegmented(items: ["现有会话", "新建草稿"], selection: $seg)

                if seg == 0 {
                    ForEach(Array(model.sessions.enumerated()), id: \.element.id) { i, b in
                        sessionCard(b)
                            .padding(.bottom, 12)
                    }
                    if model.sessions.isEmpty {
                        ZCEmptyBox(text: "暂无会话密钥授权")
                            .padding(.bottom, 12)
                    }
                } else {
                    draftCard
                }

                Text("授权簿按 origin 记账；撤销只影响该 origin 的委托密钥，不动主密钥。delegated key 私钥只活在解锁会话，锁定即毁。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.top, 8)

                ZCBanner(kind: .info, title: "两个「会话」不是一回事",
                         body_: "本页管理的是 dapp 的 SNIP-12 委托授权（默认 1 天有效，按 origin 记账）；与 15 分钟无操作自动锁定的解锁会话彼此独立——锁定钱包不会撤销这里的授权，撤销授权也不会锁定钱包。")
                    .padding(.top, 4)
            }
        } footer: {}
    }

    private func sessionCard(_ b: SessionBinding) -> some View {
        ZCCard(emphasize: b.status == .active && !b.revoked) {
            HStack(spacing: 9) {
                ZStack {
                    ZCIcon(name: .key, size: 12)
                        .foregroundColor(b.status == .active && !b.revoked ? model.c.felt : model.c.amb)
                }
                .frame(width: 26, height: 26)
                .background(b.status == .active && !b.revoked ? model.c.feltW : model.c.ambW)
                .cornerRadius(ZCMetrics.chipCorner)
                .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner)
                    .stroke(b.status == .active && !b.revoked ? model.c.feltRl : model.c.ambRl, lineWidth: 1))
                VStack(alignment: .leading, spacing: 1) {
                    Text(b.origin)
                        .font(.ui(12.5, .semibold))
                        .foregroundColor(model.c.ink)
                        .lineLimit(1)
                    Text("delegated \(b.delegated)")
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(model.c.ink3)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                ZCChip(b.revoked ? "已撤销" : b.statusLabel, tone: b.revoked ? .bad : b.statusTone, xs: true)
            }
            .padding(.bottom, 9)

            ZCLedgerRow {
                Text("scope")
            } value: {
                HStack(spacing: 4) {
                    ForEach(b.scopes, id: \.self) { s in
                        ZCChip(s, tone: .neutral, xs: true)
                    }
                }
            }
            ZCLedgerRow("单笔限额", b.perTxLimit.map { "≤ \(fmtAmount($0)) PLAY" } ?? "不限")
            ZCLedgerRow("日累计", "\(fmtAmount(b.dailyUsed)) / \(fmtAmount(b.perDayLimit ?? "不限")) PLAY")
            if let p = b.usagePercent {
                ZCMeter(percent: p, warn: b.status == .exhausted)
                    .padding(.vertical, 7)
            }
            ZCLedgerRow("桌白名单", b.tables.map { $0.joined(separator: " · ") + "（\($0.count) 桌）" } ?? "不限桌")
            ZCLedgerRow("有效期", validityRemain(b.validUntil))
            ZCLedgerRow("登记来源", b.evidence, dim: true)

            if b.revoked {
                ZCButton("删除记录", style: .ghost, small: true) {
                    model.deleteSession(b)
                }
                .padding(.top, 11)
                .frame(maxWidth: .infinity)
                Text("已撤销为粘滞态：该 origin 的签名一律拒绝，删除记录后回到常规路径。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.top, 7)
            } else if b.status == .active || b.status == .exhausted {
                ZCButton("撤销授权", style: .danger, small: true) {
                    withAnimation(ZCAnim.std) { model.overlay = .init(kind: .revokeConfirm(b)) }
                }
                .padding(.top, 11)
                .frame(maxWidth: .infinity)
                Text("撤销为粘滞操作：立即生效，本会话永久失效")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.top, 7)
            } else {
                ZCButton("删除记录", style: .ghost, small: true) {
                    model.deleteSession(b)
                }
                .padding(.top, 11)
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// 新建草稿（演示形态：字段 + 生成摘要按钮）。
    private var draftCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZCCard(title: "授权面向") {
                ZCField(label: "origin") {
                    ZCInput(placeholder: "http://localhost:8080", text: .constant(""), mono: true, smallFont: true)
                }
                ZCField(label: "授权方账户地址（felt hex）") {
                    ZCInput(placeholder: "0x…", text: .constant(""), mono: true, smallFont: true)
                }
            }
            .padding(.bottom, 12)
            ZCCard(title: "scope 授权") {
                HStack(spacing: 4) {
                    ZCChip("开桌（play）", tone: .felt, xs: true)
                    ZCChip("买入（buyin）", tone: .felt, xs: true)
                    ZCChip("结算（settle）", tone: .felt, xs: true)
                }
                ZCLedgerRow("转账（transfer）", "未勾选")
                Text("withdraw 永不可选：提现签名面未开放。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .padding(.top, 4)
            }
            .padding(.bottom, 12)
            ZCField(label: "单笔限额") {
                ZCInput(text: .constant("1000"), mono: true)
            }
            ZCField(label: "日累计限额") {
                ZCInput(text: .constant("5000"), mono: true)
            }
            ZCField(label: "桌白名单") {
                ZCInput(placeholder: "table_id，逗号分隔（留空 = 不限桌，不推荐）", text: .constant(""), mono: true, smallFont: true)
            }
            ZCField(label: "有效期（小时）") {
                ZCInput(text: .constant("168"), mono: true)
            }
            ZCButton("生成摘要并确认", disabled: true)
            Text("delegated key 由 wallet-core 生成；摘要由 wallet-core poseidon 计算，UI 不算第二份。（演示态：登记入口关闭）")
                .font(.ui(10.5))
                .foregroundColor(model.c.ink3)
                .lineSpacing(2)
                .padding(.top, 10)
        }
    }
}

// MARK: - 13 Proof Portal

struct ZCPortalScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var binding = "0xc41d8f22e9a04b79b"

    var body: some View {
        ScreenScaffold {
            ZCSubHeader(title: "Proof Portal") {
                AnyView(ZCChip("STARK", tone: .felt, xs: true))
            }
            ZCBody {
                ZCField(label: "hand binding", aux: "网关 127.0.0.1:18900") {
                    ZCInput(placeholder: "64 位 hex（不带 0x）", text: $binding, mono: true, smallFont: true)
                }

                ZCButton(model.portal.running ? "验证中…" : "验证这一手牌", icon: .search, disabled: model.portal.running) {
                    model.runPortal()
                }
                .padding(.bottom, 4)

                stepsCard
                perfBanner
                settlementCard
                sealView
                conclusionBanner
            }
        } footer: {}
    }

    /// 验证步骤卡（四步）。
    @ViewBuilder
    private var stepsCard: some View {
        let p = model.portal
        let started = p.steps.contains { $0.state != .idle }
        if started {
            ZCCard(title: "验证步骤", more: "\(p.steps.filter { $0.state == .done }.count)/4") {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(p.steps.enumerated()), id: \.element.id) { i, s in
                        ZCStepRow(index: i + 1,
                                  state: stepState(s.state),
                                  title: s.title,
                                  sub: s.sub,
                                  spinning: s.state == .run)
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    private func stepState(_ s: PortalStep.State) -> ZCStepRow.StepState {
        switch s {
        case .idle: return .idle
        case .run: return .run
        case .done: return .done
        case .bad: return .bad
        }
    }

    /// 性能如实标注（>500ms 必须写出来）。
    @ViewBuilder
    private var perfBanner: some View {
        let p = model.portal
        if p.conclusion != nil || p.running {
            let total = p.starkElapsed + p.verdictElapsed
            ZCBanner(kind: .info, title: "性能如实标注",
                     body_: total > 500
                        ? "浏览器内完整验证约 \(String(format: "%.1f", Double(total) / 1000))s，超出 500ms 交互预算——进度如实展示，不伪装即时。"
                        : "本次复验 \(String(format: "%.2f", Double(total) / 1000))s，在 500ms 预算内（历史基准 p50 1.70–1.80s）。")
        }
    }

    @ViewBuilder
    private var settlementCard: some View {
        if let s = model.portal.settlement {
            ZCCard(title: "结算摘要") {
                ZCLedgerRow {
                    Text("hand_binding")
                        .font(.system(size: 11, design: .monospaced))
                } value: {
                    Text(shortAddr(s.handBinding))
                        .font(.system(size: 11, design: .monospaced))
                }
                ZCLedgerRow("table_id", s.tableId)
                ZCLedgerRow("底池", s.pot)
                ZCLedgerRow("rake", s.rake)
                ZCLedgerRow("我方份额", s.myShare)
                ZCLedgerRow {
                    Text("payout_root")
                        .font(.system(size: 11, design: .monospaced))
                } value: {
                    Text(s.payoutRoot)
                        .font(.system(size: 11, design: .monospaced))
                }
            }
            .padding(.bottom, 12)
        }
    }

    /// 结论印章（只在结论返回后落章）。
    @ViewBuilder
    private var sealView: some View {
        if let conclusion = model.portal.conclusion {
            HStack {
                Spacer()
                ZCSeal(text: conclusion == .verified ? "已验证" : conclusion == .partial ? "部分验证" : "未通过",
                       tone: conclusion == .verified ? .ok : .bad,
                       animate: true)
                Spacer()
            }
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var conclusionBanner: some View {
        if let conclusion = model.portal.conclusion {
            ZCBanner(kind: conclusion == .verified ? .ok : .bad,
                     title: conclusion == .verified ? "验证通过" : (conclusion == .partial ? "部分验证" : "验证未通过"),
                     body_: conclusion == .verified
                        ? "该手牌结算与链上 STARK 证明一致。两项验证相互独立，均为本地完成。"
                        : "两项验证相互独立：任一阶段被跳过或拒绝，整体结论就不是 fully verified（fail-closed，不合并成「看起来通过」）。")
        }
    }
}

// MARK: - 14 回执状态机

struct ZCReceiptsScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var seg = 0

    var body: some View {
        ScreenScaffold {
            ZCSubHeader(title: "交易回执") {
                AnyView(ZCChip("signed→seen→included", tone: .neutral, xs: true))
            }
            ZCBody {
                let buckets = model.receiptBuckets
                ZCSegmented(items: ["全部", "签名中", "已上链"], selection: $seg)

                let list: [ReceiptItem] = seg == 0 ? buckets.all : (seg == 1 ? buckets.pend : buckets.done)
                if list.isEmpty {
                    ZCEmptyBox(text: "该分桶暂无回执")
                        .padding(.bottom, 12)
                } else {
                    ZCCard(rowsStyle: true) {
                        ForEach(list) { r in
                            receiptRow(r)
                        }
                    }
                    .padding(.bottom, 12)
                }

                Text("回执状态机 signed → seen → included 单向推进，与凭证阶梯 pending → proven → finalized 是两套独立状态，不得混用同一种笔触。超出 deadline（10s）时提示存在 ForceInclude 协议路径，但当前版本只展示状态、不实现提交——按钮保持禁用；evidence 按网关返回如实展示，未验签就写未验签。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
            }
        } footer: {}
    }

    private func receiptRow(_ r: ReceiptItem) -> some View {
        let chip = model.receiptChip(r)
        let icon: ZCIconName = r.status == .included ? .check : (r.status == .seen ? .receipt : (r.pastDeadline ? .warn : .clock))
        let tone: ZCTxRow.IconTone = r.status == .included ? .ok : (r.status == .seen ? (r.pastDeadline ? .bad : .blue) : (r.pastDeadline ? .bad : .warn))
        let amountText: String?
        let amountTone: ZCAssetRow.AmountTone
        if let total = r.amountTotal {
            let isNeg = r.kind == "transfer" || r.kind == "buy_in"
            amountText = (isNeg ? "-" : "+") + fmtDisplay(total, kind: "play")
            amountTone = isNeg ? .neg : .pos
        } else {
            amountText = nil
            amountTone = .dim
        }
        let name: String
        switch r.kind {
        case "settle": name = "结算 · \(r.tableId.map { "\($0) 桌" } ?? "")".trimmedSlash
        case "buy_in": name = "买入 · 8♠ 桌"
        case "transfer": name = "转账 · 收款人 0x8f…d7"
        default: name = r.kindLabel
        }
        let sub: String
        if r.pastDeadline {
            sub = "\(shortAddr(r.digest, 8, 2)) · 超出 deadline"
        } else if r.status == .signed, let signedAt = Calendar.current.date(byAdding: .second, value: 92, to: r.signedAtMs), r.signedAtMs > Date().addingTimeInterval(-100) {
            sub = "\(shortAddr(r.digest, 8, 2)) · \(remainText(signedAt.timeIntervalSinceNow)) 后过期"
        } else {
            sub = "\(shortAddr(r.digest, 8, 2)) · \(relTime(r.signedAtMs))"
        }
        return VStack(alignment: .leading, spacing: 0) {
            ZCTxRow(icon: icon, iconTone: tone, name: name, sub: sub,
                    amount: amountText, amountTone: amountTone,
                    chip: (chip.0, chip.1),
                    forceIncludeDisabled: r.pastDeadline)
            Text("证据：\(r.status == .included ? "local_manual_entry（本机手工登记，非链上证实）" : "receipt_unverified_signature（回执未验签，如实标注）")")
                .font(.ui(10.5))
                .foregroundColor(model.c.ink3)
                .padding(.bottom, 6)
                .padding(.top, 2)
        }
    }
}
