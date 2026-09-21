import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// ============================================================================
// ZCQRCode — 原生二维码生成（CoreImage，无第三方依赖）。
// 设计稿立场：扩展版因「无经验证的 QR 编码器」不画码；iOS 平台自带经过验证的
// CIQRCodeGenerator，因此收款页可以给出真码 + 完整地址核对。
// ============================================================================

#if canImport(UIKit)
typealias ZCPlatformImage = UIImage
#else
typealias ZCPlatformImage = NSImage
#endif

enum ZCQRCode {
    /// 生成二维码位图（纠错级 M）。
    static func image(text: String, scale: CGFloat = 6) -> ZCPlatformImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cg = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        #if canImport(UIKit)
        return UIImage(cgImage: cg)
        #else
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        #endif
    }
}

/// 收款卡（.qr 白底码块）。
struct ZCQRCard: View {
    @EnvironmentObject var model: WalletModel
    let text: String

    var body: some View {
        Group {
            if let img = ZCQRCode.image(text: text) {
                platformImage(img)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("二维码生成失败")
                    .font(.ui(11))
                    .foregroundColor(model.c.ink3)
            }
        }
        .frame(width: 150, height: 150)
        .padding(8)
        .background(Color.white)
        .cornerRadius(ZCMetrics.chipCorner)
        .overlay(RoundedRectangle(cornerRadius: ZCMetrics.chipCorner).stroke(model.c.rl2, lineWidth: 1))
    }

    private func platformImage(_ img: ZCPlatformImage) -> Image {
        #if canImport(UIKit)
        Image(uiImage: img)
        #else
        Image(nsImage: img)
        #endif
    }
}
