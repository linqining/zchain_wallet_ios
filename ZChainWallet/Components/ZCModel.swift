import SwiftUI
import Combine
#if canImport(AppKit)
import AppKit
#endif

// ============================================================================
// ZCModel — 屏幕注册表 / 导航 / 钱包演示状态 / 纯逻辑（移植 common/ui_ledger.js
// 与 transfer_preview 的语义；演示数据与 Pixso 设计稿 19 屏逐值对应）。
//
// 诚实边界（与设计稿一致）：
// - 金额一律等宽、千分位、保留原始小数位（不四舍五入、不造精度）；
// - REAL / GAME 物理分库，跨域金额永不轧差；
// - REAL 提现 canSubmit 恒 false（fail-closed），虚线按钮 = 不可用；
// - 回执 evidence 原样展示，未验签就写未验签。
// ============================================================================

// MARK: - 链与屏幕注册表

enum Chain: String, CaseIterable, Codable {
    case zc, evm, stk

    var label: String {
        switch self { case .zc: return "ZChain"; case .evm: return "EVM"; case .stk: return "Starknet" }
    }
    /// 抬头 kind 的词形（Ledger · Zchain / Evm / Starknet）。
    var kindWord: String {
        switch self { case .zc: return "Zchain"; case .evm: return "Evm"; case .stk: return "Starknet" }
    }
}

enum ScreenId: String, CaseIterable {
    case welcome, success, importScreen = "import", lock
    case home, acct
    case zcSend = "zc-send", zcWithdraw = "zc-withdraw", zcConfirm = "zc-confirm"
    case zcSessions = "zc-sessions", zcPortal = "zc-portal", zcReceipts = "zc-receipts"
    case send, contract, history, manage
    case proofs, settings

    var tab: TabKind? {
        switch self {
        case .home: return .home
        case .acct, .zcSend, .zcWithdraw, .zcConfirm, .zcSessions, .zcReceipts, .send, .contract, .history, .manage: return .acct
        case .zcPortal, .proofs: return .proofs
        default: return nil
        }
    }
    /// 子页栏「返回」目标（'@acct' = 回账簿并沿用当前链）。
    var parent: NavTarget? {
        switch self {
        case .success: return .init(.home)
        case .importScreen: return .init(.welcome)
        case .lock: return .init(.home)
        case .zcSend, .zcWithdraw, .zcConfirm, .zcSessions, .zcPortal, .zcReceipts, .send, .contract, .history, .manage: return .acctChain
        case .settings: return .init(.home)
        default: return nil
        }
    }
    var title: String {
        switch self {
        case .welcome: return "欢迎 · 一次创建三层"
        case .success: return "创建成功 · 解锁口令"
        case .importScreen: return "导入 / 恢复"
        case .lock: return "锁定 · 统一解锁"
        case .home: return "三链总账"
        case .acct: return "账簿"
        case .zcSend: return "转账 · 贪心选币"
        case .zcWithdraw: return "REAL 提现预览 · fail-closed"
        case .zcConfirm: return "dapp 签名请求"
        case .zcSessions: return "会话密钥 · SNIP-12"
        case .zcPortal: return "Proof Portal"
        case .zcReceipts: return "回执状态机"
        case .send: return "发送 · 交易预览"
        case .contract: return "合约读写"
        case .history: return "交易记录 · 双边对账"
        case .manage: return "账户管理 · 危险区"
        case .proofs: return "凭证簿"
        case .settings: return "设置 · 能力矩阵"
        }
    }
}

enum TabKind { case home, acct, proofs }

struct NavTarget: Equatable {
    var id: ScreenId
    var chain: Chain?
    static let acctChain = NavTarget(.acct, chain: nil) // nil = 沿用当前链

    /// 无标签便捷 init（`NavTarget(.home)`）。
    init(_ id: ScreenId, chain: Chain? = nil) {
        self.id = id
        self.chain = chain
    }
}

// MARK: - 数据形状

enum Domain: String { case game, real }
enum ProofLevel: String, CaseIterable { case pending, soft, proven, finalized }

struct Note: Identifiable {
    let id = UUID()
    let commitment: String
    let amount: String        // 十进制串
    let proof: ProofLevel
    let spendable: Bool
    let domain: Domain

    var amountDecimal: Decimal { parseDecimal(amount) ?? 0 }
}

enum InclusionStatus: String { case signed, seen, included }

struct ReceiptItem: Identifiable {
    let id = UUID()
    let kind: String          // transfer / buy_in / settle / withdraw
    let digest: String
    let chainId: String
    let status: InclusionStatus
    let signedAtMs: Date
    let amountTotal: String?
    let tableId: String?
    let pastDeadline: Bool

    var kindLabel: String {
        switch kind {
        case "transfer": return "转账"
        case "buy_in": return "买入"
        case "settle": return "结算"
        case "withdraw": return "提现"
        default: return kind
        }
    }
}

