//
//  File.swift
//
//
//  Created by Damiaan on 21/04/2020.
//

import Cocoa
import MediaConverter

let frame = NSRect(x: 0, y: 0, width: 1920, height: 1080)
let view = NSTextView(frame: frame)
view.font = .labelFont(ofSize: 200)
view.textColor = .white
view.backgroundColor = .black

let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1920, pixelsHigh: 1080, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bitmapFormat: .init(), bytesPerRow: 1920*4, bitsPerPixel: 32)!

func generateImage() -> Data {
	encodeRunLength(data: imageRep.cgImage!.dataProvider!.data! as Data)
}
var textImage = generateImage()


import Atem

let address: String
if CommandLine.arguments.count > 1 {
	address = CommandLine.arguments[1]
} else {
	print("Enter switcher IP address: ", terminator: "")
	address = readLine() ?? "10.1.0.210"
}
print("Trying to connect to switcher with IP addres", address)

let controller = try Controller(ipAddress: address) { connection in

	connection.when { (connected: InitiationComplete) in
		print(connected)
		print("Type some text to send to the atem")
	}

	var transferCounter = UInt16(100)
	var dataCursor = 0

	connection.when { (lock: LockObtained) in
		print("got lock, starting data transfer")
		transferCounter = .random(in: 0 ..< .max)
		dataCursor = 0
		connection.send(StartDataTransfer(transferID: transferCounter, store: 0, frameNumber: 0, size: 1920*1080*4, mode: .write))
	}

	connection.when { (startInfo: DataTransferChunkRequest) in
		guard dataCursor < textImage.count else {
			print("early exit")
			return
		}

		if dataCursor == 0 {
			connection.send(SetFileDescription(
				transferID: startInfo.transferID,
				name: "Color bars",
				description: "Horizontal color bars",
				hash: .init(repeating: .random(in: 0..<255), count: 16)
			))
		}

		let surplus = Int(startInfo.chunkSize % 8)
		let maxChunkSize = Int(startInfo.chunkSize) - surplus

//		print("uploading chunks from \(dataCursor) (progress: \(Double(dataCursor) / Double(textImage.count)))")

		var chunkIndex = UInt16(0)
		while dataCursor < textImage.count && chunkIndex < startInfo.chunkCount {
			let chunkEnd = textImage.withUnsafeBytes { (buffer) -> Int in
				let maxChunkEnd = dataCursor + maxChunkSize
				if maxChunkEnd > textImage.count { return textImage.count }
				var chunkEnd = maxChunkEnd - 16
				while chunkEnd < maxChunkEnd {
					if buffer.load(fromByteOffset: chunkEnd, as: UInt64.self) == repeatMarker {
						return chunkEnd
					}
					chunkEnd += 8
				}
				return chunkEnd
			}
//			print("\tsending chunk \(dataCursor..<chunkEnd) (size: \(chunkEnd - dataCursor))")
			connection.sendPackage(
				with: TransferData(
					transferID: startInfo.transferID,
					data: Array(textImage[dataCursor..<chunkEnd])
				)
			)
			dataCursor = chunkEnd
			chunkIndex += 1
		}

		if dataCursor == textImage.count {
//			print("finished uploading bytes")
		}
	}

	connection.when { (completion: DataTransferCompleted) in
		connection.send(LockRequest(store: 0, state: 0))
		print("upload successful")
	}

	connection.whenDisconnected = {
		print("Disconnected")
	}
}

while true {
	view.string = (readLine() ?? "Sample text") + "😍"
	view.cacheDisplay(in: frame, to: imageRep)
	textImage = generateImage()

	controller.send(message: LockPositionRequest(store: 0, index: 0, type: 1))
}
