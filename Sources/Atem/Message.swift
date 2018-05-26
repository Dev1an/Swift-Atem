//
//  Message.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation

enum MessageError: String, Error {
	case serialising
	case titleNotDeserializable
	
	var localizedDescription: String {
		switch self {
		case .titleNotDeserializable:
			return "MessageError: Unable to decode the title"
		default:
			return "MessageError: \(self.rawValue)"
		}
	}
}

public protocol Message: CustomDebugStringConvertible {
	static var title: MessageTitle {get}
}

/// A message containing a title
protocol InternalMessage: Message {
	init(with bytes: ArraySlice<UInt8>) throws
}

extension InternalMessage {
	static func prefix() -> [UInt8] { return title.number.bytes }
	func execute(_ unknownHandler: Any) {
		let handler = unknownHandler as! (Self)->Void
		handler(self)
	}
}

protocol Serializable: InternalMessage {
	var dataBytes: [UInt8] {get}
}

extension Serializable {
	func serialize() -> [UInt8] {
		let data = dataBytes
		return UInt16(data.count).bytes + [0,0] + Self.prefix() + data
	}
}

enum MessageParseError: Error {
	case unknownMessageTitle(String)
}