struct SessionBinding: Identifiable {
    let id = UUID()
    let bindingId: String
    let origin: String
    let delegated: String
    let scopes: [String]
    let perTxLimit: String?
    let perDayLimit: String?
    let dailyUsed: String
    var status: SessionStatus
    let tables: [String]?
    let validUntil: Date
    let evidence: String
    var revoked: Bool = false

    enum SessionStatus: String { case active, exhausted, revoked, expired }
    var statusLabel: String {
        switch status {
        case .active: return "活跃"
        case .exhausted: return "已耗尽"
        case .revoked: return "已撤销"
        case .expired: return "已过期"
        }
    }
    var statusTone: ZCChipTone {
        switch status {
        case .active: return .felt
        case .exhausted, .expired: return .amb
        case .revoked: return .bad
        }
    }
    var usagePercent: Double? {
        guard let limit = perDayLimit, let l = Decimal(string: limit), l > 0,
              let u = Decimal(string: dailyUsed) else { return nil }
        return min(100, Double(truncating: NSDecimalNumber(decimal: u * 100 / l)))
    }
}

struct ChainTx: Identifiable {
    let id = UUID()
    let kind: String           // send / receive / contract
    let methodLabel: String?
    let hash: String
    let valueHuman: String
    let createdAt: Date
    let status: String         // confirmed / pending / failed / succeeded / reverted
    let source: String         // local / explorer
    let direction: String      // in / out

    var statusChip: (String, ZCChipTone) {
        if status == "confirmed" || status == "succeeded" { return ("成功", .felt) }
        if status == "failed" || status == "reverted" { return (status == "failed" ? "失败" : "已回退", .bad) }
        return ("待确认", .amb)
    }
}

struct LayerState {
    var has: Bool = true
    var unlocked: Bool = false
    var address: String? = nil
    var label: String? = nil
}

// MARK: - 钱包总状态

@MainActor
final class WalletModel: ObservableObject {
    // 导航
    @Published var screen: ScreenId = .home
    @Published var chain: Chain = .zc
    @Published var enterAnim = false

    // 偏好
    @Published var ground: ZCGround = .paper
    @Published var hideAmount = false
    @AppStorage("zc.ground") private var groundRaw: String = "paper"
    @AppStorage("zc.hideAmount") private var hideAmountRaw: Bool = false

    // 账户
    @Published var onboarded = false
    @Published var walletLabel = "牌手一号"
    @Published var layers: [String: LayerState] = [
        "zchain": LayerState(unlocked: false, address: "zc1qpoker8f2a91c4d7e26b30a5f48c9e2d17b64a3f7x2", label: "牌手一号"),
        "evm": LayerState(unlocked: false, address: "0x59195049a3f2c1e8b7d6a54f0c3e29d81b6a7527", label: "账户 2"),
        "stk": LayerState(unlocked: false, address: "0x058f41a7c3e92d8f6b1a0447e2c9d8f0b1a853f", label: "牌手一号"),
    ]

    // ZChain 数据（演示态 = 设计稿数据）
    @Published var playNotes: [Note] = []
    @Published var realNotes: [Note] = []
    @Published var receipts: [ReceiptItem] = []
    @Published var sessions: [SessionBinding] = []
    @Published var pendingRequest: PendingRequest? = nil
    @Published var proofLog: [ProofLogEntry] = []

    // 链层数据
    @Published var evmInfo: ChainInfo?
    @Published var stkInfo: ChainInfo?
    @Published var evmTxs: [ChainTx] = []
    @Published var stkTxs: [ChainTx] = []
    @Published var evmExplorerOn = true

    // 预览 / 草稿
    @Published var transferPreview: TransferPreview?
    @Published var withdrawPreview: WithdrawPreview?
    @Published var portal = PortalState()

    // UI 状态
    @Published var toastMsg: String? = nil
    @Published var overlay: OverlaySpec? = nil
    @Published var generatedPassword: CreatedWallet? = nil
    @Published var showGroundSeed = false

    private var toastTask: Task<Void, Never>? = nil

    // MARK: 演示行情（价格源已接入的设计态）

    let priceNative = Decimal(string: "1.012")!   // 1 NATIVE ≈ $1.012
    let priceETH = Decimal(string: "3360")!       // 1 ETH ≈ $3,360

    var c: ZCPalette { ground == .night ? .night : .paper }

    init() {
        ground = ZCGround(rawValue: groundRaw) ?? .paper
        hideAmount = hideAmountRaw
        loadDemoState()
    }

    func persistPrefs() {
        groundRaw = ground.rawValue
        hideAmountRaw = hideAmount
    }

    // MARK: 解锁 / 创建 / 锁定

    var anyUnlocked: Bool {
        layers.values.contains { $0.unlocked }
    }
    var unlockCount: (held: Int, unlocked: Int) {
        let held = ["zchain", "evm", "stk"].filter { layers[$0]?.has == true }
        return (held.count, held.filter { layers[$0]?.unlocked == true }.count)
    }
    func layer(_ chain: Chain) -> LayerState {
        layers[key(chain)] ?? LayerState()
    }
    private func key(_ chain: Chain) -> String {
        chain == .zc ? "zchain" : chain.rawValue
    }

