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
	let messageHandler: PureMessageHandler

	public var whenDisconnected: (()->Void)?
	public var whenError = { (error: Error)->Void in
		print(error)
		fatalError(error.localizedDescription)
	}

	init(address: SocketAddress, messageHandler: PureMessageHandler) {
		self.address = address
		self.messageHandler = messageHandler
	}
	
	final override func channelRead(context: ChannelHandlerContext, data: NIOAny) {
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
			whenError(error)
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
				whenDisconnected?()
			}
		} else if awaitingConnectionResponse {
			let 📦 = SerialPacket.connectToCore(uid: initiationID, type: .connect)
			let data = encode(bytes: 📦.bytes, for: address, in: context)
			context.write(data).whenFailure(whenError)
		} else {
			let 📦 = SerialPacket(connectionUID: initiationID, acknowledgement: 0)
			let data = encode(bytes: 📦.bytes, for: address, in: context)
			context.write(data).whenFailure(whenError)
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
	public let messageHandler = PureMessageHandler()

	let eventLoop: EventLoopGroup
	let handler: ControllerHandler
	
	/// Start a new Controller that connects to an ATEM Switcher specified by its IP address.
	///
	/// When a connection to a switcher is being initialized it will receive `Message`s from the switcher to describe its initial state. If you are interested in these messages use the `setup` parameter to set up handlers for them (see `ControllerConnection.when(...)`). When the connection initiation process is finished the `ConnectionInitiationEnd` message will be sent. From that moment on you know that a connection is succesfully established.
	
	/// - Parameter ipAddress: the IPv4 address of the switcher.
	/// - Parameter eventLoopGroup: the underlying `EventLoopGroup` that will be used for the network connection.
	/// - Parameter setup: a closure that will be called before establishing the connection to the switcher. Use the provided `ControllerConnection` to register callbacks for incoming messages from the switcher.
	public init(ipAddress: String, eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount), setup: (ControllerConnection)->Void = {_ in}) throws {
		eventLoop = eventLoopGroup
		let address = try SocketAddress(ipAddress: ipAddress, port: 9910)
		let tempHandler = ControllerHandler(address: address, messageHandler: messageHandler)
		handler = tempHandler
		setup(handler)
		channel = DatagramBootstrap(group: eventLoop)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer { $0.pipeline.addHandler(tempHandler) }
			.bind(to: try! SocketAddress(ipAddress: "0.0.0.0", port: 0))
	}
	
	
	/// Sends a message to the connected switcher.
	///
	/// - Parameter message: the message that will be sent to the switcher
	public func send(message: Serializable) {
		channel.eventLoop.execute {
			self.handler.send(message)
		}
	}
}

/// A connection of a controller to a switcher. Use it to interact with the switcher: send messages and attach message handlers for incoming `Message`s.
///
/// Message handlers are functions that will be executed when a certain type of Message is received by the `Controller`.
///
/// Attach a handler to a certain type of `Message` by calling
/// ```
/// connection.when { message: <MessageType> in
///		// Handle your message here
/// }
/// ```
/// Replace `<MessageType>` with a concrete type that conforms to the `Message` protocol (eg: `ProgramBusChanged`).
public protocol ControllerConnection {
	/// Sends a message to the connected switcher.
	///
	/// - Parameter message: the message that will be sent to the switcher
	func send(_ message: Serializable)

	/// A function that will be called when the connection is lost
	var whenDisconnected: (()->Void)?   { get set }

	/// A function that will be called when an error occurs
	var whenError: (Error)->Void { get set }

	/// Attaches a message handler to a concrete `Message` type. Every time a message of this type comes in, the provided `handler` will be called.
	/// The handler takes one generic argument `message`. The type of this argument indicates the type that this message handler will be attached to.
	///
	/// - Parameter handler: The handler to attach
	/// - Parameter message: The message to which the handler is attached
	func when<M: Message>(_ handler: @escaping (_ message: M)->Void)
}

extension ControllerHandler: ControllerConnection {
	public final func send(_ message: Serializable) {
		connectionState?.send(message)
	}

	public final func when<M: Message>(_ handler: @escaping (_ message: M)->Void) {
		messageHandler.when(handler)
	}
}
