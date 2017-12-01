//
//  Message.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation

typealias AtemMessageTitle = String
extension AtemMessageTitle {
	var quadBytes: UInt32 {
		return
			UInt32(utf8[utf8.index(utf8.startIndex, offsetBy: 0)]) << 24 +
			UInt32(utf8[utf8.index(utf8.startIndex, offsetBy: 1)]) << 16 +
			UInt32(utf8[utf8.index(utf8.startIndex, offsetBy: 2)]) << 8  +
			UInt32(utf8[utf8.index(utf8.startIndex, offsetBy: 3)])
	}
}

enum MessageError: Error {
	case serialising
}

protocol AtemMessage: CustomDebugStringConvertible {
	static var title: AtemMessageTitle {get}
	init(with bytes: ArraySlice<UInt8>)
}

extension AtemMessage {
	static func prefix() -> [UInt8] { return Self.title.toBytes() }
}

protocol Serializable: AtemMessage {
	var dataBytes: [UInt8] {get}
}

extension Serializable {
	func serialize() -> [UInt8] {
		let data = dataBytes
		return UInt16(data.count).bytes + [0,0] + Self.prefix() + data
	}
}

enum AtemSize: UInt8 {
	case oneME = 0, twoME = 1
}



/// There are two version numbers in ATEM world: One for the ATEM Software Control application (for instance version 6.0) which is what people usually refers to and one for the firmware which is often updated with the PC/Mac application versions (for instance 2.15). The latter version number is what "_ver" gives you and a number you can not find anywhere in the application to our knowledge.
struct ProtocolVersion: Serializable {
	static let title = "_ver"
	static let majorPosition = 0..<2
	static let minorPosition = 2..<4
	let minor, major: UInt16
	
	init(with bytes: ArraySlice<UInt8>) {
		major = UInt16(from: bytes[ProtocolVersion.majorPosition.advanced(by: bytes.startIndex)])
		minor = UInt16(from: bytes[ProtocolVersion.minorPosition.advanced(by: bytes.startIndex)])
	}
	
	init(major: UInt16, minor: UInt16) {
		self.major = major
		self.minor = minor
	}
	
	var dataBytes: [UInt8] { return major.bytes + minor.bytes }
	
	var debugDescription: String { return "Version: \(major).\(minor)"}
}

/// The type of atem
struct AtemType: Serializable {
	static var title = "_pin"
	let string: String
	
	init(with bytes: ArraySlice<UInt8>) {
		do {
			// Stores the string constructed from the first non-zero bytes
			string = try bytes.prefix(upTo: bytes.index {$0==0} ?? 44).toString()
		} catch {
			string = "unable to read product name"
		}
	}
	
	init(string: String) {
		if string.characters.count > 44 {
			self.string = string.substring(to: string.index(string.startIndex, offsetBy: 44))
		} else {
			self.string = string
		}
	}
	
	var dataBytes: [UInt8] {
		switch string.characters.count {
			case 44: return string.toBytes()
			default: return string.toBytes() + Array(repeating: UInt8(0), count: 44 - string.characters.count)
		}
	}
	
	var debugDescription: String {
		return string
	}
}

/// The resources of an atem
struct Topology: Serializable {
	static var title = "_top"
	
	let mixEffectBanks: UInt8
	let sources: UInt8
	let colorGenerators: UInt8
	let auxiliaryBusses: UInt8
	let downstreamKeyers: UInt8
	let stingers: UInt8
	let digitalVideoEffects: UInt8
	let superSources: UInt8
	let standardDefinitionOutput: Bool

	init(with bytes: ArraySlice<UInt8>) {
		mixEffectBanks      = bytes[bytes.startIndex    ]
		sources             = bytes[bytes.startIndex + 1]
		colorGenerators     = bytes[bytes.startIndex + 2]
		auxiliaryBusses     = bytes[bytes.startIndex + 3]
		downstreamKeyers    = bytes[bytes.startIndex + 4]
		stingers            = bytes[bytes.startIndex + 5]
		digitalVideoEffects = bytes[bytes.startIndex + 6]
		superSources        = bytes[bytes.startIndex + 7]
		standardDefinitionOutput = bytes[bytes.startIndex + 9].firstBit
	}
	
	init(mixEffectBanks: UInt8,
		sources: UInt8,
		colorGenerators: UInt8,
		auxiliaryBusses: UInt8,
		downstreamKeyers: UInt8,
		stingers: UInt8,
		digitalVideoEffects: UInt8,
		superSources: UInt8,
		standardDefinitionOutput: Bool) {
		
		self.mixEffectBanks           = mixEffectBanks
		self.sources                  = sources
		self.colorGenerators          = colorGenerators
		self.auxiliaryBusses          = auxiliaryBusses
		self.downstreamKeyers         = downstreamKeyers
		self.stingers                 = stingers
		self.digitalVideoEffects      = digitalVideoEffects
		self.superSources             = superSources
		self.standardDefinitionOutput = standardDefinitionOutput
	}
	
	var dataBytes: [UInt8] {
		return [mixEffectBanks, sources, colorGenerators, auxiliaryBusses, downstreamKeyers, stingers, digitalVideoEffects, superSources, 0, standardDefinitionOutput ? 1:0, 0]
	}
	
	var debugDescription: String {
		return [
			""
		].joined(separator: "\n")
	}
}

/// The message that should be sent at the end of the connection initiation. The connection initiation is the sequence of packets that is sent at the very beginning of a connection and they contain messages that represent the state of the device at the moment of conection.
struct ConnectionInitiationEnd: Serializable {
	static let title = "InCm"
	static let `default` = ConnectionInitiationEnd(with: [])
	let dataBytes = [UInt8(1), 0, 0, 0]

	init(with bytes: ArraySlice<UInt8>) {}
	
	let debugDescription = "End of connection initiation sequence."
}

/// Performs a cut on the atem
struct DoCut: AtemMessage {
	static let title = "DCut"
	let debugDescription = "cut"
	let atemSize : AtemSize
	
	init(with bytes: ArraySlice<UInt8>) {
		atemSize = AtemSize(rawValue: bytes[0])!
	}
}

let messageTypes: [UInt32: AtemMessage.Type] = [
	ProtocolVersion.title.quadBytes: ProtocolVersion.self,
	AtemType.title.quadBytes: AtemType.self,
	Topology.title.quadBytes: Topology.self,
	ConnectionInitiationEnd.title.quadBytes: ConnectionInitiationEnd.self,
	DoCut.title.quadBytes: DoCut.self
]
