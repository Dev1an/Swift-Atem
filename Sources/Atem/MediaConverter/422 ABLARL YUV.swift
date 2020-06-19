//
//  File.swift
//  
//
//  Created by Damiaan on 23/05/2020.
//

import Foundation

/// Namespace for functions that relate to media encoding
public enum Media {
	
	static let rLum: Float = 0.2126
	static let gLum: Float = 0.7152
	static let bLum: Float = 1 - rLum - gLum

	static let bChrom: Float = 0.5389
	static let rChrom: Float = 0.6350

	// ITU-Recommendation BT.709
	// Y   = 0.2126*R + 0.7152*G + 0.0722*B
	// Cb  = 0.5389*(B-Y)
	// Cr  = 0.6350*(R-Y)


	static let uInt10Max = Float(1 << 10) - 1
	static let sInt10End = Float(1 <<  9)
	static let sInt10Max = sInt10End - 1
	static let uInt10in8 = Float(UInt8.max) / uInt10Max
	static let sInt10in8 = Float(UInt8.max) / sInt10Max

	static func rgba(from ablarl: UInt64) -> UInt64 {
		let alpha1 = Float((ablarl >> 52) & 0b0000_0011_1111_1111)
		let blue   = Float((ablarl >> 42) & 0b0000_0011_1111_1111) - sInt10End
		let lum1   = Float((ablarl >> 32) & 0b0000_0011_1111_1111)

		let alpha2 = Float((ablarl >> 20) & 0b0000_0011_1111_1111)
		let red    = Float((ablarl >> 10) & 0b0000_0011_1111_1111) - sInt10End
		let lum2   = Float((ablarl      ) & 0b0000_0011_1111_1111)

		let rs = red / rChrom
		let r1 = to8Bit(rs + lum1)
		let r2 = to8Bit(rs + lum2)

		let bs = blue / bChrom
		let b1 = to8Bit(bs + lum1)
		let b2 = to8Bit(bs + lum2)

		let g1 = to8Bit((lum1 - r1 * rLum - b1 * bLum) / gLum)
		let g2 = to8Bit((lum2 - r2 * rLum - b2 * bLum) / gLum)

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

	static func clampToUInt8(_ float: Float) -> Float {
		min(255, max(0, float))
	}

	static func to8Bit(_ float: Float) -> Float {
		clampToUInt8( float * uInt10in8 )
	}

	public static let repeatMarker: UInt64 = 0xFEFE_FEFE_FEFE_FEFE

	/// Decode 10bit YUV to 8bit RGB
	/// - Parameters:
	///   - yuvData: array containing groups of (Alpha1 Blue Lum1 Alpha2 Red Lum2). With 10bits for each color channel. So one group is 8 bytes  = 64 bits and describes two pixels
	///   - uncompressedByteCount: the size of the decompressed data
	/// - Returns: array containing groups of (Red Green Blue Alpha) with 8 bits for each channel. So one group is 4 bytes = 32 bit and describes one pixel.
	public static func decodeRunLength(yuvData compressed: Data, uncompressedByteCount: Int? = nil) -> Data {
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

	static func ablarlFrom(rgbaBundle: UnsafeRawPointer) -> UInt64 {
		let red1   = Float(rgbaBundle.load(fromByteOffset: 0, as: UInt8.self))
		let green1 = Float(rgbaBundle.load(fromByteOffset: 1, as: UInt8.self))
		let blue1  = Float(rgbaBundle.load(fromByteOffset: 2, as: UInt8.self))
		let alpha1 = Float(rgbaBundle.load(fromByteOffset: 3, as: UInt8.self))
		let red2   = Float(rgbaBundle.load(fromByteOffset: 4, as: UInt8.self))
		let green2 = Float(rgbaBundle.load(fromByteOffset: 5, as: UInt8.self))
		let blue2  = Float(rgbaBundle.load(fromByteOffset: 6, as: UInt8.self))
		let alpha2 = Float(rgbaBundle.load(fromByteOffset: 7, as: UInt8.self))

		let lum1 = red1 * rLum + green1 * gLum + blue1 * bLum
		let lum2 = red2 * rLum + green2 * gLum + blue2 * bLum

		let r1 = red1 - lum1
		let r2 = red2 - lum2
		let r = toSigned10Bit( rChrom * (r1 + r2)/2 )

		let b1 = blue1 - lum1
		let b2 = blue2 - lum2
		let b = toSigned10Bit( bChrom * (b1 + b2)/2 )

		let l1 = to10Bit(lum1)
		let l2 = to10Bit(lum2)
		let a1 = to10Bit(alpha1)
		let a2 = to10Bit(alpha2)

		return ((a1 << 52) | (b << 42) | (l1 << 32) | (a2 << 20) | (r << 10) | l2).bigEndian
	}

	static func toSigned10Bit(_ float: Float) -> UInt64 {
		UInt64(min(uInt10Max, max(0, float * 4 + sInt10End)))
	}

	static func to10Bit(_ float: Float) -> UInt64 {
		UInt64(min(uInt10Max, max(0, float * 55 / 16 + 64)))
		// The factor 55/16 + 64 shifts and scales [0-255] to [64-893].
		// That is basically a combination of mapping [0-255] to [16-235] (see SMPTE-125M)
		// combined with mapping [0-255] to [0-1024] (8bit to 10bit)
	}

	/// Encode to 8bit RGB to 10bit YUV
	/// - Parameters:
	///   - rgbData: array containing groups of (Red Green Blue Alpha) with 8 bits for each channel. So one group is 4 bytes = 32 bit and describes one pixel.
	/// - Returns: array containing groups of (Alpha1 Blue Lum1 Alpha2 Red Lum2). With 10bits for each color channel. So one group is 8 bytes  = 64 bits and describes two pixels
	public static func encodeRunLength(rgbData data: Data) -> Data {
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

}

extension Array where Element == UInt64 {
	var data: Data {
		withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Data in
			Data(bytes: buffer.baseAddress!, count: buffer.count)
		}
	}
}