    func quickCreate() {
        let pw = "felt-poker-verifiable-9x2a"
        layers["zchain"]?.unlocked = true
        layers["evm"]?.unlocked = true
        layers["stk"]?.unlocked = false
        onboarded = true
        generatedPassword = CreatedWallet(password: pw, generated: true,
                                          zc: shortAddr(layers["zchain"]?.address, 12, 4),
                                          evm: shortAddr(layers["evm"]?.address, 8, 4),
                                          stk: shortAddr(layers["stk"]?.address, 8, 4))
        go(.success)
        showToast("已创建三层账户 · 口令只显示一次", 4000)
    }

    func quickUnlock(password: String) -> Bool {
        guard !password.isEmpty else { return false }
        // 演示：任意非空口令可解锁（fail-closed 语义见 README）。
        layers["zchain"]?.unlocked = true
        layers["evm"]?.unlocked = true
        var stk = layers["stk"] ?? LayerState()
        stk.unlocked = true
        layers["stk"] = stk
        return true
    }

    func lockAll() {
        for k in layers.keys { layers[k]?.unlocked = false }
        evmInfo = nil
        stkInfo = nil
    }

    func lockCurrent() {
        layers[key(chain)]?.unlocked = false
        if chain == .evm { evmInfo = nil }
        if chain == .stk { stkInfo = nil }
    }

    // MARK: 导航（屏幕注册表是唯一权威）

    func go(_ id: ScreenId, chain newChain: Chain? = nil) {
        if let c = newChain { self.chain = c }
        if screen != id {
            enterAnim = true
            screen = id
        }
    }

    func go(_ target: NavTarget) {
        go(target.id, chain: target.chain)
    }

    func back() {
        guard let parent = screen.parent else { return }
        if parent.id == .acct {
            go(.acct, chain: chain)
        } else {
            go(parent.id)
        }
    }

    func selectChain(_ c: Chain) {
        guard c != chain else { return }
        chain = c
        go(.acct, chain: c)
    }

    // MARK: 复制 / toast

