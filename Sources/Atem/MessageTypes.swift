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
public struct ProtocolVersion: Serializable {
	public static let title = MessageTitle(string: "_ver")
	static let majorPosition = 0..<2
	static let minorPosition = 2..<4
	let minor, major: UInt16
	
	public init(with bytes: ArraySlice<UInt8>) {
		major = UInt16(from: bytes[ProtocolVersion.majorPosition.advanced(by: bytes.startIndex)])
		minor = UInt16(from: bytes[ProtocolVersion.minorPosition.advanced(by: bytes.startIndex)])
	}
	
	public init(major: UInt16, minor: UInt16) {
		self.major = major
		self.minor = minor
	}
	
	public var dataBytes: [UInt8] { return major.bytes + minor.bytes }
	
	public var debugDescription: String { return "Version: \(major).\(minor)"}
}

/// The type of atem
struct AtemType: Serializable {
	static let title = MessageTitle(string: "_pin")
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
public struct Topology: Serializable {
	public static let title = MessageTitle(string: "_top")
	
	public let mixEffectBanks: UInt8
	public let sources: UInt8
	public let colorGenerators: UInt8
	public let auxiliaryBusses: UInt8
	public let downstreamKeyers: UInt8
	public let stingers: UInt8
	public let digitalVideoEffects: UInt8
	public let superSources: UInt8
	public let standardDefinitionOutput: Bool
	
	public init(with bytes: ArraySlice<UInt8>) {
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
	
	public init(mixEffectBanks: UInt8,
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
	
	public var dataBytes: [UInt8] {
		return [mixEffectBanks, sources, colorGenerators, auxiliaryBusses, downstreamKeyers, stingers, digitalVideoEffects, superSources, 0, standardDefinitionOutput ? 1:0, 0]
	}
	
	public var debugDescription: String {
		return "Topology(\n" + ([
			"mixEffectBanks": mixEffectBanks,
			"sources": sources,
			"colorGenerators": colorGenerators,
			"auxiliaryBusses": auxiliaryBusses,
			"downstreamKeyers": downstreamKeyers,
			"stingers": stingers,
			"digitalVideoEffects": digitalVideoEffects,
			"superSources": superSources,
			"standardDefinitionOutput": standardDefinitionOutput
			] as DictionaryLiteral ).map{"\t\($0): \($1),"}.joined(separator: "\n") + "\n)"
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

/// Informs a controller that the preview bus has changed
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

/// Informs a controller that the program bus has changed
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

	public var debugDescription: String {return "Program bus changed to \(programBus) on ME\(mixEffect)"}
}

/// Informs a controller that the switchers timecode has changed
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

public struct LockRequest: Serializable {
	public static let title = MessageTitle(string: "LOCK")
	public let store: UInt16
	public let state: UInt16
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		store = UInt16(from: bytes)
		state = UInt16(from: bytes[relative: 2..<4])
	}
	
	public var debugDescription: String {return "Lock store \(store) to \(String(state, radix: 16))"}
	
	public var dataBytes: [UInt8] {
		return store.bytes + state.bytes
	}
}

public struct LockPositionRequest: Message {
	public static let title = MessageTitle(string: "PLCK")
	public let store: UInt16
	public let index: UInt16
	public let type: UInt16
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		store = UInt16(from: bytes)
		index = UInt16(from: bytes[relative: 2..<4])
		type = UInt16(from: bytes[relative: 4..<6])
		print(bytes)
	}
	
	public var debugDescription: String {return "Lock request \(store): for index \(index), type \(type)"}
}

public struct LockChange: Serializable {
	public static let title = MessageTitle(string: "LKST")
	public let store: UInt16
	public let isLocked: Bool
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		store = .init(from: bytes)
		isLocked = bytes[relative: 2] == 1
	}
	
	public init(store: UInt16, isLocked: Bool) {
		self.store = store
		self.isLocked = isLocked
	}
	
	public var dataBytes: [UInt8] {
		return store.bytes + [isLocked ? 1:0, 0]
	}
	
	public var debugDescription: String { return "Lock for store \(store) is \(isLocked ? "established" : "released")" }
}

public struct LockObtained: Serializable {
	public static let title = MessageTitle(string: "LKOB")
	let store: UInt16
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		store = .init(from: bytes)
	}
	
