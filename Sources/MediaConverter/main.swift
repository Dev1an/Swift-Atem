//
//  File.swift
//  
//
//  Created by Damiaan on 20/05/2020.
//

import Foundation


let part1 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/stripe.bin"))
//let part2 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/image/part2.bin"))
//let part3 = try Data(contentsOf: URL(fileURLWithPath: "/tmp/image/part3.bin"))
//
let compressedImage = part1// + part2 + part3

//let compressedImage = try Data(contentsOf: URL(fileURLWithPath: "/tmp/testImage.bin"))
//let compressedImage = try Data(contentsOf: URL(fileURLWithPath: "/tmp/testColors.bin"))
//let compressedImage = try Data(contentsOf: URL(fileURLWithPath: "/tmp/grayscale.bin"))

let startDate = Date()
let decompressedImage = decodeRunLength(data: compressedImage, uncompressedByteCount: 8294400)
print(decompressedImage.count)
print(Date().timeIntervalSince(startDate))

//try imageData.write(to: URL(fileURLWithPath: "/tmp/atemImage.bmp"))

import CoreGraphics
import AppKit

import Accelerate

//let width = UInt(1920)
//let height = UInt(1080)

//var sourceBuffer = imageData.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) -> vImage_Buffer in
//	vImage_Buffer(data: buffer.baseAddress!, height: height, width: width, rowBytes: Int(width * 4))
//}

let dataProvider = CGDataProvider(data: decompressedImage as NSData)!

//	let pixelCount = 28800/4
let width = 1920
let height = 1080

let cgImage = CGImage(
	width: width,
	height: height,
	bitsPerComponent: 8,
	bitsPerPixel: 32,
	bytesPerRow: width*4,
	space: CGColorSpace(name: CGColorSpace.sRGB)!,
	bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
	provider: dataProvider,
	decode: nil,
	shouldInterpolate: true,
	intent: .defaultIntent
)!

let name = "/tmp/atemInput-\(width)x\(height).tiff"
try NSImage(cgImage: cgImage, size: .init(width: width, height: height)).tiffRepresentation?.write(to: URL(fileURLWithPath: name))

// 00111010100110000000001110101001 00111010100110000000001110101001
// 00010111101110000000000101111011 00010111101110000000000101111011
