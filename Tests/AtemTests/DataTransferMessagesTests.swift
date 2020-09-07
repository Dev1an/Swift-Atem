//
//  File.swift
//  
//
//  Created by Damiaan on 20/05/2020.
//

import XCTest
@testable import Atem

class DataMessageTests: XCTestCase {

	func testStartDataTransfer() throws {
		let checker = try KeyPathEqualityChecker(
			constructed: Do.StartDataTransfer(transferID: 1, store: 2, frameNumber: 3, size: 4, mode: .write2)
		)

		checker.compare(field: \.transferID)
		checker.compare(field: \.store)
		checker.compare(field: \.frameNumber)
		checker.compare(field: \.size)
		checker.compare(field: \.mode)
	}

	func testContinueDataTransfer() throws {
		let checker = try KeyPathEqualityChecker(
			constructed: Do.RequestDataChunks(transferID: 5, chunkSize: 4, chunkCount: 3)
		)

		checker.compare(field: \.transferID)
		checker.compare(field: \.chunkSize)
		checker.compare(field: \.chunkCount)
		checker.compare(field: \.magicNumber)
		checker.compare(field: \.magicNumber2)
	}

	func testFileDescription() throws {
		let checker = try KeyPathEqualityChecker(
			constructed: Do.SetFileDescription(transferID: .random(in: 0..<500), name: "Naampje", description: "Dit is een beschrijving", hash: Array(194..<210))
		)

		checker.compare(field: \.transferID)
		checker.compare(field: \.name)
		checker.compare(field: \.description)
		checker.compare(field: \.hash)
	}

	func testTransferData() throws {
		let checker = try KeyPathEqualityChecker(
			constructed: Do.TransferData(transferID: .random(in: 0 ..< .max), data: Array(0 ..< .max))
		)

		checker.compare(field: \.transferID)
		checker.compare(field: \.body)
	}

}

class KeyPathEqualityChecker<S: SerializableMessage> {
	let constructed: S
	let parsed: S

	init(constructed: S) throws {
		self.constructed = constructed
		parsed = try S(with: constructed.dataBytes[0...])
	}

	func compare<B: Equatable>(field: KeyPath<S,B>, file: StaticString = #filePath, line: UInt = #line) {
		XCTAssertEqual(constructed[keyPath: field], parsed[keyPath: field], file: (file), line: line)
	}
}
