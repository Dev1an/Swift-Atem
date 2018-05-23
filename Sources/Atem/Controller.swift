//
//  Controller.swift
//  Atem
//
//  Created by Damiaan on 9/12/17.
//

import Foundation
import NIO

class ControllerHandler: HandlerWithTimer {

	var connectionState: ConnectionState?
	let address: SocketAddress
	let initiationID = ConnectionState.id(firstBit: false)
	var awaitingConnectionResponse = true
	
	init(address: SocketAddress) {
		self.address = address
	}
	
	final override func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		var envelope = unwrapInboundIn(data)
		let packet = Packet(bytes: envelope.data.readBytes(length: envelope.data.readableBytes)!)

		if let connectionState = connectionState {
			handle(messages: connectionState.parse(packet))
		} else {
			if awaitingConnectionResponse {
				awaitingConnectionResponse = false
			} else {
				let state = ConnectionState(id: packet.connectionUID)
				connectionState = state
				handle(messages: state.parse(packet))
			}
		}
	}
	
	final func handle(messages: [ArraySlice<UInt8>]) {
		for message in messages {
			let name = String(bytes: message[message.startIndex.advanced(by: 4)..<message.startIndex.advanced(by: 8)], encoding: .utf8)!
			print(name)
		}
	}
	
	override func executeTimerTask(context: ChannelHandlerContext) {
		if let state = connectionState {
			let packets = state.assembleOutgoingPackets()
			if packets.count < 50 {
				for packet in packets {
					let data = encode(bytes: packet.bytes, for: address, in: context)
					context.write(data).whenFailure{ error in
						print(error)
					}
				}
			} else {
				connectionState = nil
				awaitingConnectionResponse = true
				print("disconnected")
			}
		} else if awaitingConnectionResponse {
			let 📦 = SerialPacket.connectToCore(uid: initiationID, type: .connect)
			let data = encode(bytes: 📦.bytes, for: address, in: context)
			context.write(data).whenFailure{ error in
				print(error)
			}
		} else {
			let 📦 = SerialPacket(connectionUID: initiationID, acknowledgement: 0)
			let data = encode(bytes: 📦.bytes, for: address, in: context)
			context.write(data).whenFailure{ error in
				print(error)
			}
		}
		context.flush()
	}
}

public class Controller {
	let 🔂 = MultiThreadedEventLoopGroup(numThreads: 1)
	public let channel: EventLoopFuture<Channel>
	let handler: ControllerHandler
	
	public init(ipAddress: String) throws {
		let address = try SocketAddress(ipAddress: ipAddress, port: 9910)
		let tempHandler = ControllerHandler(address: address)
		handler = tempHandler
		channel = DatagramBootstrap(group: 🔂)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer { $0.pipeline.add(handler: tempHandler) }
			.bind(to: try! SocketAddress(ipAddress: "0.0.0.0", port: 0))
	}
	
	public func transition(to position: UInt16) {
		handler.connectionState?.send(message: [0, 12, 203, 167, 67, 84, 80, 115, 0, 43] + position.bytes)
	}
	
	deinit {
		try? 🔂.syncShutdownGracefully()
	}
}