	public init(store: UInt16) {
		self.store = store
	}
	
	public var debugDescription: String { return "Lock obtained" }
	
	public var dataBytes: [UInt8] {
		return store.bytes + [0, 0]
	}
}

extension VideoSource {
	/// The properties (like name and port types) of a video source
	public struct PropertiesChanged: Serializable {
		public static let title: MessageTitle = MessageTitle(string: "InPr")
		public static let shortNameLength = 4
		public static let longNameLength = 20

		public let dataBytes: [UInt8]
		
		public init(with bytes: ArraySlice<UInt8>) throws {
			dataBytes = Array(bytes)
		}
		
		public init(source: VideoSource, longName: String, shortName optionalShortName: String? = nil, kind: VideoSource.Kind, externalInterfaces: ExternalInterfaces, availability: Availability, mixEffects: MixEffects) throws {
			let encodedLongName = try encodeAtem(string: longName, length: PropertiesChanged.longNameLength)
			
			let shortName = optionalShortName ?? String(longName.prefix(4))
			let encodedShortName = try encodeAtem(string: shortName, length: PropertiesChanged.shortNameLength)
			
			
			dataBytes =
				source.rawValue.bytes +
				encodedLongName +
				encodedShortName +
				[
					0x01,
					externalInterfaces.rawValue,
					0x01
				] +
				kind.rawValue.bytes +
				[
					0x00,
					availability.rawValue,
					mixEffects.rawValue,
					0x1f,
					0x03
				]
		}
		
		public var debugDescription: String {
			return "Video source \(String(describing: id)) changed to: \(longName ?? "unknown long name") (\(shortName ?? "unknown short name"))"
		}
		
		public var id: VideoSource? {
			return VideoSource(rawValue: .init(from: dataBytes[0..<2]))
		}
		public var shortName: String? {
			return String(bytes: dataBytes[ 2..<22].prefix {$0 != 0}, encoding: .utf8)
		}
		public var longName: String? {
			return String(bytes: dataBytes[22..<26].prefix {$0 != 0}, encoding: .utf8)
		}
	}
}

/// Informs a controller that a connection is succesfully established.
public struct InitiationComplete: Message {
	public static var title = MessageTitle(string: "InCm")
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		print("InCm", bytes)
	}
	
	public let debugDescription = "Initiation complete"
}


/// Informs a controller that the some tally lights might have changed.
public struct SourceTallies: Serializable {
	public static var title = MessageTitle(string: "TlSr")
	
	/// The state of the tally lights for each source of the Atem switcher
	public let tallies: [VideoSource:TallyLight]
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		let sourceCount = Int(UInt16(from: bytes))
		precondition(sourceCount*3 <= bytes.count-2, "Message is too short, it cannot contain tally info for \(sourceCount) sources")
		
		var tallies = [VideoSource:TallyLight](minimumCapacity: sourceCount)
		for cursor in stride(from: 2, to: sourceCount*3 + 2, by: 3) {
			let source = try VideoSource.decode(from: UInt16(from: bytes[relative: cursor...]))
			tallies[source] = try TallyLight.decode(from: bytes[relative: cursor+2])
		}
		self.tallies = tallies
	}
	
	
	public init(tallies: [VideoSource:TallyLight]) {
		self.tallies = tallies
	}
	
	public var dataBytes: [UInt8] {
		var bytes = [UInt8]()
		bytes.reserveCapacity(2 + tallies.count*3)
		
		bytes.append(contentsOf: UInt16(tallies.count).bytes)
		// Todo: check if sources really need to be sorted
		for (source, tally) in tallies.sorted(by: {$0.0.rawValue < $1.0.rawValue}) {
			bytes.append(contentsOf: source.rawValue.bytes)
			bytes.append(tally.rawValue)
		}
		return bytes
	}
	
	public var debugDescription: String {
		return "Source tallies (\n" +
		"\(tallies.sorted{$0.0.rawValue < $1.0.rawValue}.map{"\t\($0.0): \($0.1)"}.joined(separator: "\n"))" +
		"\n)"
	}
}
