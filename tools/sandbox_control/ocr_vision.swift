import Foundation
import Vision

guard CommandLine.arguments.count > 1 else {
    fputs("usage: ocr_vision.swift <image>\n", stderr)
    exit(1)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
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
let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
print(lines.joined(separator: "\n"))
