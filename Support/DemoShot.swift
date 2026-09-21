import SwiftUI
import AppKit
import CoreGraphics

// ============================================================================
// DemoShot — macOS 演示/验收辅助（#if os(macOS)，iOS 上整体不参与编译）。
//
// 环境变量 ZC_SHOT=<png 路径> 时：启动 2.5s 后把本进程窗口自截为 PNG 并退出。
// 进程捕获自己的窗口不需要「屏幕录制」权限，用于无 Xcode 环境下的渲染验收。
// ============================================================================

#if os(macOS)
enum DemoShot {
    static func maybeSchedule() {
        guard let path = ProcessInfo.processInfo.environment["ZC_SHOT"], !path.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            captureOwnWindow(to: path)
            NSApp.terminate(nil)
        }
    }

    private static func captureOwnWindow(to path: String) {
        let pid = getpid()
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return }
        for w in list {
            let ownerPID = w[kCGWindowOwnerPID as String] as? Int ?? -1
            let layer = w[kCGWindowLayer as String] as? Int ?? Int.min
            guard ownerPID == pid, layer == 0 else { continue }
            let wid = w[kCGWindowNumber as String] as? UInt32 ?? 0
            guard wid != 0,
                  let img = CGWindowListCreateImage(.null, .optionIncludingWindow, wid, [.bestResolution, .boundsIgnoreFraming]) else { continue }
            let rep = NSBitmapImageRep(cgImage: img)
            guard let data = rep.representation(using: .png, properties: [:]) else { continue }
            try? data.write(to: URL(fileURLWithPath: path))
            return
        }
    }
}
#endif
