// Run from the repository root: swift scripts/make-icon.swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
let iconset = temporary.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: temporary) }
guard let image = NSImage(contentsOf: root.appendingPathComponent("docs/app-icon.png")) else {
    fatalError("Missing reference artwork at docs/app-icon.png")
}
func render(_ pixels: Int) throws -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    context.imageInterpolation = .high
    image.draw(in: NSRect(x: -72, y: -72, width: 1168, height: 1168), from: .zero, operation: .copy, fraction: 1)
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
let process = Process(); process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Sources/Resources/AppIcon.icns").path]
try process.run(); process.waitUntilExit()
guard process.terminationStatus == 0 else { fatalError("iconutil failed") }
print("Generated AppIcon.icns from the supplied reference artwork")
