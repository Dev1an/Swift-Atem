//
//  MessageHandler.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//

/// A utility to parse `RawMessage`s and call their attached handlers within a certain context.
/// This class is similar to `PureMessageHandler` with the difference that the registered handlers are also passed a certain context in addition to the attached message. This context can be used to determine where the message comes from.
public class ContextualMessageHandler: MessageParser {
	public typealias Context = ConnectionState

	/// Attaches a message handler to a concrete `Message` type. Every time a message of this type comes in, the provided `handler` will be called.
	/// The handler takes one generic argument `message`. The type of this argument indicates the type that this message handler will be attached to.
	///
	/// - Parameter handler: The handler to attach
	/// - Parameter message: The message to which the handler is attached
	/// - Parameter context: The context `message` was sent from.
	public func when<M: Message.Deserializable>(_ handler: @escaping (_ message: M, _ context: Context)->Void) {
		eventRegister[M.title.number] = M.self
		handlerRegister[M.title.number] = handler
	}

	final func handle(rawMessage: RawMessage, in context: Context) throws {
		if let (message, handler) = try self.message(from: rawMessage) {
			message.execute(handler, in: context)
		}
	}

	final func handle(messages: [RawMessage], in context: Context) throws {
		for message in messages {
			try handle(rawMessage: message, in: context)
		}
	}
}

/// A utility to parse `RawMessage`s and call their attached handlers.
///
/// Handlers are functions that will be executed when `handle(rawMessage: RawMessage)` is called. Handlers are attached to a specific `Message` type for example: `ProgramBusChanged`.
public class PureMessageHandler: MessageParser {

	/// Attaches a message handler to a concrete `Message` type. Every time a message of this type comes in, the provided `handler` will be called.
	/// The handler takes one generic argument `message`. The type of this argument indicates the type that this message handler will be attached to.
	///
	/// - Parameter handler: The handler to attach
	/// - Parameter message: The message to which the handler is attached
	public func when<M: Message.Deserializable>(_ handler: @escaping (_ message: M)->Void) {
		eventRegister[M.title.number] = M.self
		handlerRegister[M.title.number] = handler
	}

	/// Parse a message and if it is of a known type and there is a handler attached to this type, execute the handler.
	final func handle(rawMessage: RawMessage) throws {
		if let (message, handler) = try self.message(from: rawMessage) {
			message.execute(handler)
		}
	}

	/// Same as `handle(rawMessage: RawMessage)` but for multiple messages.
	final func handle(messages: [ArraySlice<UInt8>]) throws {
		for message in messages {
			try handle(rawMessage: message)
		}
	}
}

/// A sequence of bytes
public typealias RawMessage = ArraySlice<UInt8>

/// A utility to parse binary messages and look up corresponding message handlers.
public class MessageParser {
	/// A registry with handlers for each message.
	/// The keys in the registry are the message names and the values are functions that interprete and react on a message.
	fileprivate var eventRegister = [UInt32: Message.Deserializable.Type]()
	fileprivate var handlerRegister = [UInt32: Any]()

	fileprivate final func message(from bytes: RawMessage) throws -> (Message.Deserializable, Any)? {
		let titlePosition = Message.Title.position.advanced(by: bytes.startIndex)
		let title = UInt32(from: bytes[titlePosition])
//		print(String(bytes: bytes[titlePosition], encoding: .utf8))
		if let handler = handlerRegister[title] {
			let type = eventRegister[title]!
			let message = try type.init(with: bytes[titlePosition.endIndex...])
			return (message, handler)
		} else {
//			print(String(bytes: rawMessage[titlePosition], encoding: .utf8)!, rawMessage[titlePosition.endIndex...])
			return nil
		}
	}
}
