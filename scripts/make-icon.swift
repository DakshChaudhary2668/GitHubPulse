// Run from the repository root: swift scripts/make-icon.swift
import AppKit
import Foundation

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
let iconset = temporary.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: temporary) }
let pulse: Set<String> = ["0,2", "1,2", "2,2", "2,3", "2,4", "3,0", "3,1", "3,2", "4,2", "5,2", "6,2"]
func render(_ pixels: Int) throws -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    color(0x060707).setFill()
    NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 200, yRadius: 200).fill()
    for column in 0..<7 {
        for row in 0..<5 {
            let active = pulse.contains("\(column),\(row)")
            color(active ? 0x24c84d : 0x18241d).setFill()
            let rect = NSRect(x: 206 + column * 90, y: 296 + row * 90, width: 72, height: 72)
            NSBezierPath(roundedRect: rect, xRadius: 14, yRadius: 14).fill()
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)" + (scale == 2 ? "@2x" : "") + ".png"
        try render(points * scale).write(to: iconset.appendingPathComponent(name))
    }
}
try FileManager.default.createDirectory(at: root.appendingPathComponent("Sources/Resources"), withIntermediateDirectories: true)
try render(512).write(to: root.appendingPathComponent("docs/app-icon.png"))
let process = Process(); process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Sources/Resources/AppIcon.icns").path]
try process.run(); process.waitUntilExit()
guard process.terminationStatus == 0 else { fatalError("iconutil failed") }
print("Generated AppIcon.icns and README preview")
