//
//  File.swift
//
//
//  Created by Damiaan on 21/04/2020.
//

import MediaConverter
import Atem

if #available(OSX 10.15, *) {

	var textImage = Title(text: "").render()

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

//			print("uploading chunks from \(dataCursor) (progress: \(Double(dataCursor) / Double(textImage.count)))")

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
//				print("\tsending chunk \(dataCursor..<chunkEnd) (size: \(chunkEnd - dataCursor))")
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
//				print("finished uploading bytes")
			}
		}

		connection.when { (completion: DataTransferCompleted) in
			connection.send(LockRequest(store: 0, state: 0))
//			print("upload successful")
		}

		connection.whenDisconnected = {
			print("Disconnected")
		}
	}

	while true {
		textImage = Title(text: readLine() ?? "Sample text").render()
		controller.send(message: LockPositionRequest(store: 0, index: 0, type: 1))
	}

}