    func copy(_ text: String, kind: ZCPassBox.CopyKind = .text) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        switch kind {
        case .password:
            showToast("已复制口令 · 注意：剪贴板内容可被其他应用读取，用完请立即清空", 4000)
        case .privatekey:
            showToast("已复制私钥 · 注意：剪贴板内容可被其他应用读取，用完请立即清空", 4000)
        case .address:
            showToast("已复制完整地址")
        case .text:
            showToast("已复制到剪贴板")
        }
    }

    func showToast(_ msg: String, _ ms: Int = 2400) {
        toastTask?.cancel()
        withAnimation(ZCAnim.std) { toastMsg = msg }
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(ZCAnim.out) { self?.toastMsg = nil }
        }
    }

    // MARK: 金额显示

    func amt(_ text: String) -> String { hideAmount ? "••••" : text }

    /// 法币估值（演示行情）。
    func fiat(_ native: Decimal, price: Decimal) -> String {
        var v = native * price
        var rounded = Decimal()
        NSDecimalRound(&rounded, &v, 2, .bankers)
        return "$" + fmtDisplay(NSDecimalNumber(decimal: rounded).stringValue, kind: "usd")
    }

    // MARK: note 域合计（跨域永不轧差）

    func playTotal() -> Decimal { playNotes.filter { $0.spendable }.reduce(0) { $0 + $1.amountDecimal } }
    func playLocked() -> Decimal { playNotes.filter { !$0.spendable }.reduce(0) { $0 + $1.amountDecimal } }
    func realTotal() -> Decimal { realNotes.filter { $0.spendable }.reduce(0) { $0 + $1.amountDecimal } }

    /// 最弱凭证（weakest）与阶梯步进。
    func realLadder() -> (weakest: ProofLevel?, total: Int, steps: [ZCRail.RailStep], outcome: Outcome) {
        let notes = realNotes
        guard !notes.isEmpty else { return (nil, 0, ladderSteps(current: nil, outcome: .idle, required: .finalized), .idle) }
        let weakest = notes.map { $0.proof }.min { rank($0) < rank($1) }!
        // 首页/凭证簿展示 outcome=wait（琥珀 cur）；blocked（朱红）只在提现页
        // 由 canSubmit:false 触发——「仍在推进」与「被卡住」是两种笔触。
        let outcome = ladderOutcome(weakest: weakest, required: .finalized, canSubmit: nil, spendable: notes.filter { $0.spendable }.count)
        return (weakest, notes.count, ladderSteps(current: weakest, outcome: outcome, required: .finalized), outcome)
    }

    func rank(_ p: ProofLevel) -> Int { ProofLevel.allCases.firstIndex(of: p) ?? 0 }

    enum Outcome { case idle, ok, blocked, wait }

    /// 阶梯 outcome 唯一出口（AC-09/10：blocked 必画朱红，不画"仍在推进"的琥珀）。
    func ladderOutcome(weakest: ProofLevel?, required: ProofLevel?, canSubmit: Bool?, spendable: Int?) -> Outcome {
        guard let weakest else { return .idle }
        if canSubmit == false { return .blocked }
        if let s = spendable, s == 0 { return .blocked }
        if let required, rank(weakest) < rank(required) { return .wait }
        return .ok
    }

    func ladderSteps(current: ProofLevel?, outcome: Outcome, required: ProofLevel?) -> [ZCRail.RailStep] {
        let curIdx = current.map { rank($0) } ?? -1
        return ProofLevel.allCases.enumerated().map { i, level in
            var state: RailNodeState = .idle
            if curIdx >= 0 {
                if i <= curIdx { state = .done }
                else if i == curIdx + 1 {
                    switch outcome {
                    case .blocked: state = .bad
                    case .wait: state = .cur
                    default: state = .idle
                    }
                }
            }
            return .init(proof: level.rawValue, state: state, required: required == level)
        }
    }

    /// 贪心选币（note 全额消费 + 找零回本账户 + 守恒）。
    func greedySelect(amount: Decimal, notes: [Note]) -> (inputs: [Note], change: Decimal, totalIn: Decimal)? {
        guard amount > 0 else { return nil }
        let spendable = notes.filter { $0.spendable }.sorted { $0.amountDecimal > $1.amountDecimal }
        var picked: [Note] = []
        var sum: Decimal = 0
        // 最小张数：先大面额（演示口径；与 transfer_preview 的"小额优先省找零"可互换）
        for n in spendable.sorted(by: { $0.amountDecimal < $1.amountDecimal }) {
            if sum >= amount { break }
            picked.append(n)
            sum += n.amountDecimal
        }
        guard sum >= amount else { return nil }
        return (picked, sum - amount, sum)
    }

    func makeTransferPreview(amountRaw: String, owner: String) -> TransferPreview? {
        guard let amount = parseDecimal(amountRaw), amount > 0 else { return nil }
        guard let sel = greedySelect(amount: amount, notes: playNotes) else { return nil }
        let weakest = sel.inputs.map { $0.proof }.min { rank($0) < rank($1) }!
        let required: ProofLevel = .soft // devnet 门槛：soft（mainnet/testnet 为 proven）
        let reached = rank(weakest) >= rank(required)
        let digest = "0x" + String(repeating: "9a2b", count: 4) + "c41d8f22e9a04b79b1e4088a2"
        return TransferPreview(
            amount: amount, owner: owner, inputs: sel.inputs, change: sel.change, totalIn: sel.totalIn,
            worstProof: weakest, requiredProof: required, reached: reached,
            canSubmit: reached, digest: digest)
    }

    func confirmTransfer() {
        guard let p = transferPreview, p.canSubmit else { return }
        // 演示：从库内移除被消费 note，登记回执（signed）。
        let consumed = Set(p.inputs.map { $0.id })
        playNotes.removeAll { consumed.contains($0.id) }
        if p.change > 0 {
            playNotes.append(Note(commitment: "chg-" + String(Int.random(in: 1000...9999)),
                                  amount: fmtDisplay(NSDecimalNumber(decimal: p.change).stringValue, kind: "play"),
                                  proof: .pending, spendable: true, domain: .game))
        }
        receipts.insert(ReceiptItem(kind: "transfer", digest: p.digest, chainId: "zchain-devnet-1",
                                    status: .signed, signedAtMs: Date(), amountTotal: fmtDisplay(NSDecimalNumber(decimal: p.amount).stringValue, kind: "play"),
                                    tableId: nil, pastDeadline: false), at: 0)
        transferPreview = nil
        showToast("已签名并登记回执 · \(shortAddr(p.digest, 8, 6))")
        go(.zcReceipts, chain: .zc)
    }

    // MARK: 签名请求

    func decidePending(_ approve: Bool) {
        guard pendingRequest != nil else { return }
        showToast(approve ? "已批准 · 会话密钥路径（≤ 1,000 PLAY）" : "已拒绝")
        pendingRequest = nil
        if approve {
            // 演示：批准开桌买入 → 登记 signed 回执
            receipts.insert(ReceiptItem(kind: "buy_in", digest: "0xc41d8f22e9a04b79b1e4088a2", chainId: "zchain-devnet-1",
                                        status: .signed, signedAtMs: Date(), amountTotal: "500.00",
                                        tableId: "A3F2", pastDeadline: false), at: 0)
        }
    }

    // MARK: 会话密钥

    func revokeSession(_ b: SessionBinding) {
        guard let idx = sessions.firstIndex(where: { $0.id == b.id }) else { return }
        sessions[idx].revoked = true
        sessions[idx].status = .revoked
        showToast("撤销为粘滞操作：该 origin 的签名一律拒绝", 4000)
    }

    func deleteSession(_ b: SessionBinding) {
        sessions.removeAll { $0.id == b.id }
        showToast("记录已删除")
    }

    // MARK: Portal（演示：本地模拟网关拉取 + 计时）

    func runPortal() {
        guard !portal.running else { return }
        portal = PortalState(running: true, binding: portal.binding.isEmpty ? "0xc41d8f22e9a04b79b" : portal.binding,
                             steps: PortalState.defaultSteps.map { .init(title: $0.title, hint: $0.hint, state: .idle, sub: $0.hint) },
                             startedAt: Date())

        func setStepState(_ i: Int, _ s: PortalStep.State) {
            portal.steps[i].state = s
        }
        func finishStep(_ i: Int, sub: String, ok: Bool) {
            portal.steps[i].state = ok ? .done : .bad
            portal.steps[i].sub = sub
        }
        func step(_ i: Int, afterMS: Int, doneSub: String) async {
            setStepState(i, .run)
            try? await Task.sleep(nanoseconds: UInt64(afterMS) * 1_000_000)
            finishStep(i, sub: doneSub, ok: true)
        }
        func stepRun(_ i: Int) {
            setStepState(i, .run)
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            // 步骤 1：拉取结算明细
            await step(0, afterMS: 420, doneSub: "网关 127.0.0.1:18900 · 200 OK")
            // 步骤 2：下载 STARK 证明
            await step(1, afterMS: 610, doneSub: "payload 84.2 KB · engine stwo")
            // 步骤 3：本地完整验证（设计口径 ~1.7s）
            stepRun(2)
            try? await Task.sleep(nanoseconds: 1_720_000_000)
            finishStep(2, sub: "verified · 1720 ms", ok: true)
            // 步骤 4：wallet-core 本地复验
            stepRun(3)
            try? await Task.sleep(nanoseconds: 180_000_000)
            finishStep(3, sub: "verified · 176 ms", ok: true)
            portal.settlement = PortalSettlement(
                handBinding: "0xc41d8f22e9a04b79b", tableId: "#128",
                pot: "1,240.00", rake: "24.80 PLAY（2%）",
                myShare: "+620.50 PLAY", payoutRoot: "0x8c3f…d210")
            portal.starkElapsed = 1720
            portal.verdictElapsed = 176
            portal.conclusion = .verified
            portal.running = false
            proofLog.insert(ProofLogEntry(binding: portal.binding, conclusion: "verified", elapsedMS: 1720 + 176, at: Date()), at: 0)
            showToast("验证通过 · 两项验证一致（本地完成）")
        }
    }

    // MARK: 回执

    var receiptBuckets: (all: [ReceiptItem], pend: [ReceiptItem], done: [ReceiptItem]) {
        (receipts, receipts.filter { $0.status != .included }, receipts.filter { $0.status == .included })
    }

    func receiptChip(_ r: ReceiptItem) -> (String, ZCChipTone) {
        if r.status == .included { return ("included", .felt) }
        if r.status == .seen { return (r.pastDeadline ? "seen 超期" : "seen", r.pastDeadline ? .bad : .play) }
        return (r.pastDeadline ? "signed 超期" : "signed", r.pastDeadline ? .bad : .amb)
    }

    // MARK: 链层（EVM / Starknet）演示

    func refreshChain(_ chain: Chain) {
        switch chain {
        case .evm:
            evmInfo = ChainInfo(balanceHuman: "2.4183", chainIdHex: "0x1", chainIdMismatch: false,
                                gasPriceGwei: "12", nonce: "42", tokenSymbol: "ETH")
        case .stk:
            stkInfo = ChainInfo(balanceHuman: "1.2034", chainIdHex: "ZCDN", chainIdMismatch: false,
                                gasPriceGwei: "—", nonce: "7", tokenSymbol: "ETH")
        case .zc: break
        }
    }

    func prepareChainTx(chain: Chain, to: String, value: String) -> ChainTxPreview? {
        guard parseDecimal(value) != nil, !to.isEmpty else { return nil }
        let fee = chain == .evm ? "0.000252" : "0.00042"
        return ChainTxPreview(
            from: chain == .evm ? (layers["evm"]?.address ?? "") : (layers["stk"]?.address ?? ""),
            to: to, valueHuman: value, gasLimit: chain == .evm ? "21,000" : nil,
            feeHuman: fee, feeFiat: chain == .evm ? "≈ $0.85" : "maxFee 0.00042",
            chainId: chain == .evm ? "1" : "ZCDN")
    }

    func broadcastChainTx(_ p: ChainTxPreview, chain: Chain) {
        let tx = ChainTx(kind: "send", methodLabel: nil, hash: "0x8f3a91c4d7e26b30a5f4", valueHuman: p.valueHuman,
                         createdAt: Date(), status: "pending", source: "local", direction: "out")
        if chain == .evm { evmTxs.insert(tx, at: 0) } else { stkTxs.insert(tx, at: 0) }
        showToast("已广播 · \(shortAddr(tx.hash, 10, 8))")
    }

    // MARK: 演示状态装载（逐值对应设计稿）

    private func loadDemoState() {
        // PLAY notes：可用 12,400.00（贪心选币演示：500 → 300+200）
        playNotes = [
            Note(commitment: "4f2a91c7e03ab5d8", amount: "300.00", proof: .proven, spendable: true, domain: .game),
            Note(commitment: "91c7e03a5d8b4f2a", amount: "200.00", proof: .proven, spendable: true, domain: .game),
            Note(commitment: "b7d24c6f0a91e583", amount: "11,900.00", proof: .proven, spendable: true, domain: .game),
        ]
        // REAL notes：10,000.00 = 4 份 finalized + 1 份 soft（1,500）
        realNotes = [
            Note(commitment: "77b1c93e04dd8f2a", amount: "1,000.00", proof: .finalized, spendable: true, domain: .real),
            Note(commitment: "c93e5f10a20877b1", amount: "2,500.00", proof: .finalized, spendable: true, domain: .real),
            Note(commitment: "a20891ce77b1c93e", amount: "1,500.00", proof: .soft, spendable: true, domain: .real),
            Note(commitment: "d41f0b8ae6c29377", amount: "2,500.00", proof: .finalized, spendable: true, domain: .real),
            Note(commitment: "e6c29377d41f0b8a", amount: "2,500.00", proof: .finalized, spendable: true, domain: .real),
        ]
        // 回执（zc-receipts 5 条 + zc-dash 两条复用）
        receipts = [
            ReceiptItem(kind: "settle", digest: "0x77d03f9eaa31c2b4", chainId: "zchain-devnet-1", status: .signed,
                        signedAtMs: Date().addingTimeInterval(-92), amountTotal: nil, tableId: "A3F2", pastDeadline: false),
            ReceiptItem(kind: "settle", digest: "0x3f9e77d0aa31c2b4", chainId: "zchain-devnet-1", status: .seen,
                        signedAtMs: Date().addingTimeInterval(-35), amountTotal: "620.50", tableId: "128", pastDeadline: false),
            ReceiptItem(kind: "buy_in", digest: "0xc41d8f229b04d7e2", chainId: "zchain-devnet-1", status: .included,
                        signedAtMs: Date().addingTimeInterval(-120), amountTotal: "500.00", tableId: "A3F2", pastDeadline: false),
            ReceiptItem(kind: "transfer", digest: "0x9a02c3d4ef56871a", chainId: "zchain-devnet-1", status: .included,
                        signedAtMs: Date().addingTimeInterval(-3600), amountTotal: "200.00", tableId: nil, pastDeadline: false),
            ReceiptItem(kind: "settle", digest: "0x51b7e8b0671902aa", chainId: "zchain-devnet-1", status: .seen,
                        signedAtMs: Date().addingTimeInterval(-86400), amountTotal: "88.00", tableId: "96", pastDeadline: true),
        ]
        // 会话密钥（设计稿两卡）
        sessions = [
            SessionBinding(bindingId: "0x7ad9c1e40000", origin: "poker.zchain.devnet", delegated: "0x7ad9…c1e4",
                           scopes: ["开桌", "买入", "结算"], perTxLimit: "1,000", perDayLimit: "5,000",
                           dailyUsed: "2,150", status: .active, tables: ["8♠", "9♣"],
                           validUntil: Date().addingTimeInterval(6 * 86400 + 12 * 3600), evidence: "devnet_local_entry"),
            SessionBinding(bindingId: "0x1e4088a20000", origin: "demo.local", delegated: "0x1e40…88a2",
                           scopes: ["开桌"], perTxLimit: "1,000", perDayLimit: "5,000",
                           dailyUsed: "5,000", status: .exhausted, tables: nil,
                           validUntil: Date().addingTimeInterval(3600), evidence: "devnet_local_entry"),
        ]
        // 待确认请求（zc-confirm 演示）
        pendingRequest = PendingRequest(
            origin: "poker.zchain.devnet", method: "zchain_sign", kind: "sign",
            expiresAt: Date().addingTimeInterval(112),
            chainId: "zchain-devnet-1", tableId: "#A3F2", asset: "PLAY", rake: "2.00%",
            owner: "0x8f3a91c4…d7e2", handBinding: "0xc41d8f22…04b79b",
            requestId: "3f9e77d0…aa31", amount: "500.00",
            digest: "0x1a2b3c4d5e6f70819a2b3c4d5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f7a8b9c0d",
            sessionPath: true)
        // 链层演示（与设计稿对齐：EVM Ethereum · chainId 1；Starknet SN DevNet · ZCDN）
        evmInfo = ChainInfo(balanceHuman: "2.4183", chainIdHex: "0x1", chainIdMismatch: false,
                            gasPriceGwei: "12", nonce: "42", tokenSymbol: "ETH")
        evmTxs = [
            ChainTx(kind: "send", methodLabel: nil, hash: "0x8f3a91c4d7e2c2", valueHuman: "0.25",
                    createdAt: Date().addingTimeInterval(-120), status: "confirmed", source: "explorer", direction: "out"),
            ChainTx(kind: "send", methodLabel: nil, hash: "0x22af3c4d5e6f71", valueHuman: "0.10",
                    createdAt: Date().addingTimeInterval(-30), status: "pending", source: "local", direction: "out"),
            ChainTx(kind: "receive", methodLabel: nil, hash: "0x51b7678a9b0cc8", valueHuman: "1.20",
                    createdAt: Date().addingTimeInterval(-86400), status: "confirmed", source: "explorer", direction: "in"),
            ChainTx(kind: "contract", methodLabel: "approve · USDC", hash: "0xd90123453456", valueHuman: "0",
                    createdAt: Date().addingTimeInterval(-3 * 86400), status: "confirmed", source: "explorer", direction: "out"),
            ChainTx(kind: "contract", methodLabel: "swap · 1inch", hash: "0x9a02c3d4ef56ef", valueHuman: "0",
                    createdAt: Date().addingTimeInterval(-5 * 86400), status: "failed", source: "explorer", direction: "out"),
        ]
        stkTxs = [
            ChainTx(kind: "send", methodLabel: "invoke · transfer", hash: "0x33c1e8b0671967", valueHuman: "0.50",
                    createdAt: Date().addingTimeInterval(-600), status: "confirmed", source: "local", direction: "out"),
            ChainTx(kind: "receive", methodLabel: "水龙头 · dev_faucet", hash: "0xe8b0c3d4567819", valueHuman: "10.00",
                    createdAt: Date().addingTimeInterval(-3600), status: "confirmed", source: "local", direction: "in"),
        ]
        // 已复验记录（凭证簿演示）
        proofLog = [
            ProofLogEntry(binding: "0xc41d8f22e9a04b79b", conclusion: "verified", elapsedMS: 1720, at: Date()),
        ]
        onboarded = true
        // 首屏路由：三层有锁 → home（演示解锁 2/3，与设计稿一致）
        layers["zchain"]?.unlocked = true
        layers["evm"]?.unlocked = true
        layers["stk"]?.unlocked = false

        // 演示/验收钩子：环境变量可直达任意屏幕 / 底色 / 链（仅影响初始展示）。
        let env = ProcessInfo.processInfo.environment
        if let g = env["ZC_GROUND"], g == "night" { ground = .night }
        if let c = env["ZC_CHAIN"], let chain = Chain(rawValue: c) { self.chain = chain }
        if let name = env["ZC_SCREEN"], let target = ScreenId(rawValue: name) {
            if target == .success {
                generatedPassword = CreatedWallet(password: "felt-poker-verifiable-9x2a", generated: true,
                                                  zc: shortAddr(layers["zchain"]?.address, 12, 4),
                                                  evm: shortAddr(layers["evm"]?.address, 8, 4),
                                                  stk: shortAddr(layers["stk"]?.address, 8, 4))
            }
            screen = target
        }
    }
}

