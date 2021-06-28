//
//  Message.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation

public enum Message {
	/// An ASCII String of exactly 4 characters. A list of available titles can be found in [Skarhoj's protocol description](http://skaarhoj.com/fileadmin/BMDPROTOCOL.html) under the column "CMD".
	public struct Title: CustomStringConvertible {
		/// The position of the title in a message. (Ignoring the first four bytes of a message)
		/// Slice `0 ..< 4`
		static let position = 0 ..< 4

		/// A `UInt32` representation of the title
		let number: UInt32

		init(string: StaticString) {
			assert(string.utf8CodeUnitCount == 4)
			number = string.utf8Start.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee.byteSwapped }
		}

		public var description: String {
			withUnsafeBytes(of: number.byteSwapped) { pointer in
				String(bytes: pointer, encoding: .utf8)!
			}
		}
	}

	// MARK: - Protocols
	public typealias Deserializable = DeserializableMessage
	public typealias Serializable = SerializableMessage

	// MARK: - Errors

	enum Error: Swift.Error {
		case serialising
		case stringTooLong(String, Int)
		case titleNotDeserializable
		case stringNotDecodable(ArraySlice<UInt8>)
		case unknownModel(UInt8)

		var localizedDescription: String {
			switch self {
			case .titleNotDeserializable:
				return "Message.Error: Unable to decode the title"
			case .stringTooLong(let string, let maxLength):
				return "Message.Error: Unable to serialise '\(string)' because it's too long, max length is: \(maxLength) bytes"
			case .serialising:
				return "Message.Error: serialising"
			case .unknownModel(let modelNumber):
				return "Message error: unknown model \(modelNumber)"
			case .stringNotDecodable(let bytes):
				return "Message error: unable to decode \(bytes) as UTF8"
			}
		}
	}

	// MARK: - Messages

	/// Namespace for messages that request an action from the ATEM switcher
	public enum Do {}

	/// Namespace for messages that inform a certain action did complete
	public enum Did {}

	/// Namespace for configuration messages
	public enum Config {}
}

public typealias Do  = Message.Do
public typealias Did = Message.Did
public typealias Config = Message.Config

/// A message that can be constructed from a sequence of bytes (`ArraySlice<UInt8>`)
public protocol DeserializableMessage: CustomDebugStringConvertible {
	/// The title of the message. This is referred to as CMD in [Skarhoj's protocol documentation](http://skaarhoj.com/fileadmin/BMDPROTOCOL.html)
	static var title: Message.Title {get}
	
	/// Initialize a new message from the given binary string
	///
	/// - Parameter bytes: the binary string to interpret
	/// - Throws: when the message cannot be interpreted
	init(with bytes: ArraySlice<UInt8>) throws
}

extension Message.Deserializable {
	static func prefix() -> [UInt8] { return title.number.bytes }
	func execute(_ unknownHandler: Any) {
		let handler = unknownHandler as! (Self)->Void
		return handler(self)
	}
	func execute(_ unknownHandler: Any, in context: ContextualMessageHandler.Context) {
		let handler = unknownHandler as! (Self, ContextualMessageHandler.Context)->Void
		return handler(self, context)
	}
}

/// A `Message` that is serializable. In other words: that can be transformed into a binary format, ready to be sent to another device.
/// Serializable messages use the `Message.title` and `Serializable.dataBytes` properties to compute the serialized message.
public protocol SerializableMessage: Message.Deserializable {
	/// The part of the serialized message starting after the 4 `Message.title` bytes.
	/// This property is used by the `Serializable.serialize()` method
	var dataBytes: [UInt8] {get}
}

extension SerializableMessage {
	public func serialize() -> [UInt8] {
		let data = dataBytes
		return UInt16(data.count + 8).bytes + [0,0] + Self.prefix() + data
	}
}

//public enum Group {
//	/// Sub group A
//	public enum SubA {
//	}
//
//	/// Sub group B
//	public enum SubB {
//		/// Struct One
//		public struct S1 {}
//
//		/// Struct Two
//		public struct S2 {}
//	}
//
//}
//
//public extension Group.SubA {
//	/// Struct One
//	struct S1 {}
//}
//
//extension Group.SubA {
//	/// Struct Two
//	public struct S2 {}
//}
