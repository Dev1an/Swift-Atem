import XCTest
@testable import Atem

import NIO

class Atem_RTests: XCTestCase {
	
	func testConnectionHandlers() {
		let controller = EmbeddedChannel()
		let switcher = EmbeddedChannel()
		let cEventLoop = controller.eventLoop as! EmbeddedEventLoop
		let sEventLoop = switcher.eventLoop as! EmbeddedEventLoop
		defer {
			let _ = try! controller.finish()
			let _ = try! switcher.finish()
		}
		
		func packet(from data: IOData?) -> (content: Packet, raw: [UInt8])? {
			if case .some(.byteBuffer(var msg)) = data {
				let bytes = msg.readBytes(length: msg.readableBytes)!
				return (Packet(bytes: bytes), bytes)
			} else {
				return nil
			}
		}
		
		func send(bytes: [UInt8], to channel: EmbeddedChannel) {
			var buffer = switcher.allocator.buffer(capacity: bytes.count)
			buffer.write(bytes: bytes)
			try! channel.writeInbound(buffer)
		}
		
		try! controller.pipeline.add(handler: IODataWrapper()).wait()
		try! controller.pipeline.add(handler: EnvelopeWrapper()).wait()
		try! controller.pipeline.add(handler: ControllerHandler(address: try! .init(ipAddress: "10.1.0.100", port: 9910))).wait()
		
		
		try! switcher.pipeline.add(handler: IODataWrapper()).wait()
		try! switcher.pipeline.add(handler: EnvelopeWrapper()).wait()
		try! switcher.pipeline.add(handler: SwitcherHandler()).wait()

		controller.pipeline.fireChannelActive()
		switcher.pipeline.fireChannelActive()
		
		cEventLoop.advanceTime(by: .milliseconds(10))
		sEventLoop.advanceTime(by: .milliseconds(10))
		
		XCTAssertNil(controller.readOutbound())
		cEventLoop.advanceTime(by: .milliseconds(20))

		guard let 📦1 = packet(from: controller.readOutbound()) else {
			XCTFail("No writes")
			return
		}
		XCTAssertNil(controller.readOutbound())
		XCTAssertTrue(📦1.content.isConnect)
		XCTAssertFalse(📦1.content.isRepeated)
		
		send(bytes: 📦1.raw, to: switcher)
		
		guard let 📦2 = packet(from: switcher.readOutbound()) else {
			XCTFail("No writes")
			return
		}
		XCTAssertNil(switcher.readOutbound())
		XCTAssertTrue(📦2.content.isConnect)
		XCTAssertEqual(📦2.raw[12..<14], [2, 0])
		
		send(bytes: 📦2.raw, to: controller)
		
		cEventLoop.advanceTime(by: .milliseconds(20))
		guard let 📦3 = packet(from: controller.readOutbound()) else {
			XCTFail("No writes")
			return
		}
		XCTAssertEqual(📦3.content.acknowledgement, 0)
		
		send(bytes: 📦3.raw, to: switcher)
		sEventLoop.advanceTime(by: .milliseconds(20))
		for number in UInt16(1)...8 {
			guard let 📦 = packet(from: switcher.readOutbound()) else {
				XCTFail("\(number - 1) instead of 9 initial state messages")
				return
			}
			XCTAssertEqual(📦.content.number, number)
			XCTAssertFalse(📦.content.isRepeated)
		}
		
	}
	
//	func testUDPserver() {
//		let _ = try? Switcher()
//	}
//	
//	func testUDPclient() {
//		let _ = try! Controller(ipAddress: "10.1.0.212")
//		let deadline = DispatchSemaphore(value: 0)
//		DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) {
//			deadline.signal()
//		}
//		deadline.wait()
//	}

    static var allTests = [
        ("testConnectionLogic", testConnectionHandlers),
    ]
}
