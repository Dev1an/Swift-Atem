//
//  File.swift
//  
//
//  Created by Damiaan on 11/06/2020.
//

import Foundation

public func decodeRunLength(rawData compressed: Data, uncompressedByteCount: Int? = nil) -> Data {
	var decompressed = [UInt64]()
	if let byteCount = uncompressedByteCount {
		decompressed.reserveCapacity(byteCount / 8)
	}
	compressed.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Void in
		let pixelCount = compressed.count/8
		var cursor = buffer.baseAddress!.bindMemory(to: UInt64.self, capacity: pixelCount)
		let endPixel = cursor.advanced(by: pixelCount)
		while cursor < endPixel {
			if cursor.pointee == repeatMarker {
				cursor = cursor.successor()
				let repeatCount = UInt64(bigEndian: cursor.pointee)
				cursor = cursor.successor()
				let doublePixel = cursor.pointee
				for _ in 0 ..< repeatCount {
					decompressed.append(doublePixel)
				}
				cursor = cursor.successor()
			} else {
				let doublePixel = cursor.pointee
				decompressed.append(doublePixel)

				cursor = cursor.successor()
			}
		}
	}

	return decompressed.data
}

public func encodeRunLength(rawData data: Data) -> Data {
	var compressed = [UInt64]()
	compressed.reserveCapacity(data.count)

	data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Void in
		let pixelCount = data.count/8
		var cursor = buffer.baseAddress!.bindMemory(to: UInt64.self, capacity: pixelCount)
		let endPixel = cursor.advanced(by: pixelCount)
		while cursor < endPixel {
			var nextCursor = cursor.successor()
			defer { cursor = nextCursor }
			while nextCursor < endPixel && cursor.pointee == nextCursor.pointee {
				nextCursor = nextCursor.successor()
			}
			let count = cursor.distance(to: nextCursor)
			let pixels = cursor.pointee
			if count > 2 {
				compressed.append(repeatMarker)
				compressed.append(UInt64(count).bigEndian)
				compressed.append(pixels)
			} else {
				for _ in 0..<count {
					compressed.append(pixels)
				}
			}
		}
	}

	return compressed.data
}
