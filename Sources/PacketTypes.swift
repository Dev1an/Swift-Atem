//
//  PacketTypes.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation

struct AtemPacketTypes: OptionSet, CustomDebugStringConvertible {
	let rawValue: UInt8
	
	static let sync           = AtemPacketTypes(rawValue: 0b00001000)
	static let connect        = AtemPacketTypes(rawValue: 0b00010000)
	static let retransmission = AtemPacketTypes(rawValue: 0b00100000)
	static let acknowledge    = AtemPacketTypes(rawValue: 0b10000000)
	
	var debugDescription: String {
		return [.retransmission, .sync, .connect, .acknowledge].filter { contains($0) } .map { type -> String in
			switch type {
			case AtemPacketTypes.sync: return "Sync"
			case AtemPacketTypes.connect: return "Connect"
			case AtemPacketTypes.retransmission: return "Retransmission"
			default: return "Acknowledge"
			}
			}.joined(separator: ", ")
	}
}