// MARK: - 值类型

struct CreatedWallet {
    let password: String
    let generated: Bool
    let zc: String
    let evm: String
    let stk: String
}

struct ChainInfo {
    let balanceHuman: String
    let chainIdHex: String
    let chainIdMismatch: Bool
    let gasPriceGwei: String
    let nonce: String
    let tokenSymbol: String
}

struct ChainTxPreview {
    let from: String
    let to: String
    let valueHuman: String
    let gasLimit: String?
    let feeHuman: String
    let feeFiat: String?
    let chainId: String
}

struct TransferPreview {
    let amount: Decimal
    let owner: String
    let inputs: [Note]
    let change: Decimal
    let totalIn: Decimal
    let worstProof: ProofLevel
    let requiredProof: ProofLevel
    let reached: Bool
    let canSubmit: Bool
    let digest: String
}

struct WithdrawPreview {
    let amount: Decimal
    let owner: String
    let inputs: [Note]
    let change: Decimal
    let totalIn: Decimal
    let worstProof: ProofLevel
    let requiredProof: ProofLevel = .finalized
    let canSubmit: Bool = false   // fail-closed：展示门 ∧ finality 合取，恒 false
    let reasons: [(String, String?, ZCChipTone)] = [
        ("提现通道未开放（v1 托管模式）", "本版本不会开放", .bad),
        ("1 张 note 的证明未达 finalized", nil, .amb),
        ("托管方签名服务待接入", nil, .amb),
    ]
}

