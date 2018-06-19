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
	
	final override func executeTimerTask(context: ChannelHandlerContext) {
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

/// An interface to
///  - send commands to an ATEM Switcher
///  - react upon incomming state change messages from the ATEM Switcher
///
/// To make an anology with real world devices: this class can be compared to a BlackMagicDesign Control Panel. It is used to control a production switcher.
public class Controller {
	/// The underlying [NIO](https://github.com/apple/swift-nio) [Datagram](https://apple.github.io/swift-nio/docs/current/NIO/Classes/DatagramBootstrap.html) [Channel](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/Channel.html)
	public let channel: EventLoopFuture<Channel>
	public let messageHandler = MessageHandler()

	let eventLoop: EventLoopGroup
	let handler: ControllerHandler
	
	/// Start a new connection to an ATEM Switcher.
	///
	/// When a connection is being initialized it will receive `Message`s from the switcher to describe its initial state. If you are interested in these messages use the `initializer` parameter to set up handlers for them (see `MessageHandlerBase.when(...)`). When this connection initiation process is finished the `ConnectionInitiationEnd` message will be sent. From that moment on you know that a connection is succesfully established.
	
	/// - Parameter ipAddress: the IPv4 address of the switcher.
	/// - Parameter eventLoopGroup: the underlying `EventLoopGroup` that will be used for the network connection.
	/// - Parameter initializer: a closure that will be called before establishing the connection to the switcher. Use the provided `MessageHandler` to register callbacks for incoming messages from the switcher.
	public init(ipAddress: String, eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1), initializer: (MessageHandler)->Void = {_ in}) throws {
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
	
	
	/// Sends a message to the connected switcher.
	///
	/// - Parameter message: the message that will be sent to the switcher
	public func send(message: Serializable) {
		channel.eventLoop.execute {
			self.handler.connectionState?.send(message: message.serialize())
		}
	}
	
	deinit {
		try? eventLoop.syncShutdownGracefully()
	}
}
