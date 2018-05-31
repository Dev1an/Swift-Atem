//
//  MessageHandler.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//
private var messageTypeRegister = [UInt32: Message.Type]()

public class RespondingMessageHandler: MessageHandlerBase<[Serializable]> {
	init() { super.init(emptyResponse: [])}
	
	func handle(messages: [ArraySlice<UInt8>]) throws -> [Serializable] {
		var result = [Serializable]()
		for message in messages {
			result.append(contentsOf: try handle(rawMessage: message))
		}
		return result
	}
}

public class MessageHandler: MessageHandlerBase<Void> {
	init() { super.init(emptyResponse: Void()) }
	
	func handle(messages: [ArraySlice<UInt8>]) throws {
		for message in messages {
			try handle(rawMessage: message)
		}
	}
}

/// A utility to parse binary messages and dispatch the parsed messages to registered handlers.
public class MessageHandlerBase<T> {
	/// A registry with handlers for each message.
	/// The keys in the registry are the message names and the values are functions that interprete and react on a message.
	var registry = [UInt32: Any]()
	
	let emptyResponse: T
	
	init(emptyResponse: T) {
		self.emptyResponse = emptyResponse
	}

	/// Registers a message handler. This is used to subscribe to a specific type of `Message`.
	/// A handler is a function that takes one generic argument `M`. The type of this argument indicates which messages you want to subscribe to.
	///
	/// - Parameter handler: The handler to register
	public func when<M: Message>(_ handler: @escaping (M)->T) {
		messageTypeRegister[M.title.number] = M.self
		registry[M.title.number] = handler
	}
	
	func handle(rawMessage: ArraySlice<UInt8>) throws -> T {
		let titlePosition = MessageTitle.position.advanced(by: rawMessage.startIndex)
		let title = UInt32(from: rawMessage[titlePosition])
		if let handler = registry[title] {
			let type = messageTypeRegister[title]!
			let message = try type.init(with: rawMessage[titlePosition.endIndex...])
			return message.execute(handler)
		}/* else {
			print(String(bytes: rawMessage[titlePosition], encoding: .utf8)!, rawMessage[titlePosition.endIndex...])
		}*/
		return emptyResponse
	}
}
