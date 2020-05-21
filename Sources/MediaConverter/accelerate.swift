//
//  File.swift
//  
//
//  Created by Damiaan on 20/05/2020.
//

import Foundation

//import Accelerate
//
//let width = UInt(160)
//let height = UInt(45)
//
//var sourceBuffer = imageData.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) -> vImage_Buffer in
//	vImage_Buffer(data: buffer.baseAddress!, height: height, width: width, rowBytes: Int(width * 4))
//}
//
//if #available(OSX 10.15, *) {
//	let rgbDestinationImageFormat = vImage_CGImageFormat(
//		bitsPerComponent: 8,
//		bitsPerPixel: 32,
//		colorSpace: nil,
//		bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
//		version: 0,
//		decode: nil,
//		renderingIntent: .defaultIntent
//	)
//	// 5: Create and initialize the destination buffer.
//	// Assumes `cmykSourceBuffer` exists and contains 16-bit-per-channel CMYK image data.
//	var rgbDestinationBuffer = vImage_Buffer()
//	vImageBuffer_Init(&rgbDestinationBuffer,
//					  sourceBuffer.height,
//					  sourceBuffer.width,
//					  rgbDestinationImageFormat.bitsPerPixel,
//					  vImage_Flags(kvImageNoFlags))
//
//	// video range 8-bit, clamped to video range
//	var pixelRange = vImage_YpCbCrPixelRange(
//		Yp_bias: 16,
//		CbCr_bias: 128,
//		YpRangeMax: 265,
//		CbCrRangeMax: 240,
//		YpMax: 235,
//		YpMin: 16,
//		CbCrMax: 240,
//		CbCrMin: 16
//	)
//
//
//	var conversionInfo = vImage_YpCbCrToARGB()
//	vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_709_2, &pixelRange, &conversionInfo, kvImage422CrYpCbYpCbYpCbYpCrYpCrYp10, kvImageARGB8888, vImage_Flags(kvImagePrintDiagnosticsToConsole))
//	var permuteMap = [UInt8(3),0,1,2]
//
//	vImageConvert_422CrYpCbYpCbYpCbYpCrYpCrYp10ToARGB8888(&sourceBuffer, &rgbDestinationBuffer, &conversionInfo, &permuteMap, .max, vImage_Flags())
//
//	let rgbCGimage = try rgbDestinationBuffer.createCGImage(format: rgbDestinationImageFormat)
//	try NSImage(cgImage: rgbCGimage, size: .init(width: Int(width), height: Int(height))).tiffRepresentation?.write(to: URL(fileURLWithPath: "/tmp/atemInput.tiff"))
//} else {
//		print("macOS too old")
//}
