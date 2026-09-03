import Foundation
import Vision

let args = Array(CommandLine.arguments.dropFirst())
let wantBoxes = args.contains("--boxes")
guard let path = args.first(where: { !$0.hasPrefix("-") }) else {
    fputs("usage: ocr_vision.swift [--boxes] <image>\n", stderr)
    exit(1)
}

let url = URL(fileURLWithPath: path)
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
let handler = VNImageRequestHandler(url: url, options: [:])
do {
    try handler.perform([request])
} catch {
    fputs("vision: \(error)\n", stderr)
    exit(2)
}
if wantBoxes {
    for obs in request.results ?? [] {
        guard let text = obs.topCandidates(1).first?.string, !text.isEmpty else { continue }
        let b = obs.boundingBox
        print("\(b.origin.x)\t\(b.origin.y)\t\(b.size.width)\t\(b.size.height)\t\(text)")
    }
} else {
    let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
    print(lines.joined(separator: "\n"))
}
