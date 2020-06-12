//
//  File.swift
//  
//
//  Created by Damiaan on 12/06/2020.
//

import Foundation
import Atem

func createGrid() throws -> Data {
	var decompressed = try Data(contentsOf: URL(fileURLWithPath: "/Users/damiaan/Documents/Projecten/ATEM/Research/communication/Change input name/input10 image/decompressed.bin"))

	for x in 0 ..< 320 * 50 { decompressed[x] = 0 }
	var number = UInt8(0)
	for row in 0..<8 {
		for col in 0..<32 {
			for x in 0..<8 {
				for y in 0..<5 {
					decompressed[(row*6 + y)*320 + (col*10 + x)] = number
				}
			}
			if number < .max {number += 1}
		}
	}

	let grid = encodeRunLength(rawData: decompressed)
	try grid.write(to: URL(fileURLWithPath: "/Users/damiaan/Documents/Projecten/ATEM/Research/communication/Change input name/input10 image/compressed3.bin"))

	return grid
}

func createRect(color: UInt8) throws -> Data {
	var decompressed = try Data(contentsOf: URL(fileURLWithPath: "/Users/damiaan/Documents/Projecten/ATEM/Research/communication/Change input name/input10 image/decompressed.bin"))
	for coordinate in 0 ..< 320*50 {
		decompressed[coordinate] = color
	}
	return encodeRunLength(rawData: decompressed)
}

let grayGradient: [UInt8] = [14, 85, 29, 132, 17, 96, 30, 77, 136, 186, 101, 50, 13, 19, 72, 217, 49, 130, 124, 123, 47, 51, 28, 32, 192, 166, 56, 167, 97, 193, 143, 172, 189, 198, 41, 154, 147, 61, 81, 109, 199, 108, 60, 37, 12, 15, 153, 21, 142, 68, 35, 173, 141, 27, 197, 144, 94, 116, 42, 185, 214, 40, 46, 184, 181, 83, 127, 175, 31, 150, 213, 73, 95, 86, 191, 117, 135, 112, 208, 22, 78, 107, 179, 114, 210, 119, 58, 67, 149, 209, 171, 110, 89, 103, 133, 43, 202, 137, 66, 39, 151, 129, 71, 200, 26, 111, 128, 11, 16, 23, 196, 201, 36, 106, 207, 205, 69, 139, 62, 105, 90, 203, 216, 54, 99, 20, 5, 4, 100, 88, 146, 145, 25, 74, 80, 204, 180, 84, 138, 212, 215, 24, 63, 33, 187, 118, 148, 183, 57, 91, 102, 206, 44, 152, 190, 126, 134, 59, 182, 87, 174, 48, 125, 104, 140, 188, 131, 92, 178, 64, 70, 76, 79, 65, 121, 113, 176, 211, 177, 52, 75, 120, 82, 38, 93, 98, 122, 53, 115, 55, 45, 34]
let TransparencyValues: [UInt8] = [194, 168, 163, 160, 6, 155, 2, 229, 227, 222, 219, 195, 165, 164, 169, 161, 170, 162, 158, 9, 8, 3, 230, 226, 228, 221, 220]

let grayIndex: [UInt8] = [0, 0, 0, 0, 180, 179, 0, 0, 0, 0, 0, 158, 84, 52, 38, 85, 159, 42, 0, 53, 179, 87, 125, 161, 196, 186, 155, 95, 63, 41, 45, 112, 64, 198, 255, 91, 164, 82, 245, 149, 104, 73, 100, 144, 209, 254, 105, 60, 219, 56, 51, 62, 240, 250, 177, 252, 66, 204, 134, 215, 81, 76, 171, 197, 229, 233, 147, 134, 90, 169, 230, 152, 55, 116, 186, 241, 232, 46, 126, 232, 187, 77, 244, 109, 191, 40, 118, 218, 182, 141, 173, 205, 226, 247, 98, 117, 44, 67, 248, 179, 181, 50, 207, 141, 222, 172, 165, 127, 81, 78, 140, 155, 123, 236, 130, 251, 100, 120, 201, 132, 243, 234, 250, 59, 58, 220, 212, 110, 157, 151, 56, 226, 42, 143, 214, 122, 48, 146, 193, 170, 223, 93, 88, 69, 97, 184, 183, 75, 201, 136, 113, 150, 211, 87, 74, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65, 67, 0, 0, 0, 138, 70, 93, 218, 111, 237, 240, 227, 129, 190, 108, 216, 203, 107, 102, 49, 200, 225, 70, 211, 119, 64, 68, 0, 0, 162, 95, 72, 80, 154, 163, 145, 175, 188, 168, 208, 166, 125, 137, 132, 239, 194, 114, 102, 194, 176, 56]

