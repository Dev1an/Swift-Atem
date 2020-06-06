//
//  File.swift
//  
//
//  Created by Damiaan on 05/06/2020.
//

import Foundation

public class UploadManager {

	private var transferCounter: UInt16 = 0
	private var transfers = [UInt16 : Transfer]()

	struct Transfer {
		let start: StartDataTransfer
		let description: SetFileDescription
		let data: Data
		var transferredBytes = 0
	}

	init() {}

	func createTransfer(store: UInt16, frameNumber: UInt16, data: Data, uncompressedSize: UInt32, mode: StartDataTransfer.Mode, name optionalName: String? = nil, description: String = "") {

		let id = transferCounter
		transferCounter += 1

		let name = optionalName ?? "transfer \(transferCounter)"

		let transfer = Transfer(
			start: StartDataTransfer(transferID: id, store: store, frameNumber: frameNumber, size: uncompressedSize, mode: mode),
			description: SetFileDescription(transferID: id, name: name, description: description),
			data: data
		)

		transfers[id] = transfer
	}

	func markAsCompleted(transferId: UInt16) {
		transfers.removeValue(forKey: transferId)
	}

	func getChunks(for id: UInt16, preferredSize: UInt16, count: UInt16) -> [[UInt8]] {
		guard let transfer = transfers[id] else {
			return []
		}

		var transferredBytes = transfer.transferredBytes
		let data = transfer.data

		guard transferredBytes < data.count else {
			return []
		}

		var chunks = [[UInt8]]()

		if transferredBytes == 0 {
			chunks.append(transfer.description.serialize())
		}

		let surplus = Int(preferredSize % 8)
		let maxChunkSize = Int(preferredSize) - surplus

//			print("uploading chunks from \(dataCursor) (progress: \(Double(dataCursor) / Double(textImage.count)))")

		var chunkIndex = UInt16(0)
		while transferredBytes < data.count && chunkIndex < count {
			let chunkEnd = data.withUnsafeBytes { (buffer) -> Int in
				let maxChunkEnd = transferredBytes + maxChunkSize
				if maxChunkEnd > data.count { return data.count }
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
			chunks.append(
				TransferData(
					transferID: id,
					data: Array(data[transferredBytes..<chunkEnd])
				).serialize()
			)
			transferredBytes = chunkEnd
			chunkIndex += 1
		}
		transfers[id]!.transferredBytes = transferredBytes

		if transferredBytes == data.count {
//				print("finished uploading bytes")
		}

		return chunks
	}

	func getTransfer(store: UInt16) -> StartDataTransfer? {
		transfers.values.first { $0.start.store == store }?.start
	}
}
