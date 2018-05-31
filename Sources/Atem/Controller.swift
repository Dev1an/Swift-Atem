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
	let messageHandler: MessageHandler
		
	init(address: SocketAddress, messageHandler: MessageHandler) {
		self.address = address
		self.messageHandler = messageHandler
	}
	
	final override func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		var envelope = unwrapInboundIn(data)
		let packet = Packet(bytes: envelope.data.readBytes(length: envelope.data.readableBytes)!)

		do {
			if let connectionState = connectionState {
				let _ = try messageHandler.handle(messages: connectionState.parse(packet))
			} else {
				if awaitingConnectionResponse {
					awaitingConnectionResponse = false
				} else {
					let state = ConnectionState(id: packet.connectionUID)
					connectionState = state
					let _ = try messageHandler.handle(messages: state.parse(packet))
				}
			}
		} catch {
			fatalError(error.localizedDescription)
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
	public let channel: EventLoopFuture<Channel>

	let eventLoop: EventLoopGroup
	let handler: ControllerHandler
	let messageHandler = MessageHandler()
	
	public init(ipAddress: String, eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numThreads: 1), initializer: (MessageHandler)->Void = {_ in}) throws {
		eventLoop = eventLoopGroup
		let address = try SocketAddress(ipAddress: ipAddress, port: 9910)
		let tempHandler = ControllerHandler(address: address, messageHandler: messageHandler)
		handler = tempHandler
		initializer(messageHandler)
		channel = DatagramBootstrap(group: eventLoop)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer { $0.pipeline.add(handler: tempHandler) }
			.bind(to: try! SocketAddress(ipAddress: "0.0.0.0", port: 0))
	}
	
	public func send(message: Serializable) {
		channel.eventLoop.execute {
			self.handler.connectionState?.send(message: message.serialize())
		}
	}
	
	deinit {
		try? eventLoop.syncShutdownGracefully()
	}
}
