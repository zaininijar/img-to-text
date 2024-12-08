import Vision
import AppKit

func recognizeText(from imagePath: String, outputFile: String) {
    let imageURL = URL(fileURLWithPath: imagePath)
    guard let image = NSImage(contentsOf: imageURL) else {
        print("Could not load image at path: \(imagePath)")
        return
    }

    let request = VNRecognizeTextRequest { (request, error) in
        if let error = error {
            print("Error: \(error)")
        } else if let observations = request.results as? [VNRecognizedTextObservation] {
            var extractedText = "=====================================================\n"
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first {
                    extractedText += topCandidate.string + "\n"
                }
            }
            do {
                let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: outputFile))
                fileHandle.seekToEndOfFile()
                if let data = extractedText.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } catch {
                print("Error writing to file: \(error)")
            }
        }
    }

    guard let imageData = image.tiffRepresentation else {
        print("Could not extract TIFF representation from the image at path: \(imagePath)")
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

    do {
        try "".write(toFile: outputFile, atomically: true, encoding: .utf8)
    } catch {
        print("Error creating output file: \(error)")
        return
    }

    do {
        let filePaths = try fileManager.contentsOfDirectory(atPath: folderPath)
        for filePath in filePaths {
            let fullPath = folderURL.appendingPathComponent(filePath).path
            if filePath.hasSuffix(".png") || filePath.hasSuffix(".jpg") || filePath.hasSuffix(".jpeg") {
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

if CommandLine.arguments.count < 2 {
    print("Usage: swift script.swift /path/to/folder")
} else {
    let folderPath = CommandLine.arguments[1]
    let outputFile = folderPath + "/../output.txt"
    processImages(in: folderPath, outputFile: outputFile)
}
