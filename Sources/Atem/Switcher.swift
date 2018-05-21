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
				let name = String(bytes: message[message.startIndex.advanced(by: 4)..<message.startIndex.advanced(by: 8)], encoding: .utf8)!
				switch name {
				case "CPgI":
					let response = [0, 12, 246, 191, 0x50, 0x72, 0x67, 0x49] + message[(8..<12).advanced(by: message.startIndex)]
					client.state.send(message: response)
					print(message)
					print(response)
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
