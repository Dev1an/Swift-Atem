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
	var initiationID = ConnectionState.id(firstBit: false)
	var oldConnectionID: UID?
	var awaitingConnectionResponse = true
	let messageHandler: PureMessageHandler
	let address: SocketAddress

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
			if let connectionState = connectionState, packet.connectionUID == connectionState.id {
				try messageHandler.handle(messages: connectionState.parse(packet))
			} else {
				if awaitingConnectionResponse, packet.connectionUID == initiationID {
					print("reconnecting")
					awaitingConnectionResponse = false
				} else if packet.connectionUID != oldConnectionID {
					print("connected, now retreiving initial state")
					let state = ConnectionState(id: packet.connectionUID)
					connectionState = state
					try messageHandler.handle(messages: state.parse(packet))
				}
			}
		} catch {
			whenError(error)
		}
	}

	final override func channelInactive(context: ChannelHandlerContext) {
		super.channelInactive(context: context)
		whenDisconnected?()
		print("lost connection due to channel inactive")
	}
	
	final override func executeTimerTask(context: ChannelHandlerContext) {
		if let state = connectionState {
			let packets = state.assembleOutgoingPackets()
			if let oldestPacketCreationTime = packets.first?.creation {
				if oldestPacketCreationTime < ProcessInfo.processInfo.systemUptime - 1.5 {
					// The state where a packet is not acknowledged after 1.5 seconds
					// is interpreted as a disconnected state.
					resetState()
					whenDisconnected?()
					print("lost connection due to too many unacknowbedged packets")
				} else {
					for packet in packets {
						let data = encode(bytes: packet.bytes, for: address, in: context)
						context.write(data).whenFailure { [weak self] error in
							self?.whenError(error)
						}
					}
				}
			}
		} else if awaitingConnectionResponse {
			let 📦 = SerialPacket.connectToCore(uid: initiationID, type: .connect)
			let data = encode(bytes: 📦.bytes, for: address, in: context)
			context.write(data).whenFailure { [weak self] error in
				self?.whenError(error)
			}
		} else {
			let 📦 = SerialPacket(connectionUID: initiationID, acknowledgement: 0)
			let data = encode(bytes: 📦.bytes, for: address, in: context)
			context.write(data).whenFailure { [weak self] error in
				self?.whenError(error)
			}
		}
		context.flush()
	}

	func resetState() {
		if let oldConnection = connectionState {
			oldConnectionID = oldConnection.id
			connectionState = nil
		}
		awaitingConnectionResponse = true
		initiationID = ConnectionState.id(firstBit: false)
	}
}

public typealias Address = SocketAddress

/// A software based controller that sends messages to an ATEM Switcher.
public class Controller {

	let eventLoop: EventLoopGroup
	let handler: ControllerHandler

	/// The underlying [NIO](https://github.com/apple/swift-nio) [Datagram](https://apple.github.io/swift-nio/docs/current/NIO/Classes/DatagramBootstrap.html) [Channel](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/Channel.html)
	public var channel: EventLoopFuture<Channel>?

	/// Start a new Controller that connects to an ATEM Switcher specified by its IP address.
	///
	/// When a connection to a switcher is being initialized it will receive `Message`s from the switcher to describe its initial state. If you are interested in these messages use the `setup` parameter to set up handlers for them (see ``ControllerConnection``'s ``ControllerConnection/when(_:)``). When the connection initiation process is finished the ``Message/Config/InitiationComplete`` message will be sent. From that moment on you know that a connection is succesfully established.

	/// - Parameter socket: the network socket for the switcher.
	/// - Parameter eventLoopGroup: the underlying `EventLoopGroup` that will be used for the network connection.
	/// - Parameter setup: a closure that will be called before establishing the connection to the switcher. Use the provided `ControllerConnection` to register callbacks for incoming messages from the switcher.
	public init(socket: SocketAddress, eventLoopGroup: EventLoopGroup = sharedEventLoopGroup, setup: (ControllerConnection)->Void = {_ in}) {
		eventLoop = eventLoopGroup
		let messageHandler = PureMessageHandler()
		handler = ControllerHandler(address: socket, messageHandler: messageHandler)
		setup(handler)
		connect()
	}

