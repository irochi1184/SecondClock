import AppKit

private let canvasWidth = 2868
private let canvasHeight = 1320
private let canvasSize = NSSize(width: canvasWidth, height: canvasHeight)

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}

private struct Copy {
    let eyebrow: String
    let headline: String
    let subheadline: String
}

private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
private let raw = root.appendingPathComponent("AppStore/Screenshots/Raw")
private let outputJA = root.appendingPathComponent("AppStore/Screenshots/Final-ja")
private let outputEN = root.appendingPathComponent("AppStore/Screenshots/Final-en")
private let concepts = root.appendingPathComponent("AppStore/Screenshots/Concepts")
private let review = root.appendingPathComponent("AppStore/Review")

private func image(_ name: String) -> NSImage {
    guard let value = NSImage(contentsOf: raw.appendingPathComponent(name)) else {
        fatalError("Missing source image: \(name)")
    }
    return value
}

private func yFromTop(_ top: CGFloat, height: CGFloat) -> CGFloat {
    CGFloat(canvasHeight) - top - height
}

private func drawBackground() {
    let rect = NSRect(origin: .zero, size: canvasSize)
    NSGradient(colors: [
        NSColor(hex: 0x061a2a),
        NSColor(hex: 0x064d53),
        NSColor(hex: 0x0aa875)
    ])?.draw(in: rect, angle: 12)

    let emeraldGlow = NSBezierPath(ovalIn: NSRect(x: 1950, y: 520, width: 1080, height: 1080))
    NSColor(hex: 0x36e39d).withAlphaComponent(0.12).setFill()
    emeraldGlow.fill()

    let orangeGlow = NSBezierPath(ovalIn: NSRect(x: -300, y: -280, width: 840, height: 840))
    NSColor(hex: 0xff7a16).withAlphaComponent(0.13).setFill()
    orangeGlow.fill()
}

private func drawText(
    _ string: String,
    x: CGFloat,
    top: CGFloat,
    width: CGFloat,
    height: CGFloat,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor = .white,
    alignment: NSTextAlignment = .left,
    lineSpacing: CGFloat = 8
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineSpacing = lineSpacing
    paragraph.lineBreakMode = .byWordWrapping
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSString(string: string).draw(
        in: NSRect(x: x, y: yFromTop(top, height: height), width: width, height: height),
        withAttributes: attributes
    )
}

private func drawPill(_ string: String, x: CGFloat, top: CGFloat, width: CGFloat) {
    let height: CGFloat = 72
    let rect = NSRect(x: x, y: yFromTop(top, height: height), width: width, height: height)
    let path = NSBezierPath(roundedRect: rect, xRadius: 36, yRadius: 36)
    NSColor.white.withAlphaComponent(0.13).setFill()
    path.fill()
    NSColor.white.withAlphaComponent(0.18).setStroke()
    path.lineWidth = 2
    path.stroke()
    drawText(
        string,
        x: x,
        top: top + 15,
        width: width,
        height: 44,
        size: 29,
        weight: .semibold,
        alignment: .center
    )
}

private func drawScreen(
    _ source: NSImage,
    x: CGFloat,
    top: CGFloat,
    width: CGFloat,
    radius: CGFloat = 56,
    border: CGFloat = 8
) {
    let height = width * source.size.height / source.size.width
    let rect = NSRect(x: x, y: yFromTop(top, height: height), width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.38)
    shadow.shadowBlurRadius = 38
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    shadow.set()
    NSColor.black.withAlphaComponent(0.9).setFill()
    NSBezierPath(
        roundedRect: rect.insetBy(dx: -border, dy: -border),
        xRadius: radius + border,
        yRadius: radius + border
    ).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    source.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}

private func makePNG(at url: URL, draw: () -> Void) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: canvasWidth,
        pixelsHigh: canvasHeight,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: canvasWidth * 4,
        bitsPerPixel: 32
    ) else {
        fatalError("Unable to create bitmap")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()

    guard let sourceImage = rep.cgImage,
          let context = CGContext(
            data: nil,
            width: canvasWidth,
            height: canvasHeight,
            bitsPerComponent: 8,
            bytesPerRow: canvasWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
          ) else {
        fatalError("Unable to flatten bitmap")
    }
    context.draw(sourceImage, in: CGRect(origin: .zero, size: canvasSize))
    guard let flattenedImage = context.makeImage() else {
        fatalError("Unable to flatten image")
    }
    let flattenedRep = NSBitmapImageRep(cgImage: flattenedImage)
    guard let data = flattenedRep.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    try! data.write(to: url)
}

