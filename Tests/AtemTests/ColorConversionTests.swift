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
		let yuvBundle = ablarlFrom(rgbaBundle: &rgbaBundle)
	}
}
