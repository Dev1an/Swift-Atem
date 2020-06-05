//
//  File.swift
//  
//
//  Created by Damiaan on 23/05/2020.
//

//import Foundation
//
//let repeatMarker: UInt64 = 0xFEFE_FEFE_FEFE_FEFE
//
//let KR: Float32 = 0.2126;
//let KB: Float32 = 0.0722;
//let KG: Float32 = 1 - KR - KB;
//
//let KRi: Float32 = 1 - KR;
//let KBi: Float32 = 1 - KB;
//
//let KBG: Float32 = KB / KG;
//let KRG: Float32 = KR / KG;
//
//let YRange: Float32 = 219;
//let CbCrRange = 224;
//let HalfCbCrRange = Float32(CbCrRange / 2);
//
//let YOffset: Float32 = Float32(Int(16) << 8);
//let CbCrOffset = Float32(128 << 8);
//
//let KRoKBi: Float32 = KR / KBi * HalfCbCrRange;
//let KGoKBi: Float32 = KG / KBi * HalfCbCrRange;
//let KBoKRi: Float32 = KB / KRi * HalfCbCrRange;
//let KGoKRi: Float32 = KG / KRi * HalfCbCrRange;
//
//let KBiRange: Float32 = KBi / HalfCbCrRange;
//let KRiRange: Float32 = KRi / HalfCbCrRange;
//
//
//func rgba(from doublePixel: UInt64) -> UInt64 {
//	let alpha1 = UInt16((doublePixel >> 52) & 0b0000_0011_1111_1111)
//	let blue   = UInt16((doublePixel >> 42) & 0b0000_0011_1111_1111)
//	let lum1   = UInt16((doublePixel >> 32) & 0b0000_0011_1111_1111)
//
//	let alpha2 = UInt16((doublePixel >> 20) & 0b0000_0011_1111_1111)
//	let red    = UInt16((doublePixel >> 10) & 0b0000_0011_1111_1111)
//	let lum2   = UInt16((doublePixel      ) & 0b0000_0011_1111_1111)
//
//	let cb = KBiRange * (Float32(blue << 6) - CbCrOffset)
//	let cr = KRiRange * (Float32(red  << 6) - CbCrOffset)
//
//	let y1 = (Float32(lum1 << 6) - YOffset) / YRange
//	let r1 = UInt64(min(255, max(0, y1 + cr)))
//	let g1 = UInt64(min(255, max(0, y1 - cb * KBG - cr * KRG)))
//	let b1 = UInt64(min(255, max(0, y1 + cb)))
//	let a1 = UInt64(min(255, max(0, (Float(alpha1) - 64) * 0.292)))
//
//	let y2 = (Float32(lum2 << 6) - YOffset) / YRange
//	let r2 = UInt64(min(255, max(0, y2 + cr)))
//	let g2 = UInt64(min(255, max(0, y2 - cb * KBG - cr * KRG)))
//	let b2 = UInt64(min(255, max(0, y2 + cb)))
//	let a2 = UInt64(min(255, max(0, (Float(alpha2) - 64) * 0.292)))
//
//	let sg1 = g1 << 8
//	let sb1 = b1 << 16
//	let sa1 = a1 << 24
//
//	let sr2 = r2 << 32
//	let sg2 = g2 << 40
//	let sb2 = b2 << 48
//	let sa2 = a2 << 56
//
//	return (r1 | sg1 | sb1 | sa1 | sr2 | sg2 | sb2 | sa2).littleEndian
//}
//
//let mask: UInt64 = 0b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111
//
////extension UInt64 {
////	func reverse() {
////		let s7 = (self >> 7) & 0x1111_1111
////		let s5 = (self >> 6) & 0x2222_2222
////		let s3 = (self >> 5) & 0x4444_4444
////		let s1 = (self >> 4) & 0x8888_8888
////
////		let b8 = (self << 1) & 0x1357
////	}
////}
//
//extension FixedWidthInteger {
//    var bitSwapped: Self {
//        var v = self
//        var s = Self(v.bitWidth)
//        precondition(s.nonzeroBitCount == 1, "Bit width must be a power of two")
//        var mask = ~Self(0)
//        repeat  {
//            s = s >> 1
//            mask ^= mask << s
//            v = ((v >> s) & mask) | ((v << s) & ~mask)
//        } while s > 1
//        return v
//    }
//}
//
//func decodeRunLength(data compressed: Data) -> [UInt64] {
//	let startDate = Date()
//	var decompressed = [UInt64]()
//	compressed.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Void in
//		let pixelCount = compressed.count/8
//		var cursor = buffer.baseAddress!.bindMemory(to: UInt64.self, capacity: pixelCount)
//		let endPixel = cursor.advanced(by: pixelCount)
//		while cursor < endPixel {
//			if cursor.pointee == repeatMarker {
//				cursor = cursor.successor()
//				let repeatCount = UInt64(bigEndian: cursor.pointee)
//				cursor = cursor.successor()
//				let doublePixel = cursor.pointee//.bigEndian.bitSwapped & mask
////				let doubleRGBA = rgba(from: doublePixel)
//				for _ in 0 ..< repeatCount {
//					decompressed.append(doublePixel)
//				}
//				cursor = cursor.successor()
//			} else {
//				let doublePixel = cursor.pointee//.bigEndian.bitSwapped & mask
//				decompressed.append(doublePixel)
//
//				cursor = cursor.successor()
//			}
//		}
//	}
//	print(Date().timeIntervalSince(startDate))
//	return decompressed
//}
//
////let part1 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/image/part1.bin"))
////let part2 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/image/part2.bin"))
////let part3 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/image/part3.bin"))
//
//let part1 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/long/part1.bin"))
//let part2 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/long/part2.bin"))
//let part3 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/long/part3.bin"))
//let part4 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/long/part4.bin"))
//let part5 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/long/part5.bin"))
//let part6 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/long/part6.bin"))
//let part7 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/long/part7.bin"))
//let part8 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/long/part8.bin"))
////
//let compressedImage = part1 + part2 + part3 + part4 + part5 + part6 + part7 + part8
//
////let compressedImage = try Data(contentsOf: URL(fileURLWithPath: "/tmp/testImage.bin"))
////let compressedImage = try Data(contentsOf: URL(fileURLWithPath: "/tmp/testColors.bin"))
////let compressedImage = try Data(contentsOf: URL(fileURLWithPath: "/tmp/grayscale.bin"))
//
//let decompressedImage = decodeRunLength(data: compressedImage)
//
//var imageData = decompressedImage.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Data in
//	print(buffer.count)
//	return Data(bytes: buffer.baseAddress!, count: buffer.count)
//}
//
//try imageData.write(to: URL(fileURLWithPath: "/tmp/atemImage.bin"))
//
//import CoreGraphics
//import AppKit
//
//import Accelerate
//
////let width = UInt(1920)
////let height = UInt(1080)
//
////var sourceBuffer = imageData.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) -> vImage_Buffer in
////	vImage_Buffer(data: buffer.baseAddress!, height: height, width: width, rowBytes: Int(width * 4))
////}
//
//let dataProvider = CGDataProvider(data: imageData as NSData)!
//
//if #available(OSX 10.11, *) {
////	let pixelCount = 28800/4
//	let width = 320
//	let height = 90
//
////	let cgImage = CGImage(
////		width: width,
////		height: height,
////		bitsPerComponent: 8,
////		bitsPerPixel: 32,
////		bytesPerRow: width*4,
////		space: CGColorSpace(name: CGColorSpace.sRGB)!,
////		bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
////		provider: dataProvider,
////		decode: nil,
////		shouldInterpolate: true,
////		intent: .defaultIntent
////	)!
//
//	let cgImage = CGImage(
//		width: width,
//		height: height,
//		bitsPerComponent: 4,
//		bitsPerPixel: 8,
//		bytesPerRow: width,
//		space: CGColorSpaceCreateDeviceGray(),
//		bitmapInfo: [CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)],
//		provider: dataProvider,
//		decode: nil,
//		shouldInterpolate: true,
//		intent: .defaultIntent
//	)!
//
//	let name = "/tmp/atemInput-\(width)x\(height).tiff"
//	try NSImage(cgImage: cgImage, size: .init(width: width, height: height)).tiffRepresentation?.write(to: URL(fileURLWithPath: name))
//} else {
//	print("macOS too old")
//}

// 00111010100110000000001110101001 00111010100110000000001110101001
// 00010111101110000000000101111011 00010111101110000000000101111011
