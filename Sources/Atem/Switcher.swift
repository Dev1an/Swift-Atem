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

let sendInterval = TimeAmount.milliseconds(20)

class SwitcherHandler: ChannelInboundHandler {
	var counter: UInt8 = 0
	var clients = [UInt16: Client]()
	var nextKeepAliveTask: Scheduled<Void>?
	var outbox = [NIOAny]()
	
	typealias InboundIn = AddressedEnvelope<ByteBuffer>
	typealias OutboundOut = AddressedEnvelope<ByteBuffer>
	
	func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		var envelope = unwrapInboundIn(data)
		let packet = Packet(bytes: envelope.data.readBytes(length: envelope.data.readableBytes)!)
		
		if packet.isConnect {
			let initiationPacket = SerialPacket.connectToController(uid: packet.connectionUID, type: .connect)
			var buffer = ctx.channel.allocator.buffer(capacity: initiationPacket.bytes.count)
			buffer.write(bytes: initiationPacket.bytes)
			let initiationEnvelope = AddressedEnvelope(remoteAddress: envelope.remoteAddress, data: buffer)
			ctx.write(wrapOutboundOut(initiationEnvelope), promise: nil)
		} else if let client = clients[UInt16(from: packet.connectionUID)] {
			for message in client.state.parse(packet) {
				let name = message[message.startIndex.advanced(by: 4)..<message.startIndex.advanced(by: 8)]
				print(String(bytes: name, encoding: .utf8)!)
			}
		} else {
			clients[UInt16(from: packet.connectionUID)] = Client(
				address: envelope.remoteAddress,
				state: ConnectionState.switcher(initialPacket: packet)
			)
		}
	}
	
	func channelActive(ctx: ChannelHandlerContext) {
		startLoop(in: ctx)
	}
	
	func channelInactive(ctx: ChannelHandlerContext) {
		nextKeepAliveTask?.cancel()
	}
	
	func startLoop(in context: ChannelHandlerContext) {
		nextKeepAliveTask = context.eventLoop.scheduleTask(in: sendInterval) {
			self.keepClientsAwake(context: context)
			self.startLoop(in: context)
		}
	}
	
	func keepClientsAwake(context: ChannelHandlerContext) {
		for (_, client) in clients {
			for packet in client.state.constructKeepAlivePackets() {
				let data = encode(bytes: packet.bytes, for: client.address, in: context)
				context.write(data, promise: nil)
			}
		}
		context.flush()
	}
	
	func encode(bytes: [UInt8], for client: SocketAddress, in context: ChannelHandlerContext) -> NIOAny {
		var buffer = context.channel.allocator.buffer(capacity: bytes.count)
		buffer.write(bytes: bytes)
		return wrapOutboundOut(AddressedEnvelope(remoteAddress: client, data: buffer))
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