struct PendingRequest {
    let origin: String
    let method: String
    let kind: String
    let expiresAt: Date
    let chainId: String
    let tableId: String
    let asset: String
    let rake: String
    let owner: String
    let handBinding: String
    let requestId: String
    let amount: String
    let digest: String
    let sessionPath: Bool
}

struct ProofLogEntry: Identifiable {
    let id = UUID()
    let binding: String
    let conclusion: String
    let elapsedMS: Int
    let at: Date
}

struct PortalStep: Identifiable {
    let id = UUID()
    let title: String
    let hint: String
    var state: State
    var sub: String

    enum State: Equatable { case idle, run, done, bad }
}

struct PortalSettlement {
    let handBinding: String
    let tableId: String
    let pot: String
    let rake: String
    let myShare: String
    let payoutRoot: String
}

struct PortalState {
    var running = false
    var binding: String = ""
    var steps: [PortalStep] = PortalState.defaultSteps.map { .init(title: $0.title, hint: $0.hint, state: .idle, sub: $0.hint) }
    var settlement: PortalSettlement? = nil
    var starkElapsed: Int = 0
    var verdictElapsed: Int = 0
    var conclusion: Conclusion? = nil
    var startedAt: Date? = nil

    enum Conclusion { case verified, partial, failed }

    static let defaultSteps: [(title: String, hint: String)] = [
        ("拉取结算明细", "网关 settlement 端点"),
        ("下载 STARK 证明", "proof 归档 payload"),
        ("本地完整验证", "stwo：FRI + Merkle + 约束 + scope 重建"),
        ("wallet-core 本地复验", "结算关系与 payout_root 比对"),
    ]
}