	/// Start a new Controller that connects to an ATEM Switcher specified by its IP address.
	///
	/// When a connection to a switcher is being initialized it will receive `Message`s from the switcher to describe its initial state. If you are interested in these messages use the `setup` parameter to set up handlers for them (see ``ControllerConnection``'s ``ControllerConnection/when(_:)`` method). When the connection initiation process is finished the ``Message/Config/InitiationComplete`` message will be sent. From that moment on you know that a connection is succesfully established.

	/// - Parameter ipAddress: the IPv4 address of the switcher.
	/// - Parameter eventLoopGroup: the underlying `EventLoopGroup` that will be used for the network connection.
	/// - Parameter setup: a closure that will be called before establishing the connection to the switcher. Use the provided ``ControllerConnection`` to register callbacks for incoming messages from the switcher.
	public convenience init(forSwitcherAt ipAddress: String, eventLoopGroup: EventLoopGroup = sharedEventLoopGroup, setup: (ControllerConnection)->Void = {_ in}) throws {
		let socket = try SocketAddress(ipAddress: ipAddress, port: 9910)
		self.init(socket: socket, eventLoopGroup: eventLoopGroup, setup: setup)
	}

	/// The NIO socket address of the switcher to control.
	public var switcherAddress: SocketAddress { handler.address }

	func connect() {
		let channel = DatagramBootstrap(group: eventLoop)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer {
				$0.pipeline.addHandler(self.handler)
			}
			.bind(to: try! SocketAddress(ipAddress: "0.0.0.0", port: 0))

		self.channel = channel

		channel.whenSuccess {[weak self] channel in
			channel.closeFuture.whenComplete {[weak self] close in
				if let controller = self {
					if case .failure(let error) = close {
						controller.handler.whenError(error)
					}
					controller.eventLoop.next().scheduleTask(in: .seconds(5), controller.connect)
				}
			}
		}
	}
	
	lazy var uploadManager: MediaTransferManager = {
		let manager = MediaTransferManager()
		var lockedStore: UInt16?

		handler.when { [unowned self] (lock: Did.ObtainLock) in
			lockedStore = lock.store
			if let startTransfer = manager.getTransfer(store: lock.store) {
				self.send(message: startTransfer)
			}
		}

		handler.when { [unowned self] (startInfo: Do.RequestDataChunks) in
			for chunk in manager.getChunks(for: startInfo.transferID, preferredSize: startInfo.chunkSize, count: startInfo.chunkCount) {
				self.handler.sendSeparately(messages: chunk)
			}
		}

		handler.when { [unowned self] (completion: Did.FinishDataTransfer) in
			manager.markAsCompleted(transferId: completion.transferID)
			if let store = lockedStore {
				if let startTransfer = manager.getTransfer(store: store) {
					self.send(message: startTransfer)
				} else {
					self.send(message: Do.RequestLock(store: store, state: 0))
					lockedStore = nil
				}
			}
		}

		return manager
	}()

	/// Sends a message to the connected switcher.
	///
	/// - Parameter message: the message that will be sent to the switcher
	public func send(message: SerializableMessage) {
		if let channel = channel {
			channel.eventLoop.execute {
				self.handler.send(message)
			}
		} else {
			handler.whenError(Error.sendMessageWhileNoNetworkConnection)
		}
	}

	enum Error: Swift.Error {
		case sendMessageWhileNoNetworkConnection
	}

	/// Upload an image to the Media Pool
	/// - Parameters:
	///   - slot: The number of the still in the media pool the image will be uploaded to
	///   - data: Raw YUV data. Use `Media.encodeRunLength(data: Data)` to convert an RGBA image to the required YUV format.
	///   - uncompressedSize: The size of the image before run length encoding
	public func uploadStill(slot: UInt16, data: Data, uncompressedSize: UInt32, name: String? = nil, description: String = "") {
		_ = uploadManager.createTransfer(
			store: 0,
			frameNumber: slot,
			data: data,
			uncompressedSize: uncompressedSize,
			mode: .write,
			name: name,
			description: description
		)
		send(message: Do.RequestLockPosition(store: 0, index: slot, type: 1))
	}

