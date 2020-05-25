//
//  File.swift
//  
//
//  Created by Damiaan on 23/05/2020.
//

import Foundation

let rLum: Float32 = 0.2126
let gLum: Float32 = 0.7152
let bLum: Float32 = 1 - rLum - gLum

let bChrom: Float32 = 0.5389
let rChrom: Float32 = 0.6350

// ITU-Recommendation BT.709
// Y   = 0.2126*R + 0.7152*G + 0.0722*B
// Cb  = 0.5389*(B-Y)
// Cr  = 0.6350*(R-Y)


let uInt10Max = Float32(1 << 10) - 1
let sInt10End = Float32(1 <<  9)
let sInt10Max = sInt10End - 1
let uInt10in8 = Float32(UInt8.max) / uInt10Max
let sInt10in8 = Float32(UInt8.max) / sInt10Max

func rgba(from ablarl: UInt64) -> UInt64 {
	let alpha1 = Float32((ablarl >> 52) & 0b0000_0011_1111_1111)
	let blue   = Float32((ablarl >> 42) & 0b0000_0011_1111_1111) - sInt10End
	let lum1   = Float32((ablarl >> 32) & 0b0000_0011_1111_1111)

	let alpha2 = Float32((ablarl >> 20) & 0b0000_0011_1111_1111)
	let red    = Float32((ablarl >> 10) & 0b0000_0011_1111_1111) - sInt10End
	let lum2   = Float32((ablarl      ) & 0b0000_0011_1111_1111)

	let rs = red / rChrom
	let r1 = to8Bit(rs + lum1)
	let r2 = to8Bit(rs + lum2)

	let bs = blue / bChrom
	let b1 = to8Bit(bs + lum1)
	let b2 = to8Bit(bs + lum2)

	let g1 = to8Bit(lum1 - r1 * rLum - b1 * bLum)
	let g2 = to8Bit(lum2 - r2 * rLum - b2 * bLum)

	let a1 = to8Bit(alpha1)
	let a2 = to8Bit(alpha2)

	let sr1 = UInt64(r1)
	let sg1 = UInt64(g1) << 8
	let sb1 = UInt64(b1) << 16
	let sa1 = UInt64(a1) << 24

	let sr2 = UInt64(r2) << 32
	let sg2 = UInt64(g2) << 40
	let sb2 = UInt64(b2) << 48
	let sa2 = UInt64(a2) << 56

	return (sr1 | sg1 | sb1 | sa1 | sr2 | sg2 | sb2 | sa2).littleEndian
}

func clampToUInt8(_ float: Float32) -> Float32 {
	min(255, max(0, float))
}

func to8Bit(_ float: Float32) -> Float32 {
	clampToUInt8( float * uInt10in8 )
}

let repeatMarker: UInt64 = 0xFEFE_FEFE_FEFE_FEFE


/// Decode 10bit YUV to 8bit RGB
/// - Parameters:
///   - compressed: array containing groups of (Alpha1 Blue Lum1 Alpha2 Red Lum2). With 10bits for each color channel. So one group is 8 bytes  = 64 bits and describes two pixels
///   - uncompressedByteCount: the size of the decompressed data
/// - Returns: array containing groups of (Red Green Blue Alpha) with 8 bits for each channel. So one group is 4 bytes = 32 bit and describes one pixel.
func decodeRunLength(data compressed: Data, uncompressedByteCount: Int? = nil) -> Data {
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
				let doublePixel = UInt64(bigEndian: cursor.pointee)
				let doubleRGBA = rgba(from: doublePixel)
				for _ in 0 ..< repeatCount {
					decompressed.append(doubleRGBA)
				}
				cursor = cursor.successor()
			} else {
				let doublePixel = UInt64(bigEndian: cursor.pointee)
				decompressed.append(rgba(from: doublePixel))

				cursor = cursor.successor()
			}
		}
	}

	return decompressed.data
}

func ablarlFrom(rgbaBundle: UnsafeRawPointer) -> UInt64 {
	let red1   = Float32(rgbaBundle.load(fromByteOffset: 0, as: UInt8.self))
	let green1 = Float32(rgbaBundle.load(fromByteOffset: 1, as: UInt8.self))
	let blue1  = Float32(rgbaBundle.load(fromByteOffset: 2, as: UInt8.self))
	let alpha1 = Float32(rgbaBundle.load(fromByteOffset: 3, as: UInt8.self))
	let red2   = Float32(rgbaBundle.load(fromByteOffset: 4, as: UInt8.self))
	let green2 = Float32(rgbaBundle.load(fromByteOffset: 5, as: UInt8.self))
	let blue2  = Float32(rgbaBundle.load(fromByteOffset: 6, as: UInt8.self))
	let alpha2 = Float32(rgbaBundle.load(fromByteOffset: 7, as: UInt8.self))

	let lum1 = red1 * rLum + green1 * gLum + blue1 * bLum
	let lum2 = red2 * rLum + green2 * gLum + blue2 * bLum

	let r1 = red1 - lum1
	let r2 = red2 - lum1
	let r = toSigned10Bit( rChrom * (r1 + r2)/2 )

	let b1 = blue1 - lum1
	let b2 = blue2 - lum2
	let b = toSigned10Bit( bChrom * (b1 + b2)/2 )

	let l1 = to10Bit(lum1)
	let l2 = to10Bit(lum2)
	let a1 = to10Bit(alpha1)
	let a2 = to10Bit(alpha2)

	return (a1 | (b << 10) | (l1 << 20) | (a2 << 32) | (r << 42) | (l2 << 52)).littleEndian
}

func toSigned10Bit(_ float: Float32) -> UInt64 {
	to10Bit(float + sInt10End)
}

func to10Bit(_ float: Float32) -> UInt64 {
	UInt64(clampToUInt8(float)) << 2
}

func encodeRunLength(data: Data) -> Data {
	var compressed = [UInt64]()
	compressed.reserveCapacity(data.count)

	data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Void in
		let pixelCount = data.count/8
		var cursor = buffer.baseAddress!.bindMemory(to: UInt64.self, capacity: pixelCount)
		let endPixel = cursor.advanced(by: pixelCount)
		while cursor < endPixel {
			var nextCursor = cursor.successor()
			defer { cursor = nextCursor }
			while cursor.pointee == nextCursor.pointee {
				nextCursor = nextCursor.successor()
			}
			let count = cursor.distance(to: nextCursor)
			let yuv = ablarlFrom(rgbaBundle: UnsafeRawPointer(cursor))
			if count > 2 {
				compressed.append(repeatMarker)
				compressed.append(UInt64(count).bigEndian)
				compressed.append(yuv)
			} else {
				for _ in 0..<count {
					compressed.append(yuv)
				}
			}
		}
	}

	return compressed.data
}

extension Array where Element == UInt64 {
	var data: Data {
		withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Data in
			Data(bytes: buffer.baseAddress!, count: buffer.count)
		}
	}
}
