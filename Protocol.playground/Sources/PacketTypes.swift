//
//  PacketTypes.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation

public struct PacketTypes: OptionSet, CustomDebugStringConvertible {
	public let rawValue: UInt8
	
	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
	
	static let sync           = PacketTypes(rawValue: 0b00001000)
	static let connect        = PacketTypes(rawValue: 0b00010000)
	static let retransmission = PacketTypes(rawValue: 0b00100000)
	static let acknowledge    = PacketTypes(rawValue: 0b10000000)
	
	public var debugDescription: String {
		return [.retransmission, .sync, .connect, .acknowledge].filter { contains($0) } .map { type -> String in
			switch type {
			case PacketTypes.sync: return "Sync"
			case PacketTypes.connect: return "Connect"
			case PacketTypes.retransmission: return "Retransmission"
			default: return "Acknowledge"
			}
		}.joined(separator: ", ")
	}
}
