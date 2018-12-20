//
//  Message.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation

enum MessageError: Error {
	case serialising
	case stringTooLong(String, Int)
	case titleNotDeserializable
	
	var localizedDescription: String {
		switch self {
		case .titleNotDeserializable:
			return "MessageError: Unable to decode the title"
		case .stringTooLong(let string, let maxLength):
			return "MessageError: Unable to serialise '\(string)' because it's too long, max length is: \(maxLength) bytes"
		case .serialising:
			return "MessageError: serialising"
		}
	}
}

/// An interpreted message coming from an ATEM device
public protocol Message: CustomDebugStringConvertible {
	/// The title of the message. This is referred to as CMD in [Skarhoj's protocol documentation](http://skaarhoj.com/fileadmin/BMDPROTOCOL.html)
	static var title: MessageTitle {get}
	
	/// Initialize a new message from the given binary string
	///
	/// - Parameter bytes: the binary string to interpret
	/// - Throws: when the message cannot be interpreted
	init(with bytes: ArraySlice<UInt8>) throws
}

extension Message {
	static func prefix() -> [UInt8] { return title.number.bytes }
	func execute<T>(_ unknownHandler: Any) -> T {
		let handler = unknownHandler as! (Self)->T
		return handler(self)
	}
}

/// A `Message` that is serializable. In other words: that can be transformed into a binary format, ready to be sent to another device.
/// Serializable messages use the `Message.title` and `Serializable.dataBytes` properties to compute the serialized message.
public protocol Serializable: Message {
	/// The part of the serialized message starting after the 4 `Message.title` bytes.
	/// This property is used by the `Serializable.serialize()` method
	var dataBytes: [UInt8] {get}
}

extension Serializable {
	public func serialize() -> [UInt8] {
		let data = dataBytes
		return UInt16(data.count + 8).bytes + [0,0] + Self.prefix() + data
	}
}

enum MessageParseError: Error {
	case unknownMessageTitle(String)
}

public func encodeAtem(string: String, length: Int) throws -> [UInt8] {
	guard string.lengthOfBytes(using: .utf8)<=length else {
		throw MessageError.stringTooLong(string, length)
	}
	let short = string.utf8.prefix(length)
	if short.count == length {
		return Array(short)
	} else {
		return short + [UInt8](repeating: 0, count: length - short.count)
	}
}

