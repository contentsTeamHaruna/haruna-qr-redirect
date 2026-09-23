import AppKit
import CoreImage
import Foundation

let fixedURL = "https://contentsteamharuna.github.io/haruna-qr-redirect/"
let outputNames = ["haruna-qr-fixed-01.png", "haruna-qr-fixed-02.png"]

guard
    let data = fixedURL.data(using: .utf8),
    let filter = CIFilter(name: "CIQRCodeGenerator")
else {
    fatalError("QR filter initialization failed")
}

filter.setValue(data, forKey: "inputMessage")
filter.setValue("H", forKey: "inputCorrectionLevel")

guard let baseQRImage = filter.outputImage else {
    fatalError("QR generation failed")
}

let quietZoneExtent = baseQRImage.extent.insetBy(dx: -4, dy: -4)
let whiteBackground = CIImage(color: CIColor.white).cropped(to: quietZoneExtent)
let qrImage = baseQRImage
    .composited(over: whiteBackground)
    .transformed(by: CGAffineTransform(scaleX: 12, y: 12))

let context = CIContext()
guard let cgImage = context.createCGImage(qrImage, from: qrImage.extent) else {
    fatalError("CGImage conversion failed")
}

let bitmap = NSBitmapImageRep(cgImage: cgImage)
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("PNG conversion failed")
}

for outputName in outputNames {
    let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(outputName)
    try png.write(to: outputURL)

    guard
        let sourceImage = CIImage(contentsOf: outputURL),
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: CIContext(),
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        ),
        let feature = detector.features(in: sourceImage).first as? CIQRCodeFeature,
        let decoded = feature.messageString
    else {
        fatalError("QR decoding failed: \(outputName)")
    }

    print("file=\(outputName)")
    print("encoded=\(fixedURL)")
    print("decoded=\(decoded)")
    print("match=\(decoded == fixedURL)")
}
