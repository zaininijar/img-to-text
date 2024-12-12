import Vision
import AppKit

func recognizeText(from imagePath: String, outputFile: String) {
    guard let image = loadImage(from: imagePath) else {
        return
    }

    let request = createTextRecognitionRequest { observations in
        let extractedText = extractText(from: observations)
        appendTextToFile(extractedText, outputFile: outputFile)
    }

    processImage(image, with: request)
}


private func loadImage(from path: String) -> NSImage? {
    let imageURL = URL(fileURLWithPath: path)
    guard let image = NSImage(contentsOf: imageURL) else {
        print("Could not load image at path: \(path)")
        return nil
    }
    return image
}


private func createTextRecognitionRequest(completion: @escaping ([VNRecognizedTextObservation]) -> Void) -> VNRecognizeTextRequest {
    return VNRecognizeTextRequest { (request, error) in
        if let error = error {
            print("Error: \(error)")
            return
        }
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            print("No text observations found.")
            return
        }

        completion(observations)
    }
}


private func extractText(from observations: [VNRecognizedTextObservation]) -> String {
    var extractedText = "=====================================================\n"
    for observation in observations {
        if let topCandidate = observation.topCandidates(1).first {
            extractedText += topCandidate.string + "\n"
        }
    }
    return extractedText
}


private func appendTextToFile(_ text: String, outputFile: String) {
    do {
        let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: outputFile))
        fileHandle.seekToEndOfFile()
        if let data = text.data(using: .utf8) {
            fileHandle.write(data)
        }
        fileHandle.closeFile()
    } catch {
        print("Error writing to file: \(error)")
    }
}


private func processImage(_ image: NSImage, with request: VNRecognizeTextRequest) {
    guard let imageData = image.tiffRepresentation else {
        print("Could not extract TIFF representation from the image.")
        return
    }

    let handler = VNImageRequestHandler(data: imageData, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("Error performing request: \(error)")
    }
}

func processImages(in folderPath: String, outputFile: String) {
    let folderURL = URL(fileURLWithPath: folderPath)
    let fileManager = FileManager.default

    createOutputFile(outputFile)

    do {
        let filePaths = try fileManager.contentsOfDirectory(atPath: folderPath)
        for filePath in filePaths {
            let fullPath = folderURL.appendingPathComponent(filePath).path
            if isImageFile(filePath) {
                print("Processing: \(filePath)")
                recognizeText(from: fullPath, outputFile: outputFile)
            } else {
                print("Skipping non-image file: \(filePath)")
            }
        }
    } catch {
        print("Error reading folder: \(error)")
    }
}


private func createOutputFile(_ outputFile: String) {
    do {
        try "".write(toFile: outputFile, atomically: true, encoding: .utf8)
    } catch {
        print("Error creating output file: \(error)")
    }
}


private func isImageFile(_ fileName: String) -> Bool {
    return fileName.hasSuffix(".png") || fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg")
}

if CommandLine.arguments.count < 2 {
    print("Usage: swift script.swift /path/to/folder")
} else {
    let folderPath = CommandLine.arguments[1]
    let outputFile = folderPath + "/../output.txt"
    processImages(in: folderPath, outputFile: outputFile)
}
