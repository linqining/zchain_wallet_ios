#!/usr/bin/env bash
# ============================================================================
# verify.sh — ZChain Wallet iOS 源码验证脚本。
#
# 背景：开发机只有 Command Line Tools，且其工具链存在 Apple 已知 bug：
#   /Library/Developer/CommandLineTools/usr/include/swift/ 下 module.modulemap
#   与 bridging.modulemap 同时定义 module SwiftBridging → clang 报
#   "redefinition of module 'SwiftBridging'"（连 SwiftPM 也因此无法构建）。
# 本脚本用 clang VFS overlay 把重复的 module.modulemap 映射为空文件绕过，
# 从而在无 Xcode 的机器上完成 **swiftc -typecheck 全量类型检查**。
#
# 用法：
#   ./Tools/verify.sh type    # 全量类型检查（本机已 PASS：0 error）
#   ./Tools/verify.sh parse   # 仅语法检查
#   ./Tools/verify.sh build   # 有 Xcode 时 xcodebuild 真实构建 iOS App
#   ./Tools/verify.sh shots   # macOS 演示构建 + 19 屏离屏渲染截图（docs/screenshots）
# ============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

FILES=$(find ZChainWallet -name '*.swift' | sort)
SHIM="Tools/clt-shim/hide.yaml"

case "${1:-type}" in
  parse)
    swiftc -parse $FILES && echo "PARSE PASS"
    ;;
  type)
    swiftc -vfsoverlay "$SHIM" -typecheck -module-cache-path /tmp/zc-mcache $FILES \
      && echo "TYPECHECK PASS (0 errors)"
    ;;
  build)
    xcodebuild -project ZChainWallet.xcodeproj -scheme ZChainWallet \
      -destination 'generic/platform=iOS Simulator' -configuration Debug build \
      && echo "XCODEBUILD PASS"
    ;;
  shots)
    OUT=/tmp/zcbuild
    mkdir -p "$OUT" "docs/screenshots"
    swiftc -vfsoverlay "$SHIM" -module-cache-path /tmp/zc-mcache \
      -o "$OUT/ZChainWallet.app/Contents/MacOS/ZChainWallet" $FILES
    BIN="$OUT/ZChainWallet.app/Contents/MacOS/ZChainWallet"
    shot() { # shot <ZC_SCREEN> <ZC_CHAIN> <ZC_HEIGHT> <输出名>
      env ZC_SCREEN="$1" ZC_CHAIN="$2" ZC_HEIGHT="$3" ZC_SHOT="$OUT/tmp.png" \
        timeout 25 "$BIN" 2>/dev/null
      cp "$OUT/tmp.png" "docs/screenshots/$4.png"
      echo "  ✓ $4"
    }
    shot welcome zc 844   01-welcome
    shot success zc 844   02-success
    shot importScreen zc 1000 03-import
    shot lock zc 844      04-lock
    shot home zc 844      05-home
    shot acct zc 844      06-zc-dash
    shot acct evm 1500    07-evm-dash
    shot acct stk 1400    08-stk-dash
    shot zc-send zc 1300  09-zc-send
    shot zc-withdraw zc 1500 10-zc-withdraw
    shot zc-confirm zc 1700  11-zc-confirm
    shot zc-sessions zc 1500 12-zc-sessions
    shot zc-portal zc 1400   13-zc-portal
    shot zc-receipts zc 1700 14-zc-receipts
    shot send evm 1200    15-evm-send
    shot history evm 1300 16-evm-history
    shot manage evm 1300  17-evm-manage
    shot proofs zc 1400   18-proofs
    shot settings zc 1400 19-settings
    echo "SHOTS DONE → docs/screenshots/"
    ;;
  *)
    echo "usage: $0 {type|parse|build|shots}"; exit 2;;
esac
