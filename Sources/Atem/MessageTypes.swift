//
//  MessageTypes.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//

enum AtemSize: UInt8 {
	case oneME = 0, twoME = 1
}

/// There are two version numbers in ATEM world: One for the ATEM Software Control application (for instance version 6.0) which is what people usually refers to and one for the firmware which is often updated with the PC/Mac application versions (for instance 2.15). The latter version number is what "_ver" gives you and a number you can not find anywhere in the application to our knowledge.
struct ProtocolVersion: Serializable {
	static let title = MessageTitle(string: "_ver")
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
	static var title = MessageTitle(string: "_pin")
	let string: String
	
	init(with bytes: ArraySlice<UInt8>) throws {
		// Stores the string constructed from the first non-zero bytes
		if let string = String(bytes: bytes.prefix(upTo: bytes.index {$0==0} ?? 44), encoding: .utf8) {
			self.string = string
		} else {
			throw MessageError.titleNotDeserializable
		}
	}
	
	init(string: String) {
		if string.count > 44 {
			self.string = String(string[..<string.index(string.startIndex, offsetBy: 44)])
		} else {
			self.string = string
		}
	}
	
	var dataBytes: [UInt8] {
		switch string.count {
		case 44: return Array(string.utf8)
		default: return Array(string.utf8) + Array(repeating: UInt8(0), count: 44 - string.count)
		}
	}
	
	var debugDescription: String {
		return string
	}
}

/// The resources of an atem
struct Topology: Serializable {
	static var title = MessageTitle(string: "_top")
	
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
	static let title = MessageTitle(string: "InCm")
	static let `default` = ConnectionInitiationEnd(with: [])
	let dataBytes = [UInt8(1), 0, 0, 0]
	
	init(with bytes: ArraySlice<UInt8>) {}
	
	let debugDescription = "End of connection initiation sequence."
}

/// Performs a cut on the atem
struct DoCut: Message {
	static let title = MessageTitle(string: "DCut")
	let debugDescription = "cut"
	let atemSize : AtemSize
	
	init(with bytes: ArraySlice<UInt8>) {
		atemSize = AtemSize(rawValue: bytes.first!)!
	}
}

/// Informs a switcher that the preview bus should be changed
public struct ChangePreviewBus: Message {
	public static let title = MessageTitle(string: "CPvI")

	public let mixEffect: UInt8
	public let previewBus: VideoSource
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		mixEffect = bytes[relative: 0]
		let sourceNumber = UInt16(from: bytes[relative: 2..<4])
		self.previewBus = try VideoSource.decode(from: sourceNumber)
	}
	
	public var debugDescription: String {return "Change preview bus to \(previewBus)"}
}

/// Informs a switcher that the program bus shoud be changed
public struct ChangeProgramBus: Message {
	public static let title = MessageTitle(string: "CPgI")

	public let mixEffect: UInt8
	public let programBus: VideoSource
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		mixEffect = bytes[relative: 0]
		let sourceNumber = UInt16(from: bytes[relative: 2..<4])
		self.programBus = try VideoSource.decode(from: sourceNumber)
	}
	
	public var debugDescription: String {return "Change program bus to \(programBus)"}
}

/// Informs a switcher that the preview bus should be changed
public struct PreviewBusChanged: Serializable {
	public static let title = MessageTitle(string: "PrvI")

	public let mixEffect: UInt8
	public let previewBus: VideoSource

	public init(with bytes: ArraySlice<UInt8>) throws {
		mixEffect = bytes[relative: 0]
		let sourceNumber = UInt16(from: bytes[relative: 2..<4])
		previewBus = try VideoSource.decode(from: sourceNumber)
	}
	
	public init(to newPreviewBus: VideoSource, mixEffect: UInt8 = 0) {
		self.mixEffect = mixEffect
		previewBus = newPreviewBus
	}
	
	public var dataBytes: [UInt8] {
		return [mixEffect, 0] + previewBus.rawValue.bytes + [0,0,0,0]
	}
	public var debugDescription: String {return "Preview bus changed to \(previewBus) on ME\(mixEffect)"}
}

/// Informs a switcher that the program bus shoud be changed
public struct ProgramBusChanged: Serializable {
	public static let title = MessageTitle(string: "PrgI")

	public let mixEffect: UInt8
	public let programBus: VideoSource
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		mixEffect = bytes[relative: 0]
		let sourceNumber = UInt16(from: bytes[relative: 2..<4])
		self.programBus = try VideoSource.decode(from: sourceNumber)
	}
	
	public init(to newProgramBus: VideoSource, mixEffect: UInt8 = 0) {
		self.mixEffect = mixEffect
		programBus = newProgramBus
	}
	
	public var dataBytes: [UInt8] {
		return [mixEffect, 0] + programBus.rawValue.bytes
	}

	public var debugDescription: String {return "Program bus changed to \(programBus)"}
}

public struct NewTimecode: Message {
	public typealias Timecode = (hour: UInt8, minute: UInt8, second: UInt8, frame: UInt8)
	public static let title = MessageTitle(string: "Time")
	public let timecode: Timecode
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		timecode = (
			bytes[relative: 0],
			bytes[relative: 1],
			bytes[relative: 2],
			bytes[relative: 3]
		)
	}
	
	public var debugDescription: String { return "Switcher time \(timecode)" }
}

/// Informs the switcher that it should update its transition position
public struct ChangeTransitionPosition: Serializable {
	public static let title = MessageTitle(string: "CTPs")
	public let mixEffect: UInt8
	public let position: UInt16
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		mixEffect = bytes[relative: 0]
		position = UInt16(from: bytes[relative: 2..<4])
	}
	
	public init(to position: UInt16, mixEffect: UInt8 = 0) {
		self.mixEffect = mixEffect
		self.position = position
	}
	
	public var dataBytes: [UInt8] {
		return [mixEffect, 0] + position.bytes
	}
	
	public var debugDescription: String { return "Change transition position of ME\(mixEffect+1) to \(position)"}
}

/// Informs the controller that the transition position has changed
public struct TransitionPositionChanged: Serializable {
	public static let title = MessageTitle(string: "TrPs")
	public let mixEffect: UInt8
	public let position: UInt16
	public let inTransition: Bool
	public let remainingFrames: UInt8
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		mixEffect = bytes[relative: 0]
		inTransition = bytes[relative: 1] == 1
		remainingFrames = bytes[relative: 2]
		position = UInt16(from: bytes[relative: 4..<6])
	}
	
	public init(to position: UInt16, remainingFrames: UInt8, inTransition: Bool? = nil, mixEffect: UInt8 = 0) {
		self.mixEffect = mixEffect
		self.position = position
		if let inTransition = inTransition {
			self.inTransition = inTransition
		} else {
			self.inTransition = (1..<9999).contains(position)
		}
		self.remainingFrames = remainingFrames
	}
	
	public var dataBytes: [UInt8] {
		return [mixEffect, inTransition ? 1:0, remainingFrames, 0] + position.bytes + [0, 0]
	}
	
	public var debugDescription: String { return "Change transition position of ME\(mixEffect+1) to \(position)"}
}
