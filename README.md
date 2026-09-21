# ZChain Wallet · iOS（原生 SwiftUI）

对齐 Pixso 设计文件「设计文件」（`wrfLcH3XiFpZsxMwj0DPkw`，页面 1 / frame `4:2`「html」，19 屏手机界面画廊）
与 `/Users/mac/projects/zchain/extension` 钱包插件（方向 B「账簿 / Ledger」v0.2）UI 的 **iOS 原生实现**。

**不是 WebView 套壳**：全部界面为 SwiftUI 原生绘制（含单线图标库 = Path 逐条移植设计稿 SVG symbol）；
零第三方依赖（二维码用系统 CoreImage `CIQRCodeGenerator` 原生生成，无需安装任何依赖）。

## 构建与运行

```bash
open ZChainWallet.xcodeproj        # Xcode 15+ / iOS 16+
# 选 ZChainWallet scheme → 任一 iPhone 模拟器 → Cmd+R
```

- Bundle id `dev.zchain.wallet.ios`，最低 iOS 16.0，iPhone 竖屏，Swift 5。
- 无 SPM / CocoaPods 依赖，无需 `pod install` 或任何依赖安装。

### 本机验证结果（已完成的编译级验证）

开发机（macOS 15.3.1）只有 Command Line Tools 且其工具链有 Apple 已知 bug
（`module.modulemap` 与 `bridging.modulemap` 重复定义 `SwiftBridging`，SwiftPM 同损）。
通过 clang **VFS overlay** 把重复 modulemap 映射为空文件绕过后，本仓库完成了：

- `./Tools/verify.sh type` → **swiftc -typecheck 全量类型检查 PASS（0 error，13 个源文件）**；
- **编译 + 链接**：`swiftc -o` 产出可执行文件成功（SwiftUI 全量编译 + 链接通过）；
- **运行时渲染验收**：以 macOS 演示构建（同一套 SwiftUI 源码，跨平台）把 **19 屏全部
  离屏渲染为 PNG**，与 Pixso 设计稿逐屏比对（颜色 token / 文案 / 数据 / 布局全部对应），
  截图归档于 [`docs/screenshots/`](docs/screenshots/)；
- 渲染中发现并修复的真实缺陷：`Decimal(string:)` 对千分位逗号静默截断（12,400 → 12）、
  fiat 未定 2 位小数、ZCRail 节点初始 opacity=0 永久不可见、首页凭证条笔触（wait/blocked
  语义）混用、分库金额缺小数位等。

`Tools/verify.sh` 用法：`type`（类型检查）/ `parse` / `build`（有 Xcode 时 xcodebuild 构建
iOS App）/ `shots`（19 屏渲染截图）。iOS 真机/模拟器运行仍需完整 Xcode（本机未装，
`sudo mv /Library/Developer/CommandLineTools/usr/include/swift/module.modulemap{,.bak}`
亦可修复 CLT 后用 `type` 模式）。

## 设计映射（Pixso 19 屏 ↔ iOS 屏幕）

| # | 设计稿 sid | 屏名 | 实现 |
|---|---|---|---|
| 01 | welcome | 欢迎 · 一次创建三层 | `Screens1_Guide.swift` WelcomeScreen |
| 02 | success | 创建成功 · 解锁口令 | SuccessScreen |
| 03 | import | 导入 / 恢复 | ImportScreen |
| 04 | lock | 锁定 · 统一解锁 | LockScreen |
| 05 | home | 三链总账（≈$22,288 总资产 / 三层账户 / 最弱凭证 / 待办） | `Screens2_HomeLedger.swift` HomeScreen |
| 06 | zc-dash | 账簿 · ZChain 层（GAME/REAL 分库 + 托管 banner + acts） | LedgerScreen + ZCPane |
| 07 | evm-dash | 账簿 · EVM 层（总余额 + 网络 + 资产） | EvmPane |
| 08 | stk-dash | 账簿 · Starknet 层 | StkPane |
| 09 | zc-send | 转账 · 贪心选币（300+200 proven 演示选币 + 凭证条） | `Screens3_ZChain.swift` ZCSendScreen |
| 10 | zc-withdraw | REAL 提现预览 · fail-closed（proven 画红 / 提交恒禁用） | ZCWithdrawScreen |
| 11 | zc-confirm | dapp 签名请求（开桌买入 -500.00 确认块 + 倒计时） | ZCConfirmScreen |
| 12 | zc-sessions | 会话密钥 · SNIP-12（活跃 + 已耗尽两卡） | ZCSessionsScreen |
| 13 | zc-portal | Proof Portal（四步验证 + 1.7s 如实标注 + 已验证印章） | ZCPortalScreen |
| 14 | zc-receipts | 回执状态机（signed→seen→included + ForceInclude 禁用） | ZCReceiptsScreen |
| 15 | evm-send | 发送 · 交易预览（EIP-155 / gas / 校验通过） | `Screens4_Chain.swift` ChainSendScreen |
| 16 | evm-history | 交易记录 · 双边对账（Explorer 开关 + 三分桶） | ChainHistoryScreen |
| 17 | evm-manage | 账户管理 · 危险区（导出/改口令/锁定/删除） | ChainManageScreen |
| 18 | proofs | 凭证簿（凭证分布 rail + 待复验 + 已复验） | `Screens5_ProofsSettings.swift` ProofsScreen |
| 19 | settings | 设置 · 能力矩阵（纸白/夜场切换 + 审计 banner） | SettingsScreen |