// MARK: - 浮层（sheet / modal）

struct OverlaySpec: Identifiable {
    let id = UUID()
    let kind: Kind

    enum Kind {
        case receive(chain: Chain)
        case accountSwitch
        case networkPicker
        case revokeConfirm(SessionBinding)
        case removeAccount(Chain)
        case capabilityMatrix
    }
}

/// 宽容十进制解析：剥离千分位逗号（"1,500.00" → 1500.00；Decimal(string:) 会
/// 在逗号处静默截断——账簿第一纪律是不静默丢数）。
func parseDecimal(_ raw: String) -> Decimal? {
    Decimal(string: raw.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces))
}

// MARK: - 金额格式化（移植 fmtAmount / fmtDisplay）

/// 千分位 + 保留原始小数位（不补齐、不四舍五入、不造精度）。
func fmtAmount(_ raw: String) -> String {
    let s = raw.trimmingCharacters(in: .whitespaces)
    var neg = false
    var body = s
    if body.hasPrefix("-") { neg = true; body.removeFirst() }
    let parts = body.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
    guard let intPart = parts.first, !intPart.isEmpty, intPart.allSatisfy({ $0.isNumber }) else { return s }
    let frac = parts.count > 1 ? "." + parts[1] : ""
    var grouped = ""
    let digits = Array(intPart)
    for (i, ch) in digits.enumerated() {
        if i > 0 && (digits.count - i) % 3 == 0 { grouped += "," }
        grouped.append(ch)
    }
    return (neg ? "-" : "") + grouped + frac
}

