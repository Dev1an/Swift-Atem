//
//  File.swift
//  
//
//  Created by Damiaan on 12/06/2020.
//

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
import AppKit.NSImage

func loadRGBfromTiff(at path: String) -> Data {
	let image = NSImage(contentsOf: URL(fileURLWithPath: path))!

	let coreGraphics = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
	return coreGraphics.dataProvider!.data! as Data
}
#else
func loadRGBfromTiff(at path: String) -> Data {
	fatalError("loading colors from tiff file not supported")
}
#endif

import Foundation

func loadAveragedGridColors(from grid: Data) -> [UInt8] {
	[UInt8](unsafeUninitializedCapacity: 256) { (buffer, count) in
		for row in 0..<8 {
			for col in 0..<32 {
				var lum = Double(0)
				for blockX in 0..<8 {
					for blockY in 0..<5 {
						let x = col*10 + blockX
						let y = row*6 + blockY
						let coordinate = y*320 + x

						let red = UInt32( grid[coordinate * 3] )
						let green = UInt32( grid[coordinate * 3 + 1] )
						let blue = UInt32( grid[coordinate * 3 + 2] )
						lum += Double(red+green+blue)/120
					}
				}
				buffer[row*32 + col] = UInt8(lum.rounded())
			}
		}
		count = 256
	}
}


func analyzeGrid(filePath: String) {
	let gradientB = loadRGBfromTiff(at: filePath + "black.tif")
	let gradientW = loadRGBfromTiff(at: filePath + "white.tif")
	let gradientBRounded = loadAveragedGridColors(from: gradientB)
	let gradientWRounded = loadAveragedGridColors(from: gradientW)

//	print(gradientBRounded)
//	print(gradientWRounded)

	let info = [(Double, Double)](unsafeUninitializedCapacity: 256) { (buffer, count) in
		for i in 0..<256 {
			let a = Double(gradientWRounded[i])/252.5
			let b = Double(gradientBRounded[i])/252.5
			let alpha = b - a + 1
			let lum = b / alpha
			buffer[i] = (alpha, lum)
		}
		count = 256
	}

//	print(info.enumerated().filter { $1.0 > 0.7 }.sorted {$0.element.1 < $1.element.1}.map{$0.offset} )
//	print(info.enumerated().filter { (0.03 ..< 0.7).contains($1.0) }.sorted {$0.element.0 < $1.element.0}.map{$0.offset} )

	let transparantValues = info
		.enumerated()
		.filter { (0.03 ..< 0.7).contains($1.0) }
		.sorted {$0.element.0 < $1.element.0}
		.map { (UInt8($0), Int($1.0 * 255)) }

	let transparencyReverseMap = [UInt8](unsafeUninitializedCapacity: 255) { (buffer, count) in
		var previousOpacity = 0
		var previousTag = UInt8(0)
		for (tag, opacity) in transparantValues {
			let half = (previousOpacity + opacity) / 2
			for o in previousOpacity ..< half {
				buffer[o] = previousTag
			}
			for o in half ... opacity {
				buffer[o] = tag
			}
			previousOpacity = opacity
			previousTag = tag
		}
		count = previousOpacity
	}

	print(transparantValues)
	print(transparencyReverseMap, transparencyReverseMap.count)

//	print(info.prefix(upTo: 218).map{ $0 > 0.7 ? UInt8($1 * 255) : 0} )
//	print(info.enumerated().map{"\($0)\t\($1.0)\t\($1.1)"}.joined(separator: "\n"))
}

func createReverseMap(grayValues: [UInt8]) -> [UInt8] {
	var indices = [UInt8].init(repeating: 0, count: 256)
	for (index, color) in grayValues.enumerated() {
		if color != 0 {
			indices[Int(color)] = UInt8(index)
		}
	}

	var cursor = 0
	var previousColor = UInt8(14)
	while cursor < indices.endIndex {
		if indices[cursor] == 0 {
			let nextColorIndex = indices[cursor...].firstIndex {$0 != 0}!
			let nextColor = indices[nextColorIndex]
			let half = (cursor + nextColorIndex) / 2
			for index in cursor..<half {
				indices[index] = previousColor
			}
			for index in half..<nextColorIndex {
				indices[index] = nextColor
			}
			cursor = nextColorIndex + 1
			previousColor = nextColor
		} else {
			cursor += 1
		}
	}

	return indices
}