	/// Change a ``VideoSource``s names and corresponding label image.
	///
	/// Some ATEM devices cannot render label images on their own and thus require the controller to render the label images. If the ATEM supports it, it will use the image provided by `labelImage` as an overlay to construct its multiview.
	/// - Parameters:
	///   - source: The source id
	///   - labelImage: The new rendered label for the source to use as an overlay in the multiview
	///   - longName: The new full name for the source
	///   - shortName: The new short name for the source
	public func uploadLabel(source: VideoSource, labelImage: Data, longName: String? = nil, shortName: String? = nil) {
		if longName == nil && shortName == nil {
			send(message: VideoSource.DoChangeProperties(input: source.rawValue, longName: String(describing: source), shortName: nil))
		} else {
			send(message: VideoSource.DoChangeProperties(input: source.rawValue, longName: longName, shortName: shortName))
		}
		send(
			message: uploadManager.createTransfer(
				store: 0xFF_FF,
				frameNumber: source.rawValue,
				data: labelImage,
				uncompressedSize: 28800,
				mode: .writeInputLabel,
				name: "Label"
			)
		)
	}

	deinit {
		print("🛑 Shutting down connection", switcherAddress)
		handler.active = false
		channel?.whenSuccess({ (channel) in
			_ = channel.close()
		})
	}
}

/// A connection of a controller to a switcher.
///
/// Use it to interact with the switcher: send messages and attach message handlers for incoming ``DeserializableMessage``s.
///
/// Message handlers are functions that will be executed when a certain type of Message is received by the ``Controller``.
///
/// Attach a handler to a certain type of `Message` by calling
/// ```swift
/// connection.when { message: <MessageType> in
///		// Handle your message here
/// }
/// ```
/// Replace `<MessageType>` with a concrete type that conforms to the ``DeserializableMessage`` protocol (for example <doc:Message/Did/ChangeProgramBus>). Look at `Receiving messages` in``Controller``'s documentation for an example on how to do this.
public protocol ControllerConnection: AnyObject {
	/// Sends a message to the connected switcher.
	///
	/// - Parameter message: the message that will be sent to the switcher
	func send(_ message: SerializableMessage)

	/// Sends the specified messages in a new packet.
	///
	/// - Parameter messages: A binary stream of concatenated messages
	///
	/// Messages are sent in packages. One packet can contain multiple messages. Only use this method when you explicitly need to send your messages in a new packet. Otherwise use ``send(_:)``. The normal ``send(_:)`` method will coalesce messages from different calls and send the in the same package when time and size permits.
	func sendSeparately(messages: [UInt8])

	/// A function that will be called when the connection is lost
	var whenDisconnected: (()->Void)?   { get set }

	/// A function that will be called when an error occurs
	var whenError: (Error)->Void { get set }

	/// Attaches a message handler to a concrete type that implements ``DeserializableMessage``. Every time a message of this type comes in, the provided `handler` will be called.
	/// The handler takes one generic argument `message`. The type of this argument indicates the type that this message handler will be attached to.
	///
	/// - Parameter handler: The handler to attach
	/// - Parameter message: The message to which the handler is attached
	func when<M: Message.Deserializable>(_ handler: @escaping (_ message: M)->Void)
}

extension ControllerHandler: ControllerConnection {
	public final func send(_ message: SerializableMessage) {
		if let state = connectionState {
			state.send(message)
		} else {
			print("👹 Not sending because connectionstate is nil")
		}
	}

	public final func sendSeparately(messages: [UInt8]) {
		if let state = connectionState {
			state.send(message: messages, asSeparatePackage: true)
		} else {
			print("👹 Not sending because connectionstate is nil")
		}
	}

	public final func when<M: Message.Deserializable>(_ handler: @escaping (_ message: M)->Void) {
		messageHandler.when(handler)
	}
}