private func makeFeature(
    _ copy: Copy,
    source: NSImage,
    pills: [String],
    output: URL
) {
    makePNG(at: output) {
        drawBackground()
        drawText(copy.eyebrow, x: 120, top: 115, width: 820, height: 44, size: 27, weight: .bold, color: NSColor(hex: 0xff8a2b))
        drawText(copy.headline, x: 120, top: 200, width: 830, height: 300, size: 92, weight: .bold, lineSpacing: 15)
        drawText(copy.subheadline, x: 120, top: 540, width: 820, height: 150, size: 40, weight: .medium, color: .white.withAlphaComponent(0.78), lineSpacing: 10)
        for (index, pill) in pills.enumerated() {
            drawPill(
                pill,
                x: 120 + CGFloat(index % 2) * 365,
                top: 830 + CGFloat(index / 2) * 94,
                width: 340
            )
        }
        drawScreen(source, x: 1035, top: 235, width: 1710)
    }
}

private func makeCustomize(_ copy: Copy, output: URL) {
    makePNG(at: output) {
        drawBackground()
        drawText(copy.eyebrow, x: 120, top: 105, width: 820, height: 44, size: 27, weight: .bold, color: NSColor(hex: 0xff8a2b))
        drawText(copy.headline, x: 120, top: 190, width: 820, height: 300, size: 88, weight: .bold, lineSpacing: 14)
        drawText(copy.subheadline, x: 120, top: 520, width: 810, height: 160, size: 39, weight: .medium, color: .white.withAlphaComponent(0.78), lineSpacing: 10)
        drawPill("SIZE", x: 120, top: 820, width: 245)
        drawPill("FONT", x: 390, top: 820, width: 245)
        drawPill("COLOR", x: 660, top: 820, width: 245)
        drawScreen(image("03-settings.png"), x: 1030, top: 85, width: 505, radius: 60, border: 7)
        drawScreen(image("01-clock-aurora-landscape.png"), x: 1605, top: 285, width: 1120, radius: 48, border: 7)
        drawText("PREVIEW", x: 1605, top: 850, width: 1120, height: 44, size: 27, weight: .bold, color: .white.withAlphaComponent(0.66), alignment: .center)
    }
}

private func makeBackgrounds(
    _ copy: Copy,
    feature: String,
    disclaimer: String,
    output: URL
) {
    makePNG(at: output) {
        drawBackground()
        drawText(copy.eyebrow, x: 120, top: 105, width: 820, height: 44, size: 27, weight: .bold, color: NSColor(hex: 0xff8a2b))
        drawText(copy.headline, x: 120, top: 190, width: 820, height: 300, size: 88, weight: .bold, lineSpacing: 14)
        drawText(copy.subheadline, x: 120, top: 520, width: 810, height: 150, size: 39, weight: .medium, color: .white.withAlphaComponent(0.78), lineSpacing: 10)
        drawText(feature, x: 120, top: 800, width: 820, height: 100, size: 43, weight: .bold)
        drawText(disclaimer, x: 120, top: 1005, width: 820, height: 110, size: 25, weight: .regular, color: .white.withAlphaComponent(0.62), lineSpacing: 8)

        drawScreen(image("01-clock-aurora-landscape.png"), x: 1025, top: 155, width: 820, radius: 42, border: 7)
        drawText("AURORA", x: 1025, top: 570, width: 820, height: 44, size: 26, weight: .bold, color: .white.withAlphaComponent(0.72), alignment: .center)
        drawScreen(image("02-clock-ocean-landscape.png"), x: 1930, top: 155, width: 820, radius: 42, border: 7)
        drawText("OCEAN", x: 1930, top: 570, width: 820, height: 44, size: 26, weight: .bold, color: .white.withAlphaComponent(0.72), alignment: .center)

        drawPill("SOLID", x: 1080, top: 830, width: 350)
        drawPill("GRADIENT", x: 1470, top: 830, width: 420)
        drawPill("PHOTO", x: 1930, top: 830, width: 350)
        drawPill("5 THEMES", x: 2320, top: 830, width: 380)
    }
}

private func makeIAPReview(output: URL) {
    makePNG(at: output) {
        drawBackground()
        drawText("APP REVIEW", x: 120, top: 105, width: 820, height: 44, size: 27, weight: .bold, color: NSColor(hex: 0xff8a2b))
        drawText("SecondClock Pro", x: 120, top: 190, width: 820, height: 120, size: 78, weight: .bold)
        drawText("設定画面から表示される、\n買い切りのアップグレード画面です。", x: 120, top: 370, width: 820, height: 150, size: 38, weight: .medium, color: .white.withAlphaComponent(0.78), lineSpacing: 10)
        drawPill("LIFETIME", x: 120, top: 675, width: 320)
        drawPill("NON-CONSUMABLE", x: 470, top: 675, width: 430)
        drawText("Product ID", x: 120, top: 900, width: 820, height: 40, size: 25, weight: .bold, color: .white.withAlphaComponent(0.62))
        drawText("com.irochi.SecondClock.pro.lifetime", x: 120, top: 955, width: 820, height: 70, size: 27, weight: .medium)
        drawScreen(image("04-paywall.png"), x: 1110, top: 70, width: 500, radius: 58, border: 7)
        drawText("購入画面", x: 1710, top: 300, width: 900, height: 80, size: 62, weight: .bold)
        drawText("写真背景・暗さ調整・限定テーマを\n一度の購入で解放します。", x: 1710, top: 430, width: 940, height: 150, size: 36, weight: .medium, color: .white.withAlphaComponent(0.78), lineSpacing: 10)
        drawPill("写真背景", x: 1710, top: 710, width: 300)
        drawPill("暗さ調整", x: 2040, top: 710, width: 300)
        drawPill("限定テーマ", x: 2370, top: 710, width: 330)
    }
}

