//
//  MessageHandler.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//

/// A utility to parse binary messages and dispatch the parsed messages to registered handlers.
public class MessageHandler {
	/// A registry with handlers for each message.
	/// The keys in the registry are the message names and the values are functions that interprete and react on a message.
	private var registry = [UInt32: Any]()
	
	
	/// Registers a message handler. This is used to subscribe to a specific type of `Message`.
	/// A handler is a function that takes one generic argument `M`. The type of this argument indicates which messages you want to subscribe to.
	///
	/// - Parameter handler: The handler to register
	public func when<M: Message>(_ handler: @escaping (M)->()) {
		registry[M.title.number] = handler
	}
	
	func handle(rawMessage: ArraySlice<UInt8>) throws {
		let titlePosition = MessageTitle.position.advanced(by: rawMessage.startIndex)
		let title = UInt32(from: rawMessage[titlePosition])
		if let handler = registry[title] {
			let type = messageTypeRegister[title]!
			let message = try type.init(with: rawMessage[titlePosition.endIndex...])
			message.execute(handler)
		}
	}
	
	func handle(messages: [ArraySlice<UInt8>]) throws {
		for message in messages {
			try handle(rawMessage: message)
		}
	}
}

private func eraseType<T>(of closure: @escaping (T)->Void) -> (Any)->Void {
	return { (message: Any) in
		closure( message as! T )
	}
}
