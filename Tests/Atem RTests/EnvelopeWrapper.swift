//
//  TestConvertor.swift
//  Atem
//
//  Created by Damiaan on 20/05/18.
//

import NIO

final class IODataWrapper: ChannelOutboundHandler {
	typealias OutboundIn = AddressedEnvelope<ByteBuffer>
	typealias OutboundOut = IOData
	
	func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
		let envelope = unwrapOutboundIn(data)
		ctx.write(wrapOutboundOut(IOData.byteBuffer(envelope.data)), promise: promise)
	}
}

final class EnvelopeWrapper: ChannelInboundHandler {
	typealias InboundIn = ByteBuffer
	typealias InboundOut = AddressedEnvelope<ByteBuffer>

	func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		let buffer = unwrapInboundIn(data)
		ctx.fireChannelRead(wrapInboundOut(AddressedEnvelope(remoteAddress: try! .init(ipAddress: "10.1.0.10", port: 9910), data: buffer)))
	}
}
