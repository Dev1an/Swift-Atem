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
	let messageHandler: RespondingMessageHandler
	
	init(handler: RespondingMessageHandler) {
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
				let responses = try messageHandler.handle(messages: client.state.parse(packet))
				var buffer = [UInt8]()
				for response in responses {
					buffer.append(contentsOf: response.serialize())
				}
				for (_, client) in clients {
					client.state.send(message: buffer)
				}
			} catch {
				fatalError(error.localizedDescription)
			}
		}
	}
	
	func send(message: [UInt8]) {
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


/// An interface to
///  - process incoming commands received from one or more controllers
///  - send state change messages to connected controllers
///
/// To make an anology with real world devices: this class can be compared to a BlackMagicDesign Production switcher. It is a state machine and control panels connect to this entity to change its state.
public class Switcher {
	let eventLoop: EventLoopGroup
	
	/// The underlying [NIO](https://github.com/apple/swift-nio) [Datagram](https://apple.github.io/swift-nio/docs/current/NIO/Classes/DatagramBootstrap.html) [Channel](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/Channel.html)
	public let channel: EventLoopFuture<Channel>
	let messageHandler = RespondingMessageHandler()
	
	/// Start a switcher endpoint that controllers can use to connect to.
	public init(eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1), initializer: (RespondingMessageHandler)->Void) throws {
		eventLoop = eventLoopGroup
		let handler = SwitcherHandler(handler: messageHandler)
		initializer(messageHandler)
		channel = DatagramBootstrap(group: eventLoop)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer { $0.pipeline.addHandler(handler) }
			.bind(host: "0.0.0.0", port: 9910)
	}
	
	deinit {
		try? eventLoop.syncShutdownGracefully()
	}
}
