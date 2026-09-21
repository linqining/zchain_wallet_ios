import SwiftUI
import AppKit

// ============================================================================
// DemoShot — macOS 演示/验收辅助（#if os(macOS)，iOS 上整体不参与编译）。
//
// 环境变量 ZC_SHOT=<png 路径> 时：RootView 出现后用 ImageRenderer 把当前屏幕
// 离屏渲染为 2x PNG 并退出进程。不需要窗口与「屏幕录制」权限，
// 用于无 Xcode 环境下的逐屏渲染验收。
// ============================================================================

#if os(macOS)
@MainActor
enum DemoShot {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["ZC_SHOT"] != nil
    }

    /// 渲染高度（ZC_HEIGHT 覆盖默认 844；可截全内容长图）。
    static var renderHeight: CGFloat {
        CGFloat(ProcessInfo.processInfo.environment["ZC_HEIGHT"].flatMap(Double.init) ?? 844)
    }

    static func renderAndExit(model: WalletModel) {
        guard let path = ProcessInfo.processInfo.environment["ZC_SHOT"], !path.isEmpty else { return }
        // ZC_THEN=back：渲染前模拟一次「返回」，用于验证屏幕注册表的 parent/back 链。
        if ProcessInfo.processInfo.environment["ZC_THEN"] == "back" {
            model.back()
        }
        let view = RootView().environmentObject(model)
        let renderer = ImageRenderer(content: AnyView(view))
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: 390, height: renderHeight)
        guard let cg = renderer.cgImage else {
            FileHandle.standardError.write(Data("DemoShot: render failed\n".utf8))
            exit(3)
        }
        let rep = NSBitmapImageRep(cgImage: cg)
        guard let data = rep.representation(using: .png, properties: [:]) else { exit(4) }
        do {
            try data.write(to: URL(fileURLWithPath: path))
        } catch {
            FileHandle.standardError.write(Data("DemoShot: write failed \(error)\n".utf8))
            exit(5)
        }
        exit(0)
    }
}
#endif
