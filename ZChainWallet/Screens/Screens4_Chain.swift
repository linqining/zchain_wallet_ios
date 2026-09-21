import SwiftUI

// ============================================================================
// Screens4_Chain — 15 发送 · 交易预览 / 合约读写 / 16 交易记录 / 17 账户管理
// （evm 与 stk 同一套结构，链=参数）
// ============================================================================

@MainActor
private func activeChain(_ model: WalletModel) -> Chain {
    model.chain == .zc ? .evm : model.chain
}

// MARK: - 15 发送 · 交易预览

struct ChainSendScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var amount = ""
    @State private var recipient = ""
    @State private var preview: ChainTxPreview?
    @State private var err = ""

    var body: some View {
        let chain = activeChain(model)
        ScreenScaffold {
            ZCSubHeader(title: "发送") {
                AnyView(ZCChip(chain == .evm ? "Ethereum" : "SN DevNet", tone: .neutral, xs: true))
            }
            ZCBody {
                let unit = chain == .evm ? "ETH" : "ETH"
                let balance = chain == .evm ? (model.evmInfo?.balanceHuman ?? "—") : (model.stkInfo?.balanceHuman ?? "—")
                ZCField(label: "金额",
                        aux: "可用 \(fmtDisplay(balance, kind: "eth")) · ",
                        auxButton: ("MAX", { amount = balance })) {
                    ZCAmountInput(text: $amount, unit: unit)
                }
                ZCFiatNote(text: "≈ $840.12 · gas price 12 gwei")
                    .padding(.bottom, 4)
                ZCField(label: "收款地址") {
                    ZCInput(placeholder: "0x…", text: $recipient, mono: true, smallFont: true)
                }

                if let p = preview {
                    previewCard(p, chain: chain)
                }

                if preview == nil {
                    ZCButton(chain == .evm ? "生成交易预览" : "生成 invoke 预览") {
                        err = ""
                        guard let p = model.prepareChainTx(chain: chain, to: recipient, value: amount) else {
                            err = "输入不合法"
                            return
                        }
                        preview = p
                    }
                }

                ZCResultLine(text: err)

                if preview != nil {
                    ZCButton("确认签名并发送", large: true) {
                        model.broadcastChainTx(preview!, chain: chain)
                        preview = nil
                        amount = ""
                        recipient = ""
                    }
                }

                ZCBanner(kind: .bad, title: "发送后不可撤销",
                         body_: "请核对地址与金额；chainId 不符时交易将被拒绝签名。")
                    .padding(.top, 6)
            }
        } footer: {}
    }

    private func previewCard(_ p: ChainTxPreview, chain: Chain) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZCCard(title: "交易预览", more: chain == .evm ? "eth_sendTransaction" : "invoke v1") {
                ZCLedgerRow {
                    Text("from")
                } value: {
                    Text(shortAddr(p.from, 8, 4))
                }
                ZCLedgerRow {
                    Text("to")
                } value: {
                    Text(shortAddr(p.to, 8, 4))
                }
                ZCLedgerRow("value", "\(fmtDisplay(p.valueHuman, kind: "eth")) ETH")
                if let gas = p.gasLimit {
                    ZCLedgerRow("gas limit", "\(gas)（EIP-155）")
                }
                ZCLedgerRow {
                    Text(chain == .evm ? "预估手续费" : "max fee")
                } value: {
                    HStack(spacing: 4) {
                        Text("\(p.feeHuman) ETH")
                        if let f = p.feeFiat, chain == .evm {
                            Text(f)
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(model.c.ink3)
                        }
                    }
                }
                ZCLedgerRow {
                    Text("chainId")
                } value: {
                    HStack(spacing: 5) {
                        Text(p.chainId)
                        ZCChip("校验通过", tone: .felt, xs: true)
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }
}

// MARK: - 合约读写

struct ChainContractScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var contract = ""
    @State private var method = ""
    @State private var args = ""
    @State private var result: [String] = []
    @State private var err = ""

    var body: some View {
        let chain = activeChain(model)
        ScreenScaffold {
            ZCSubHeader(title: "合约") {
                AnyView(ZCChip(chain == .evm ? "eth_call" : "starknet_call", tone: .neutral, xs: true))
            }
            ZCBody {
                ZCField(label: "合约地址") {
                    ZCInput(placeholder: "0x…", text: $contract, mono: true, smallFont: true)
                }
                ZCField(label: "方法名") {
                    ZCInput(placeholder: chain == .evm ? "balanceOf / transfer / symbol" : "balance_of / symbol / faucet",
                            text: $method, mono: true, smallFont: true)
                }
                ZCField(label: "参数") {
                    ZCInput(placeholder: chain == .evm ? "逗号分隔；token 金额用人类可读单位" : "felt hex（0x…），逗号分隔",
                            text: $args, mono: true, smallFont: true)
                }
                HStack(spacing: 9) {
                    ZCButton("读取", style: .secondary) {
                        err = ""
                        guard !contract.isEmpty, !method.isEmpty else {
                            err = "请填写合约地址与方法名"
                            return
                        }
                        // 演示：常见只读方法给演示返回
                        if method.lowercased().contains("balance") {
                            result = ["3,286.50（raw 3286500000）"]
                        } else if method.lowercased().contains("symbol") {
                            result = ["USDC"]
                        } else {
                            result = ["0x1（bool true）"]
                        }
                    }
                    ZCButton("发起交易") {
                        err = ""
                        guard !contract.isEmpty, !method.isEmpty else {
                            err = "请填写合约地址与方法名"
                            return
                        }
                        model.showToast("非只读方法走交易确认路径（演示态）")
                    }
                }
                ZCResultLine(text: err)

                if !result.isEmpty {
                    ZCCard(title: method) {
                        ForEach(Array(result.enumerated()), id: \.offset) { _, v in
                            ZCLedgerRow("返回", v)
                        }
                    }
                    .padding(.bottom, 12)
                }

                Text("只读方法直接调用；非只读方法走交易确认路径（预览 → 签名 → 广播）。felt 参数用 hex。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
            }
        } footer: {}
    }
}

// MARK: - 16 交易记录 · 双边对账

struct ChainHistoryScreen: View {
    @EnvironmentObject var model: WalletModel
    @State private var seg = 0

    var body: some View {
        let chain = activeChain(model)
        let txs = chain == .evm ? model.evmTxs : model.stkTxs
        let filtered: [ChainTx] = seg == 0 ? txs : (seg == 1 ? txs.filter { $0.kind != "contract" } : txs.filter { $0.kind == "contract" })
        return ScreenScaffold {
            ZCSubHeader(title: "交易记录") {
                AnyView(ZCChip(chain == .evm ? "Ethereum" : "Starknet", tone: .neutral, xs: true))
            }
            ZCBody {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("合并 Explorer 数据")
                            .font(.ui(12, .semibold))
                            .foregroundColor(model.c.ink)
                        Text("本地账本 + Etherscan 兼容 txlist")
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(model.c.ink3)
                    }
                    Spacer(minLength: 6)
                    ZCSwitch(on: Binding(
                        get: { chain == .evm ? model.evmExplorerOn : false },
                        set: { model.evmExplorerOn = $0 }))
                }
                .padding(.bottom, 12)

                Text(model.evmExplorerOn
                     ? "已启用：本账户地址将作为查询参数发送给第三方 Explorer API。两者结果冲突时以链上回执为准，差异原样列在详情里，不做静默合并。"
                     : "未启用：仅展示本机账本记录，不向第三方发送地址。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.bottom, 12)

                ZCSegmented(items: ["全部", "转账", "合约"], selection: $seg)

                if filtered.isEmpty {
                    ZCEmptyBox(text: "暂无交易记录")
                        .padding(.bottom, 12)
                } else {
                    ZCCard(rowsStyle: true) {
                        ForEach(filtered) { t in
                            historyRow(t)
                        }
                    }
                    .padding(.bottom, 12)
                }

                ZCButton("重新对账", style: .secondary) {
                    model.showToast("本轮对账更新 0 笔待确认交易")
                }

                Text("来源用 chip 区分（本地 / explorer）；两者冲突时以链上回执为准，并把差异原样列在详情里，不做静默合并。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.top, 8)
            }
        } footer: {}
    }

    private func historyRow(_ t: ChainTx) -> some View {
        let chip = t.statusChip
        let isIn = t.direction == "in"
        let icon: ZCIconName = t.kind == "contract" ? .file : (isIn ? .recv : .send)
        let tone: ZCTxRow.IconTone = chip.1 == .felt ? .ok : chip.1 == .amb ? .warn : chip.1 == .bad ? .bad : .blue
        let amountText = t.kind == "contract"
            ? (t.status == "failed" ? "Failed" : "合约")
            : fmtSigned(t.valueHuman, positive: isIn, negative: !isIn)
        let amountTone: ZCAssetRow.AmountTone = t.kind == "contract" ? (t.status == "failed" ? .bad : .dim) : (isIn ? .pos : .neg)
        let sourceMark = t.source == "explorer" ? " · 链上" : " · 本地"
        return ZCTxRow(icon: icon, iconTone: tone,
                       name: "\(t.kind == "contract" ? (t.methodLabel ?? "合约调用") : (isIn ? "接收" : "发送")) · \(fmtAmount(t.valueHuman == "0" ? "0" : t.valueHuman))",
                       sub: "\(shortAddr(t.hash, 10, 2)) · \(relTime(t.createdAt))\(sourceMark)",
                       amount: amountText, amountTone: amountTone,
                       chip: (chip.0, chip.1))
    }
}

// MARK: - 17 账户管理 · 危险区

struct ChainManageScreen: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        let chain = activeChain(model)
        let layer = model.layer(chain)
        return ScreenScaffold {
            ZCSubHeader(title: "账户管理")
            ZCBody {
                ZCCard {
                    HStack(spacing: 12) {
                        Text("B")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(model.c.onInk)
                            .frame(width: 38, height: 38)
                            .background(model.c.ink)
                            .cornerRadius(ZCMetrics.chipCorner)
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 5) {
                                Text(layer.label ?? "账户 2")
                                    .font(.ui(13, .semibold))
                                    .foregroundColor(model.c.ink)
                                ZCChip(layer.unlocked ? "已解锁" : "已锁定", tone: layer.unlocked ? .felt : .amb, xs: true)
                            }
                            Text(layer.address ?? "—")
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(model.c.ink3)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding(.bottom, 4)

                ZCSectionTitle(text: "安全")
                ZCCard {
                    ZCMenuRow(icon: .key, title: "导出私钥",
                              sub: "口令确认后展开 · 展示后 30 秒自动收起",
                              action: { model.showToast("演示态：导出私钥需口令确认（fail-closed）") })
                    ZCMenuRow(icon: .pen, title: "修改口令",
                              sub: "本层 keystore 重派生（两套 KDF）",
                              action: { model.showToast("演示态：修改口令会重加密本层 keystore") })
                    ZCMenuRow(icon: .lock, title: "锁定",
                              sub: "立即清除内存中的会话",
                              action: {
                                  model.lockCurrent()
                                  model.showToast("\(chain.label) 层已锁定")
                                  model.go(.acct, chain: chain)
                              })
                }
                .padding(.bottom, 4)

                ZCSectionTitle(text: "网络")
                ZCCard {
                    ZCMenuRow(icon: .swap, title: "RPC 覆盖",
                              sub: chain == .evm ? "Ethereum · 默认 https://…" : "SN DevNet · 默认 https://…",
                              action: { model.overlay = .init(kind: .networkPicker) })
                    ZCMenuRow(icon: .ext, title: "Explorer API 覆盖",
                              sub: "Etherscan 兼容 · 已配置",
                              action: { model.showToast("演示态：Explorer API 覆盖保存后即时生效") })
                }
                .padding(.bottom, 4)

                ZCSectionTitle(text: "危险区", danger: true)
                ZCCard {
                    ZCMenuRow(icon: .trash, title: "删除账户",
                              sub: "需输入口令确认；导出私钥前请先备份",
                              danger: true,
                              action: { withAnimation(ZCAnim.std) { model.overlay = .init(kind: .removeAccount(chain)) } })
                }
                .padding(.bottom, 4)

                ZCFoot(text: "本机 keystore（本层）：PBKDF2-SHA256 600k + AES-256-GCM · 私钥只在内存会话，落盘仅密文 · 无云端副本")
            }
        } footer: {}
    }
}