/// 展示精度补零（只补齐不截断；kind：play/native/note→2 位，eth/strk→4 位）。
func fmtDisplay(_ raw: String, kind: String) -> String {
    let target: Int
    switch kind {
    case "eth", "strk": target = 4
    default: target = 2
    }
    let s = raw.trimmingCharacters(in: .whitespaces)
    let parts = s.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
    guard let intPart = parts.first, !intPart.isEmpty, intPart.allSatisfy({ $0.isNumber }) else {
        return fmtAmount(s)
    }
    var frac = parts.count > 1 ? String(parts[1]) : ""
    if frac.count < target { frac += String(repeating: "0", count: target - frac.count) }
    return fmtAmount(String(intPart) + "." + frac)
}

/// 带符号金额。
func fmtSigned(_ raw: String, positive: Bool = false, negative: Bool = false) -> String {
    let s = fmtAmount(raw)
    if positive { return "+" + s }
    if negative { return s.hasPrefix("-") ? s : "-" + s }
    return s
}

/// 相对时间。
func relTime(_ date: Date, now: Date = Date()) -> String {
    let s = Int(max(0, now.timeIntervalSince(date)))
    if s < 10 { return "刚刚" }
    if s < 60 { return "\(s) 秒前" }
    if s < 3600 { return "\(s / 60) 分钟前" }
    if s < 86400 { return "\(s / 3600) 小时前" }
    if s < 30 * 86400 { return "\(s / 86400) 天前" }
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

/// 剩余时间（倒计时）。
func remainText(_ interval: TimeInterval) -> String {
    if interval <= 0 { return "已过期" }
    let s = Int(ceil(interval))
    if s < 60 { return "\(s)s" }
    let m = s / 60, rs = s % 60
    if m < 60 { return "\(m):\(String(format: "%02d", rs))" }
    return "\(m / 60)h \(m % 60)m"
}

/// 有效期剩余（会话密钥）。
func validityRemain(_ until: Date, now: Date = Date()) -> String {
    let left = until.timeIntervalSince(now)
    if left <= 0 { return "已过期" }
    let d = Int(left) / 86400
    let h = Int(left) % 86400 / 3600
    if d > 0 { return "剩 \(d) 天 \(h) 小时" }
    if h > 0 { return "剩 \(h) 小时" }
    return "剩 \(max(1, Int(left) / 60)) 分钟"
}

/// 错误码 → 文案（全 UI 单一口径）。
let ERROR_TEXT: [String: String] = [
    "BadPassword": "口令错误（fail-closed）",
    "AmountInvalid": "金额不合法",
    "AmountOverflow": "金额超出可表示范围",
    "OwnerInvalid": "收款地址格式不合法",
    "InsufficientFunds": "可用余额不足（note 全额消费，不支持部分花费）",
    "NoSpendableNote": "没有可花费的 note",
    "PreviewMismatch": "预览摘要与签名内容不一致（已拒绝）",
    "GatewayUnreachable": "网关不可达（未伪造结果）",
    "GatewayNotConfigured": "当前网络未配置网关",
]

func errorText(_ code: String) -> String { ERROR_TEXT[code] ?? code }
