//
//  File.swift
//  
//
//  Created by Damiaan on 17/04/2020.
//

import XCTest
@testable import Atem

class MessageTests: XCTestCase {
	func testProductInfo() throws {

		let short = "Short"
		let exact = String(repeating: "a", count: 40)
		let tooLong = String(repeating: "abcd", count: 41)
		let extraLong = String(repeating: "Hello World.", count: 100)

		let testNames = [short, exact, tooLong, extraLong]

		try testNames.map{ Config.ProductInfo(name: $0, model: .mini).dataBytes }.forEach { bytes in
			XCTAssertEqual(bytes.count, 44)
			XCTAssertEqual(try Config.ProductInfo(with: ArraySlice(bytes)).model, .mini)
		}

		for name in [short, exact] {
			let bytes = ArraySlice(Config.ProductInfo(name: name, model: .mini).dataBytes)
			XCTAssertEqual(try Config.ProductInfo(with: bytes).name, name)
		}

		for name in [tooLong, extraLong] {
			let bytes = ArraySlice(Config.ProductInfo(name: name, model: .mini).dataBytes)
			let trimmedName = String(name.prefix(40-3) + "...")
			XCTAssertEqual(try Config.ProductInfo(with: bytes).name, trimmedName)
		}
	}
}