try! FileManager.default.createDirectory(at: outputJA, withIntermediateDirectories: true)
try! FileManager.default.createDirectory(at: outputEN, withIntermediateDirectories: true)
try! FileManager.default.createDirectory(at: concepts, withIntermediateDirectories: true)
try! FileManager.default.createDirectory(at: review, withIntermediateDirectories: true)

makeFeature(
    Copy(
        eyebrow: "SECOND CLOCK",
        headline: "秒まで、\n美しく見える。",
        subheadline: "開いた瞬間、全画面の時計。\n横向きなら離れていても見やすい。"
    ),
    source: image("01-clock-aurora-landscape.png"),
    pills: ["秒表示", "全画面", "横向き", "自動保存"],
    output: outputJA.appendingPathComponent("01-fullscreen-clock.png")
)
makeFeature(
    Copy(
        eyebrow: "LANDSCAPE READY",
        headline: "横向きでも、\nひと目で時刻。",
        subheadline: "デスクやベッドサイドに。\n秒まで大きく、くっきり。"
    ),
    source: image("02-clock-ocean-landscape.png"),
    pills: ["デスク", "ベッドサイド", "24時間表示", "日付表示"],
    output: outputJA.appendingPathComponent("02-landscape.png")
)
makeCustomize(
    Copy(
        eyebrow: "CUSTOMIZE",
        headline: "サイズも書体も、\n思いのまま。",
        subheadline: "見やすさと雰囲気を、\n自分にちょうどよく整えられます。"
    ),
    output: outputJA.appendingPathComponent("03-customize.png")
)
makeBackgrounds(
    Copy(
        eyebrow: "YOUR CLOCK",
        headline: "色も背景も、\n空間に合わせて。",
        subheadline: "気分やインテリアに似合う、\n自分だけの時計へ。"
    ),
    feature: "単色・グラデーション・写真背景",
    disclaimer: "※一部の背景・配色・写真機能はSecondClock Proで利用できます。",
    output: outputJA.appendingPathComponent("04-backgrounds.png")
)

makeFeature(
    Copy(
        eyebrow: "SECOND CLOCK",
        headline: "See every\nsecond.",
        subheadline: "A full-screen clock from launch.\nClear and readable in landscape."
    ),
    source: image("01-clock-aurora-landscape.png"),
    pills: ["SECONDS", "FULL SCREEN", "LANDSCAPE", "AUTO SAVE"],
    output: outputEN.appendingPathComponent("01-fullscreen-clock.png")
)
makeFeature(
    Copy(
        eyebrow: "LANDSCAPE READY",
        headline: "Made for\nlandscape.",
        subheadline: "Perfect for your desk or bedside.\nSee every second across the room."
    ),
    source: image("02-clock-ocean-landscape.png"),
    pills: ["DESK", "BEDSIDE", "24-HOUR", "DATE"],
    output: outputEN.appendingPathComponent("02-landscape.png")
)
makeCustomize(
    Copy(
        eyebrow: "CUSTOMIZE",
        headline: "Size and style,\nyour way.",
        subheadline: "Tune the clock for the look\nand readability you want."
    ),
    output: outputEN.appendingPathComponent("03-customize.png")
)
makeBackgrounds(
    Copy(
        eyebrow: "YOUR CLOCK",
        headline: "Colors for\nevery space.",
        subheadline: "Choose a look that fits\nyour room and mood."
    ),
    feature: "Solid colors, gradients & photos",
    disclaimer: "Some backgrounds, colors and photo features require SecondClock Pro.",
    output: outputEN.appendingPathComponent("04-backgrounds.png")
)

makeFeature(
    Copy(
        eyebrow: "SECOND CLOCK",
        headline: "秒まで、\n美しく見える。",
        subheadline: "横向き専用のApp Store掲載デザイン。"
    ),
    source: image("01-clock-aurora-landscape.png"),
    pills: ["秒表示", "全画面", "横向き", "カスタマイズ"],
    output: concepts.appendingPathComponent("concept-a-editorial-dark-landscape.png")
)

makeIAPReview(output: review.appendingPathComponent("iap-review.png"))

print("Generated landscape App Store screenshot sets and IAP review image")
