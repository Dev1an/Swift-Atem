import XCTest
@testable import Atem

class Atem_RTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
		var controller = ConnectionState.controller()
		let firstMessages = controller.constructKeepAlivePackets()
		XCTAssertEqual(firstMessages.count, 1)
		var switcher = ConnectionState.switcher(interpreting: firstMessages.first!.bytes)
		let a1 = switcher.constructKeepAlivePackets()
		for answer in a1 {
			controller.interpret(answer.bytes)
		}
		for answer in controller.constructKeepAlivePackets() {
			switcher.interpret(answer.bytes)
		}
		let a2 = switcher.constructKeepAlivePackets()
		XCTAssertEqual(a2.count, 1)
		XCTAssertEqual(a2[0].number, 15)
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
