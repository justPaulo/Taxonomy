import AppKit
import Foundation

enum PackagingError: LocalizedError {
    case usage
    case missingExecutable(String)
    case invalidIcon
    case commandFailed(String, Int32, String)
    case invalidPlist

    var errorDescription: String? {
        switch self {
        case .usage:
            "Usage: package-app.swift <executable> <app-bundle-path>"
        case .missingExecutable(let path):
            "The release executable was not found at \(path)."
        case .invalidIcon:
            "Could not render the application icon."
        case .commandFailed(let command, let status, let output):
            "\(command) failed with status \(status): \(output)"
        case .invalidPlist:
            "Could not create a valid application Info.plist."
        }
    }
}

func run(_ executable: String, arguments: [String]) throws {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = output
    process.standardError = output
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let message = String(data: data, encoding: .utf8) ?? ""
        throw PackagingError.commandFailed(executable, process.terminationStatus, message)
    }
}

func drawIcon(size: Int, to url: URL) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw PackagingError.invalidIcon
    }

    bitmap.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let canvas = CGFloat(size)
    let background = NSBezierPath(
        roundedRect: NSRect(x: canvas * 0.035, y: canvas * 0.035, width: canvas * 0.93, height: canvas * 0.93),
        xRadius: canvas * 0.23,
        yRadius: canvas * 0.23
    )
    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.30, green: 0.58, blue: 0.40, alpha: 1),
        NSColor(srgbRed: 0.12, green: 0.31, blue: 0.24, alpha: 1)
    ])!
    gradient.draw(in: background, angle: -45)

    NSColor(srgbRed: 0.98, green: 0.97, blue: 0.89, alpha: 1).setFill()
    for (x, y, radius) in [
        (0.25, 0.56, 0.095),
        (0.41, 0.72, 0.105),
        (0.60, 0.73, 0.105),
        (0.77, 0.57, 0.095)
    ] {
        let diameter = canvas * radius * 2
        NSBezierPath(ovalIn: NSRect(
            x: canvas * x - diameter / 2,
            y: canvas * y - diameter / 2,
            width: diameter,
            height: diameter
        )).fill()
    }

    let pad = NSBezierPath(ovalIn: NSRect(
        x: canvas * 0.31,
        y: canvas * 0.16,
        width: canvas * 0.38,
        height: canvas * 0.33
    ))
    pad.fill()

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw PackagingError.invalidIcon
    }
    try data.write(to: url, options: .atomic)
}

func makeIcon(in resourcesURL: URL, temporaryRoot: URL) throws {
    let iconsetURL = temporaryRoot.appendingPathComponent("AppIcon.iconset", isDirectory: true)
    try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

    let iconSizes: [(String, Int)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024)
    ]

    for (name, size) in iconSizes {
        try drawIcon(size: size, to: iconsetURL.appendingPathComponent(name))
    }

    let iconURL = resourcesURL.appendingPathComponent("AppIcon.icns")
    try run("/usr/bin/iconutil", arguments: [
        "-c", "icns",
        iconsetURL.path,
        "-o", iconURL.path
    ])
    try FileManager.default.removeItem(at: iconsetURL)
}

func packageApp(executableURL: URL, bundleURL: URL) throws {
    let fileManager = FileManager.default
    guard fileManager.isExecutableFile(atPath: executableURL.path) else {
        throw PackagingError.missingExecutable(executableURL.path)
    }

    let parentURL = bundleURL.deletingLastPathComponent()
    try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true)

    let stagingURL = parentURL.appendingPathComponent(
        ".Animal Taxonomy.app.\(UUID().uuidString).tmp",
        isDirectory: true
    )
    defer {
        if fileManager.fileExists(atPath: stagingURL.path) {
            try? fileManager.removeItem(at: stagingURL)
        }
    }

    let contentsURL = stagingURL.appendingPathComponent("Contents", isDirectory: true)
    let macOSURL = contentsURL.appendingPathComponent("MacOS", isDirectory: true)
    let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)
    try fileManager.createDirectory(at: macOSURL, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

    let bundledExecutableURL = macOSURL.appendingPathComponent("SciClassification")
    try fileManager.copyItem(at: executableURL, to: bundledExecutableURL)
    try makeIcon(in: resourcesURL, temporaryRoot: stagingURL)

    let info: [String: Any] = [
        "CFBundleDevelopmentRegion": "en",
        "CFBundleExecutable": "SciClassification",
        "CFBundleIconFile": "AppIcon",
        "CFBundleIdentifier": "com.pnascim.sciclassification",
        "CFBundleInfoDictionaryVersion": "6.0",
        "CFBundleName": "Animal Taxonomy",
        "CFBundleDisplayName": "Animal Taxonomy",
        "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": "1.0",
        "CFBundleVersion": "1",
        "LSApplicationCategoryType": "public.app-category.education",
        "LSMinimumSystemVersion": "13.0",
        "NSHighResolutionCapable": true,
        "NSPrincipalClass": "NSApplication"
    ]
    guard PropertyListSerialization.propertyList(info, isValidFor: .xml),
          let plistData = try? PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0) else {
        throw PackagingError.invalidPlist
    }
    try plistData.write(to: contentsURL.appendingPathComponent("Info.plist"), options: .atomic)

    if fileManager.fileExists(atPath: bundleURL.path) {
        try fileManager.removeItem(at: bundleURL)
    }
    try fileManager.moveItem(at: stagingURL, to: bundleURL)
}

do {
    guard CommandLine.arguments.count == 3 else {
        throw PackagingError.usage
    }
    try packageApp(
        executableURL: URL(fileURLWithPath: CommandLine.arguments[1]),
        bundleURL: URL(fileURLWithPath: CommandLine.arguments[2])
    )
} catch {
    fputs("App packaging failed: \(error.localizedDescription)\n", stderr)
    exit(EXIT_FAILURE)
}
