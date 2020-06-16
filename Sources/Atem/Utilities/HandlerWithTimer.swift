//
//  HandlerWithTimer.swift
//  Atem
//
//  Created by Damiaan on 20/05/18.
//

import NIO

let sendInterval = TimeAmount.milliseconds(30)

class HandlerWithTimer: ChannelInboundHandler {
	typealias InboundIn = AddressedEnvelope<ByteBuffer>
	typealias OutboundOut = AddressedEnvelope<ByteBuffer>

	var nextKeepAliveTask: Scheduled<Void>?
	var active = false

	func channelActive(context: ChannelHandlerContext) {
		active = true
		print("channel active")
		startLoop(in: context)
	}
	
	func channelRead(context: ChannelHandlerContext, data: NIOAny) {}
	
	func channelInactive(context: ChannelHandlerContext) {
		nextKeepAliveTask?.cancel()
		active = false
		print("channel inactive")
	}
	
	final func startLoop(in context: ChannelHandlerContext) {
		if active {
			nextKeepAliveTask = context.eventLoop.scheduleTask(in: sendInterval) { [weak self] in
				if let handler = self {
					handler.executeTimerTask(context: context)
					handler.startLoop(in: context)
				}
			}
		}
	}
	
	func executeTimerTask(context: ChannelHandlerContext) {}

	final func encode(bytes: [UInt8], for client: SocketAddress, in context: ChannelHandlerContext) -> NIOAny {
		var buffer = context.channel.allocator.buffer(capacity: bytes.count)
		buffer.writeBytes(bytes)
		return wrapOutboundOut(AddressedEnvelope(remoteAddress: client, data: buffer))
	}
}