设计系统（`Theme/ZCTheme.swift`）：纸白 / 夜场双底色 token 与 `popup.css` 逐值一致
（`#F5F2EA` 页底、`#0B6B45` 绿毡、`#15507F` 蓝墨、`#7D5308` 金墨、`#A83226` 朱红、`#8A5A12` 琥珀…），
金额/哈希/地址一律等宽右对齐，账格纸纹、齿孔线、-4° 方形印章、凭证条四态笔触（done/cur/bad/空）
均为原生实现。屏幕注册表 / 导航 / 金额口径 / 凭证阶梯语义移植自 `common/ui_ledger.js`（`Components/ZCModel.swift`）。

## 交互（演示态，全部可走通）

- 欢迎页「一键创建钱包」→ 成功页口令 `felt-poker-verifiable-9x2a`（只显示一次 + 剪贴板风险警示）→ 总账；
- 账簿链切换（链=筛选器，三链同一模板换数据面）；收款 sheet 出**真二维码**（CoreImage）+ 完整地址；
- 转账：金额/owner → 生成预览（贪心选币、找零、守恒核对、签名摘要、凭证条）→ 确认 → 回执登记并跳转回执页；
- 提现：fail-closed —— 三条原因（含「本版本不会开放」策略标注），提交按钮恒虚线禁用；
- 签名请求：倒计时 chip、批准/拒绝（批准登记 signed 回执）；
- 会话密钥：撤销需**键入 REVOKE**（粘滞语义），删除记录；Portal：四步逐步推进（本地模拟 ~1.7s 验证），结论后落「已验证」印章；
- 设置：外观底面纸白 ↔ 夜场（同一套 token 两种底色）；能力矩阵模态。

## 诚实边界（与设计稿一致，不虚标）

- 行情为**演示价格源**（NATIVE $1.012 / ETH $3,360），设置页已注明；PLAY 不计价；
- REAL 提现 `canSubmit` 恒 false（托管 + finality 合取，UI 只消费）；跨域金额永不轧差；
- 回执 evidence 原样展示（未验签就写未验签；included 标注「本机手工登记，非链上证实」）；
- 钱包数据为内存演示态（devnet 口径），未接入真实链 / keystore——接入缝在 `WalletModel`
  （替换 `loadDemoState` 与预览/签名函数即可挂 wallet-core 移植层）。

## 目录

```
ZChainWallet.xcodeproj          Xcode 工程（手写 pbxproj，objectVersion 56）
ZChainWallet/
  ZChainWalletApp.swift         入口 + RootView + 屏幕骨架（票据抬头/子页栏/底部 tab）
  Theme/ZCTheme.swift           双底色 token、字体、账格纸纹、齿孔线
  Theme/ZCIcons.swift           40 个单线图标（SVG symbol → Path 逐条移植）+ ZChain logo
  Components/ZCComponents.swift 组件库（chip/印章/卡片/账簿行/凭证条/表单/开关…）
  Components/ZCModel.swift      屏幕注册表 + 导航 + 演示数据 + 纯逻辑（选币/阶梯/格式化）
  Components/ZCOverlays.swift   收款 / 账户切换 / 网络选择 / REVOKE 撤销 / 删除 / 能力矩阵
  Screens/Screens1_Guide.swift  01–04 引导四屏
  Screens/Screens2_HomeLedger.swift  05 总账 + 06–08 三链账簿
  Screens/Screens3_ZChain.swift 09–14 ZChain 六屏
  Screens/Screens4_Chain.swift  15–17 链层三屏 + 合约
  Screens/Screens5_ProofsSettings.swift  18 凭证簿 + 19 设置
  Support/ZCQRCode.swift        原生二维码（CoreImage）
Tools/verify.sh                 无 Xcode 环境下的类型检查脚本（见脚本内说明）
```
