import SwiftUI

// ============================================================================
// ZCOverlays — 底部抽屉（sheet）与模态（modal）：收款 / 账户切换 / 网络选择 /
// 撤销会话密钥（REVOKE 键入门槛）/ 删除账户（DELETE）/ 能力矩阵。
// ============================================================================

/// 抽屉外壳（grab 条 + 标题 + 关闭）。
struct SheetShell<Content: View>: View {
    @EnvironmentObject var model: WalletModel
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(model.c.rl2)
                .frame(width: 34, height: 3)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
            HStack(spacing: 8) {
                Text(title)
                    .font(.ui(13, .semibold))
                    .foregroundColor(model.c.ink)
                Spacer(minLength: 4)
                ZCIconBtn(icon: .x, bare: true) {
                    withAnimation(ZCAnim.out) { model.overlay = nil }
                }
            }
            .padding(.bottom, 8)
            content()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(model.c.pg)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: ZCMetrics.cornerL, topTrailingRadius: ZCMetrics.cornerL))
        .overlay(UnevenRoundedRectangle(topLeadingRadius: ZCMetrics.cornerL, topTrailingRadius: ZCMetrics.cornerL).stroke(model.c.ink, lineWidth: 1))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// 模态外壳（居中卡片）。
struct ModalShell<Content: View>: View {
    @EnvironmentObject var model: WalletModel
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(model.c.ink)
                .padding(.bottom, 6)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(model.c.pg)
        .cornerRadius(ZCMetrics.corner)
        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.corner).stroke(model.c.ink, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.28), radius: 25, x: 0, y: 9)
        .padding(20)
        .transition(.scale(scale: 0.96).combined(with: .opacity))
    }
}

// MARK: - 收款（真二维码 + 完整地址）

struct ReceiveSheet: View {
    @EnvironmentObject var model: WalletModel
    let chain: Chain

    var body: some View {
        SheetShell(title: "收款 · \(chain.label) 层") {
            let addr = model.layer(chain).address ?? "—"
            VStack(alignment: .leading, spacing: 10) {
                Text(subtitle)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                ZCQRCard(text: addr)
                    .frame(maxWidth: .infinity)
                ZCPassBox(text: addr, copyKind: .address)
                ZCBanner(kind: .info, title: "收款请核对完整地址",
                         body_: "二维码由系统 CoreImage（CIQRCodeGenerator，纠错级 M）生成；转账前请以完整地址逐字核对，资产类网络转错不可撤回。")
            }
        }
    }

    private var subtitle: String {
        switch chain {
        case .zc: return "zchain-devnet-1 · 公钥即 owner（hex33 压缩公钥）"
        case .evm: return "Ethereum · chainId 1"
        case .stk: return "SN DevNet · ZCDN"
        }
    }
}

// MARK: - 账户切换

struct AccountSwitchSheet: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        SheetShell(title: "\(model.chain.label) 账户切换") {
            VStack(alignment: .leading, spacing: 0) {
                accountRow(label: model.walletLabel, addr: model.layer(model.chain).address ?? "（解锁后可见）", active: true, unlocked: model.layer(model.chain).unlocked)
                accountRow(label: "账户 2", addr: "0x59195049a3…29f97527", active: model.chain == .evm, unlocked: model.layer(.evm).unlocked)
                ZCButton("新建 / 导入账户", style: .secondary) { model.go(.importScreen) }
                    .padding(.top, 12)
                Text(model.chain == .zc
                     ? "切换账户会锁定当前 ZChain 会话（单槽）；其他账户的密文互不影响。"
                     : "切换即锁定本层会话，目标账户需口令解锁。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.top, 8)
            }
        }
    }

    private func accountRow(label: String, addr: String, active: Bool, unlocked: Bool) -> some View {
        HStack(spacing: 10) {
            Text(String(label.prefix(1)).uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(model.c.onInk)
                .frame(width: 30, height: 30)
                .background(model.c.ink)
                .cornerRadius(ZCMetrics.chipCorner)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.ui(12.5, .semibold))
                        .foregroundColor(model.c.ink)
                    if active { ZCChip("当前", tone: .felt, xs: true) }
                }
                Text(shortAddr(addr))
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(model.c.ink3)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            ZCChip(unlocked ? "已解锁" : "锁定中", tone: unlocked ? .felt : .amb, xs: true)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(model.c.rl).frame(height: 1) }
    }
}

// MARK: - 网络选择（封闭注册表；mainnet 刻意不在 ZChain 层）

struct NetworkPickerSheet: View {
    @EnvironmentObject var model: WalletModel

    var body: some View {
        SheetShell(title: "\(model.chain.label) 网络") {
            VStack(alignment: .leading, spacing: 0) {
                switch model.chain {
                case .zc:
                    netRow(name: "开发网（本地）", sub: "zchain-devnet-1", current: true)
                    netRow(name: "测试网", sub: "zchain-testnet-1（未配置网关，如实 null）", current: false, disabled: true)
                case .evm:
                    netRow(name: "Ethereum", sub: "chainId 0x1", current: true)
                    netRow(name: "Sepolia", sub: "chainId 0xaa36a7", current: false)
                    netRow(name: "Base", sub: "chainId 0x2105", current: false)
                    netRow(name: "Arbitrum One", sub: "chainId 0xa4b1", current: false)
                case .stk:
                    netRow(name: "SN DevNet", sub: "ZCDN", current: true)
                    netRow(name: "Starknet Sepolia", sub: "SN_SEPOLIA", current: false)
                }
                Text(model.chain == .zc
                     ? "mainnet 不在注册表内：跨网请求一律 NetworkUnsupported，不隐藏、不放行。"
                     : "切换即改 RPC 与 explorer 口径；RPC 返回的 chainId 与预设不符时如实告警，不静默继续。")
                    .font(.ui(10.5))
                    .foregroundColor(model.c.ink3)
                    .lineSpacing(2)
                    .padding(.top, 8)
            }
        }
    }