/// Maps Grayscale value [0-255] to BMD atem label color values
let grayColorTable: [UInt8] = [14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 85, 85, 29, 132, 96, 96, 30, 77, 136, 136, 186, 101, 50, 13, 19, 72, 72, 217, 124, 124, 123, 47, 51, 51, 28, 192, 166, 56, 167, 193, 143, 189, 198, 198, 41, 154, 147, 61, 81, 109, 199, 199, 108, 37, 12, 12, 15, 153, 153, 142, 68, 68, 35, 173, 173, 197, 197, 144, 144, 94, 116, 116, 214, 214, 40, 40, 46, 184, 184, 181, 83, 127, 175, 31, 150, 213, 73, 73, 95, 86, 191, 117, 135, 135, 112, 208, 208, 78, 107, 179, 179, 114, 210, 210, 67, 67, 149, 149, 209, 171, 110, 110, 103, 133, 133, 43, 202, 137, 66, 39, 39, 151, 129, 71, 200, 200, 111, 128, 128, 11, 16, 23, 23, 196, 201, 36, 106, 207, 205, 205, 69, 139, 62, 105, 90, 203, 203, 216, 54, 99, 99, 4, 100, 88, 146, 145, 74, 74, 80, 204, 180, 180, 84, 138, 138, 215, 24, 24, 63, 33, 187, 187, 148, 183, 183, 57, 91, 102, 102, 206, 44, 190, 190, 126, 134, 134, 59, 182, 174, 174, 48, 125, 104, 104, 140, 188, 188, 131, 178, 64, 64, 70, 79, 79, 65, 121, 113, 113, 176, 211, 211, 177, 75, 120, 120, 82, 38, 93, 93, 98, 122, 122, 115, 55, 45, 45, 34]

/// Maps an 8 bit alpha channel value [0-255] to BMD atem label color values
let transparencyColorTable: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 194, 194, 194, 194, 194, 194, 194, 194, 194, 194, 194, 194, 168, 168, 163, 163, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 155, 155, 2, 2, 229, 229, 227, 227, 222, 219, 219, 219, 219, 219, 219, 219, 195, 195, 195, 195, 195, 195, 195, 195, 165, 165, 165, 164, 164, 164, 169, 169, 169, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 161, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 162, 162, 162, 162, 162, 162, 162, 158, 158, 158, 158, 158, 158, 159, 9, 8, 8, 3, 3, 3, 3, 3, 3, 3, 230, 230, 230, 230, 230, 230, 230, 225, 226, 224, 221, 221, 220, 220]

@available(OSX 10.12, *)
let labelColorSpace = grayIndex.withUnsafeBufferPointer { (buffer) -> CGColorSpace in
	let graySpace = CGColorSpace(name: CGColorSpace.linearGray)!
	return CGColorSpace(indexedBaseSpace: graySpace, last: grayIndex.indices.last!, colorTable: buffer.baseAddress!)!
}

func createGradient() throws -> Data {
	var decompressed = try Data(contentsOf: URL(fileURLWithPath: "/Users/damiaan/Documents/Projecten/ATEM/Research/communication/Change input name/input10 image/decompressed.bin"))
	for (coordinate, color) in TransparencyValues.enumerated() {
		for y in 0..<50 {
			for x in 0..<9 {
				decompressed[y*320 + 9*coordinate + x] = color
			}
		}
	}
	return encodeRunLength(rawData: decompressed)
}
