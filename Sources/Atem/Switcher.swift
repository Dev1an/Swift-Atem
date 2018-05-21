//
//  SwitcherConnection.swift
//  AtemPackageDescription
//
//  Created by Damiaan on 7/12/17.
//

import Foundation
import NIO

struct Client {
	let address: SocketAddress
	let state: ConnectionState
}

class SwitcherHandler: HandlerWithTimer {
	var counter: UInt16 = 0
	var clients = [UInt16: Client]()
	var connectionIdUpgrades = [UInt16: UInt16]()
	var outbox = [NIOAny]()
	let bootDate = Date()
		
	override func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		var envelope = unwrapInboundIn(data)
		let packet = Packet(bytes: envelope.data.readBytes(length: envelope.data.readableBytes)!)
		
		if packet.isConnect {
			print("💋 receiving connection initiation request", packet.connectionUID)
			let newId: UInt16
			if let savedId = connectionIdUpgrades[UInt16(from: packet.connectionUID)] {
				newId = savedId & 0b0111_1111_1111_1111
			} else {
				counter = (counter+1) % 0b0111_1111_1111_1111
				newId = counter
				connectionIdUpgrades[UInt16(from: packet.connectionUID)] = newId | 0b1000_0000_0000_0000
			}
			let initiationPacket = SerialPacket.connectToController(oldUid: packet.connectionUID, newUid: newId.bytes, type: .connect)
			let data = encode(bytes: initiationPacket.bytes, for: envelope.remoteAddress, in: ctx)
			ctx.write(data, promise: nil)
		} else if let newId = connectionIdUpgrades[UInt16(from: packet.connectionUID)] {
			print("💋 creating new connection state", packet.connectionUID)
			clients[newId] = Client(
				address: envelope.remoteAddress,
				state: ConnectionState.switcher(id: newId)
			)
		} else if let client = clients[UInt16(from: packet.connectionUID)] {
			for message in client.state.parse(packet) {
				let namePosition = messageTitlePosition.advanced(by: message.startIndex)
				let name = String(bytes: message[namePosition], encoding: .utf8)!
				switch name {
				case "CPgI":
					let source = UInt16(from: message[(10..<12).advanced(by: message.startIndex)])
					if (1...8).contains(source) {
						// Construct Time
						let components = Calendar(identifier: .gregorian).dateComponents([.hour, .minute, .second, .nanosecond], from: bootDate, to: Date())
						let timeMessage = [0, 16, 0, 0, 84, 105, 109, 101,
										   UInt8(components.hour!),
										   UInt8(components.minute!),
										   UInt8(components.second!),
										   UInt8(components.nanosecond! / 20_000_000),
										   1, 0, 3, 232]
						
						// Construct PrgI
						let PrgIMessage = [0, 12, 1, 232, 0x50, 0x72, 0x67, 0x49] + message[(8..<12).advanced(by: message.startIndex)]
						
						// Construct TlSr
						var TlSrMessage = [UInt8(0), 84, 1, 224, 84, 108, 83, 114, 0, 24, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 3, 0, 0, 4, 0, 0, 5, 0, 0, 6, 2, 0, 7, 0, 0, 8, 0, 3, 232, 0, 7, 209, 0, 7, 210, 0, 11, 194, 0, 11, 195, 0, 11, 204, 0, 11, 205, 0, 15, 170, 0, 19, 146, 0, 19, 156, 0, 39, 26, 0, 39, 27, 0, 27, 89, 0, 27, 90, 0, 31, 65, 0, 1, 0]
						TlSrMessage[12+Int(source)*3] = 1
						
						// Construct TlIn
						var TlInMessage = [UInt8(0), 20, 102, 101, 84, 108, 73, 110, 0, 8, 0, 0, 0, 0, 0, 2, 0, 0, 1, 120]
						TlInMessage[9+Int(source)] = 1
						print(source)
						print(message)
						print(timeMessage)
						print(PrgIMessage)
						print(TlInMessage)
						print(TlSrMessage)
						
						// Send 3 messages
						client.state.send(message: timeMessage + TlInMessage + TlSrMessage + PrgIMessage)
					}
				default:
					print(name)
				}
			}
		}
	}
	
	override func executeTimerTask(context: ChannelHandlerContext) {
		for (_, client) in clients {
			for packet in client.state.assembleOutgoingPackets() {
				let data = encode(bytes: packet.bytes, for: client.address, in: context)
				context.write(data).whenFailure{ error in
					print(error)
				}
			}
		}
		context.flush()
	}
}

class Switcher {
	init() throws {
		let 🔂 = MultiThreadedEventLoopGroup(numThreads: 1)
		let bootstrap = DatagramBootstrap(group: 🔂)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer { $0.pipeline.add(handler: SwitcherHandler()) }
		defer {
			try! 🔂.syncShutdownGracefully()
		}
		
		try bootstrap
			.bind(host: "127.0.0.1", port: 9910)
			.wait()
			.closeFuture
			.wait()
	}
}