    private func netRow(name: String, sub: String, current: Bool, disabled: Bool = false) -> some View {
        ZCMenuRow(icon: current ? .check : .swap,
                  title: name,
                  sub: sub + (current ? " · 当前" : ""),
                  right: current ? .chip("当前", .felt) : .chevron,
                  action: {
                      if disabled {
                          model.showToast("该网络未配置网关（如实展示，不伪造可用）")
                      } else {
                          withAnimation(ZCAnim.out) { model.overlay = nil }
                          model.showToast("网络已切换")
                      }
                  })
    }
}

// MARK: - 撤销会话密钥（键入 REVOKE 门槛）

struct RevokeModal: View {
    @EnvironmentObject var model: WalletModel
    let binding: SessionBinding
    @State private var typed = ""

    var body: some View {
        ModalShell(title: "撤销该 origin 的会话密钥？") {
            Text("目标 origin：\(binding.origin)")
                .font(.ui(11.5))
                .foregroundColor(model.c.ink2)
                .padding(.bottom, 10)
            ZCBanner(kind: .bad, title: "撤销立即生效，且不可在本会话恢复",
                     body_: "该委托密钥立即失效；该 origin 本会话永久失效；此后它的每次签名都需重新输入口令。")
            Text("只影响该 origin 的委托密钥，不动主密钥，也不影响其他站点的授权。")
                .font(.ui(11.5))
                .foregroundColor(model.c.ink2)
                .padding(.bottom, 8)
            ZCInput(placeholder: "键入 REVOKE 以确认", text: $typed, mono: true)
            HStack(spacing: 9) {
                ZCButton("取消", style: .ghost) {
                    withAnimation(ZCAnim.out) { model.overlay = nil }
                }
                ZCButton("确认撤销", style: .danger,
                         disabled: typed.trimmingCharacters(in: .whitespaces).uppercased() != "REVOKE") {
                    model.revokeSession(binding)
                    withAnimation(ZCAnim.out) { model.overlay = nil }
                }
            }
            .padding(.top, 12)
            Text("注：当前授权为本机登记（evidence=devnet_local_entry），链上 admission 未接线；撤销同样只作用于本机登记表。")
                .font(.ui(10.5))
                .foregroundColor(model.c.ink3)
                .lineSpacing(2)
                .padding(.top, 8)
        }
    }
}

// MARK: - 删除账户（键入 DELETE）

struct RemoveAccountModal: View {
    @EnvironmentObject var model: WalletModel
    let chain: Chain
    @State private var typed = ""

    var body: some View {
        ModalShell(title: "删除 \(chain.label) 账户？") {
            Text("该账户的私钥将从本机 keystore 永久移除。若没有备份，资产无法找回。此操作与其他两层无关。")
                .font(.ui(11.5))
                .foregroundColor(model.c.ink2)
                .lineSpacing(2)
                .padding(.bottom, 8)
            ZCInput(placeholder: "输入 DELETE 以确认", text: $typed, mono: true)
            HStack(spacing: 9) {
                ZCButton("取消", style: .ghost) {
                    withAnimation(ZCAnim.out) { model.overlay = nil }
                }
                ZCButton("确认删除", style: .danger,
                         disabled: typed.trimmingCharacters(in: .whitespaces).uppercased() != "DELETE") {
                    withAnimation(ZCAnim.out) { model.overlay = nil }
                    model.showToast("演示态：账户删除已拦截（真实实现需 wallet-core keystore）")
                }
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - 能力矩阵（逐层能力与红线）

struct CapabilityMatrixModal: View {
    @EnvironmentObject var model: WalletModel

    private let rows: [(layer: String, can: String, cannot: String)] = [
        ("ZChain", "PLAY note 转账 / 买入 / 结算签名；REAL 分库只读展示；回执状态机与凭证阶梯；SNIP-12 会话密钥授权与限额", "REAL 提现提交恒禁用（fail-closed）；mainnet 刻意不在注册表内；私钥/note 明文不出边界"),
        ("EVM", "余额 / nonce / gas 查询；合约读（eth_call）与写（EIP-155 签名广播）；交易记录（本地账本 + explorer 合并）", "不冒充 EIP-1193 注入；eth_sign / eth_sendTransaction 等签名方法默认全拒"),
        ("Starknet", "STARK curve 账户；余额查询；invoke v1 签名广播；UDC 公式地址推导", "v3 交易（Poseidon/BLAKE2s）未交付；typed-data rev1 归 wallet-core 单实现"),
        ("Proof", "结算明细拉取；STARK 证明本地完整验证（stwo）；wallet-core 复验；两级结论独立不合并", "网关水位只原样展示不推进；超 500ms 如实标注；无归档证明时如实跳过"),
    ]

    var body: some View {
        ModalShell(title: "能力矩阵") {
            Text("逐层能力与红线，按交付面如实列举；不为好看放宽。")
                .font(.ui(11.5))
                .foregroundColor(model.c.ink2)
                .padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            ZCChip(row.layer, tone: .felt, xs: true)
                            Text(row.can)
                                .font(.ui(11.5))
                                .foregroundColor(model.c.ink2)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text("不具备 / 红线：\(row.cannot)")
                            .font(.ui(10.5))
                            .foregroundColor(model.c.ink3)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }
            ZCButton("知道了") {
                withAnimation(ZCAnim.out) { model.overlay = nil }
            }
            .padding(.top, 14)
        }
    }
}
