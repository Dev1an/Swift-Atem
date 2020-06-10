//
//  File.swift
//  
//
//  Created by Damiaan on 05/06/2020.
//

import XCTest
@testable import Atem

class ColorConversionTests: XCTestCase {
	func testGrayscaleRGBtoYUV() {
		var rgbaBundle = [UInt8(255),255,255,255, 0,0,0,255]
		let yuvBundle = ablarlFrom(rgbaBundle: &rgbaBundle).bigEndian

//		let alpha1 = Float32((yuvBundle >> 52) & 0b0000_0011_1111_1111)
		let blue   = Float32((yuvBundle >> 42) & 0b0000_0011_1111_1111) - sInt10End
//		let lum1   = Float32((yuvBundle >> 32) & 0b0000_0011_1111_1111)

//		let alpha2 = Float32((yuvBundle >> 20) & 0b0000_0011_1111_1111)
		let red    = Float32((yuvBundle >> 10) & 0b0000_0011_1111_1111) - sInt10End
		let lum2   = Float32((yuvBundle      ) & 0b0000_0011_1111_1111)

		XCTAssertEqual(lum2, 64)

		XCTAssertEqual(blue, red)
		XCTAssertEqual(blue, 0)
	}
}
