//
//  File.swift
//
//
//  Created by Damiaan on 21/04/2020.
//

import Atem

if #available(OSX 10.15, *) {
	let fileManager = FileManager()

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

		var lockedStore: UInt16?

		connection.when { (lock: LockObtained) in
			lockedStore = lock.store
			if let startTransfer = fileManager.getTransfer(store: lock.store) {
				connection.send(startTransfer)
			}
		}

		connection.when { (startInfo: DataTransferChunkRequest) in
			for chunk in fileManager.getChunks(for: startInfo.transferID, preferredSize: startInfo.chunkSize, count: startInfo.chunkCount) {
				connection.sendPackage(messages: chunk)
			}
		}

		connection.when { (completion: DataTransferCompleted) in
			fileManager.markAsCompleted(transferId: completion.transferID)
			if let store = lockedStore {
				if let startTransfer = fileManager.getTransfer(store: store) {
					connection.send(startTransfer)
				} else {
					connection.send(LockRequest(store: store, state: 0))
					lockedStore = nil
				}
			}
		}

		connection.whenDisconnected = {
			print("Disconnected")
		}

		connection.whenError = { error in
			print("Error", error)
		}
	}

	while true {
		fileManager.createTransfer(
			store: 0, frameNumber: 0,
			data: Title(text: "😀" + (readLine() ?? "Sample text")).render(),
			uncompressedSize: 1920*1080*4,
			mode: .write
		)
		controller.send(message: LockPositionRequest(store: 0, index: 0, type: 1))
	}

}
