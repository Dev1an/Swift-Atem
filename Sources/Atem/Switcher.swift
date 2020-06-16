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
	let messageHandler: ContextualMessageHandler
	
	init(handler: ContextualMessageHandler) {
		messageHandler = handler
	}
		
	final override func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		var envelope = unwrapInboundIn(data)
		let packet = Packet(bytes: envelope.data.readBytes(length: envelope.data.readableBytes)!)
		
		if packet.isConnect {
			let newId: UInt16
			if let savedId = connectionIdUpgrades[UInt16(from: packet.connectionUID)] {
				newId = savedId & 0b0111_1111_1111_1111
			} else {
				counter = (counter+1) % 0b0111_1111_1111_1111
				newId = counter
				connectionIdUpgrades[UInt16(from: packet.connectionUID)] = newId | 0b1000_0000_0000_0000
			}
			let initiationPacket = SerialPacket.connectToController(oldUid: packet.connectionUID, newUid: newId.bytes, type: .connect)
			let data = encode(bytes: initiationPacket.bytes, for: envelope.remoteAddress, in: context)
			context.write(data, promise: nil)
			context.flush()
		} else if let newId = connectionIdUpgrades[UInt16(from: packet.connectionUID)] {
			let newConnection = ConnectionState(id: newId.bytes[0...])
			print("new client \(UInt16(from: newConnection.id)) from \(envelope.remoteAddress)")
			for message in initialMessages {
				newConnection.send(message: message)
			}
			clients[newId] = Client(
				address: envelope.remoteAddress,
				state: newConnection
			)
			connectionIdUpgrades.removeValue(forKey: UInt16(from: packet.connectionUID))
		} else if let client = clients[UInt16(from: packet.connectionUID)] {
			do {
				try messageHandler.handle(messages: client.state.parse(packet), in: client.state)
			} catch {
				fatalError(error.localizedDescription)
			}
		}
	}

	/// Queues a block of bytes to be sent to all connected controllers.
	final func send(message: [UInt8]) {
		for (_, client) in clients {
			client.state.send(message: message)
		}
	}
	
	final override func executeTimerTask(context: ChannelHandlerContext) {
		var notRespondingClients = [UInt16]()
		for (id, client) in clients {
			let packets = client.state.assembleOutgoingPackets()
			if packets.count < 50 {
				for packet in packets {
					let data = encode(bytes: packet.bytes, for: client.address, in: context)
					context.write(data).whenFailure{ error in
						print(error)
					}
				}
			} else {
				notRespondingClients.append(id)
			}
		}
		context.flush()
		for key in notRespondingClients {
			clients.removeValue(forKey: key)
			print("client", key, "disconnected")
		}
		notRespondingClients.removeAll()
	}
}

/// An endpoint to interact with BMD ATEM controllers like "Atem Software Control" or any of the hardware control panels.
public class Switcher {
	let eventLoop: EventLoopGroup
	
	/// The underlying [NIO](https://github.com/apple/swift-nio) [Datagram](https://apple.github.io/swift-nio/docs/current/NIO/Classes/DatagramBootstrap.html) [Channel](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/Channel.html)
	public let channel: EventLoopFuture<Channel>
	let messageHandler = ContextualMessageHandler()
	
	/// Start a switcher endpoint that controllers can interact with.
	///
	/// Behaviour of this switcher can be defined using the `setup` parameter. This is a function that will be called with a connections handle before the switcher is started. Use this connection parameter to attach handlers for the messages you want to act upon. See `SwitcherConnections` for more information.
	///
	/// - Parameters:
	///   - eventLoopGroup: The Swift NIO event loop group this switcher will run in.
	///   - setup: A function to setup the behaviour of the switcher.
	public init(eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount), setup: (SwitcherConnections)->Void) {
		print(inputProperties.last!, inputProperties.last!.serialize())
		eventLoop = eventLoopGroup
		let handler = SwitcherHandler(handler: messageHandler)
		setup(handler)
		channel = DatagramBootstrap(group: eventLoop)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer { channel in
				channel.pipeline.addHandler(handler)
			}
			.bind(to: try! SocketAddress(ipAddress: "0.0.0.0", port: 9910))
	}
}

/// Interact with connections to a switcher.
///
/// Used to send messages to all connected controllers and to attach message handlers to incoming `Message`s.
///
/// Handlers are functions that will be executed when a certain type of Message is received by the `Switcher`.
///
public protocol SwitcherConnections {
	/// Queues a message to be sent to all connected controllers.
	///
	/// The message will be serialized immediately into a byte array and appended to the outgoing buffer of all the connected controllers.
	/// These buffers will be flushed after at most 20ms.
	func send(_ message: Serializable)

	/// Attaches a message handler to a concrete `Message` type. Every time a message of this type comes in, the provided `handler` will be called with two parameters: the message itself and the origin of the message.
	/// The handler takes one generic argument `message`. The type of this argument indicates the type that this message handler will be attached to.
	///
	/// - Parameter handler: The handler to attach
	/// - Parameter message: The message to which the handler is attached
	/// - Parameter context: The origin of the message. Use this parameter to reply directly to the sender of the message.
	func when<M: Message>(_ handler: @escaping (_ message: M, _ context: ConnectionState)->Void)
}

extension SwitcherHandler: SwitcherConnections {
	public func send(_ message: Serializable) {
		send(message: message.serialize())
	}

	func when<M: Message>(_ handler: @escaping (_ message: M, _ context: ConnectionState)->Void) {
		messageHandler.when(handler)
	}
}
