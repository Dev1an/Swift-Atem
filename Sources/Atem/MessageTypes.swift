//
//  MessageTypes.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//

public enum AtemSize: UInt8 {
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

/// Information about the ATEM product
public struct ProductInfo: Serializable {
	public static let title = MessageTitle(string: "_pin")
	static let namePosition = 0..<40
	static let tooLongNameCount = Self.namePosition.count + 1
	static let truncationDots = Array("...".utf8)
	static let modelPosition = 40

	/// The name of the product
	let name: String
	/// The model of the product
	let model: Model
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		// Stores the string constructed from the first non-zero bytes
		guard let string = String(bytes: bytes.prefix(upTo: bytes[relative: Self.namePosition].firstIndex {$0==0} ?? 40), encoding: .utf8) else {
			throw MessageError.titleNotDeserializable
		}
		let modelNumber = bytes[relative: Self.modelPosition]
		guard let model = Model(rawValue: modelNumber) else {
			throw MessageError.unknownModel(modelNumber)
		}
		self.name = string
		self.model = model
	}
	
	public init(name: String, model: Model) {
		self.name = name
		self.model = model
	}
	
	public var dataBytes: [UInt8] {
		let binaryString = Array(name.utf8).prefix(Self.tooLongNameCount)
		let fixedString: [UInt8]
		switch binaryString.count {
		case Self.tooLongNameCount... :
			fixedString = binaryString.prefix(Self.namePosition.upperBound - Self.truncationDots.count) + Self.truncationDots
		default:
			fixedString = binaryString + Array(repeating: UInt8(0), count: Self.namePosition.count - binaryString.count)
		}
		return fixedString + [model.rawValue, 0, 0, 0]
	}
	
	public var debugDescription: String {
		return name
	}
}

/// The topology of an atem describes all its resources: inputs, outputs, generators, etc.
///
/// References:
///  - [Norwegian government-owned radio and television public broadcasting company](https://github.com/nrkno/tv-automation-atem-connection/issues/79)
///  - [Qt ATEM protocol implementation](https://github.com/petersimonsson/libqatemcontrol/blob/master/qatemconnection.cpp)
public struct Topology: Serializable {
	public static let title = MessageTitle(string: "_top")
	
	public let mixEffectBlocks: UInt8
	public let sources: UInt8
	public let auxiliaryBusses: UInt8
	/// Number of downstream keyers. Tested using simulator and v8.2.1
	public let downstreamKeyers: UInt8
	public let mixMinusOutputs: UInt8
	/// Number of media players. Tested using simulator and v8.2.1
	public let mediaPlayers: UInt8
	/// Maximum number of linked hyperdecks. Tested using simulator and v8.2.1
	public let maxHyperdecks: UInt8
	/// Number of serial ports.
	///
	/// Tested using v8.2.1 and the simulator: When changing this value the tab "Remote" in the settings pane of the official "ATEM Software control" changes
	///  - when `0`: the "*use RS422 control port to*" radio buttons are **disabled**
	///  - when `1`: the "*use RS422 control port to*" radio buttons are **enabled**
	public let serialPorts: UInt8
	public let unknownA: UInt8
	/// Unknown property, it might be the number of *Digital Video Effects* aka *DVE*s
	public let unknownB: UInt8
	/// Number of stingers.
	///
	/// Tested using v8.2.1 and the simulator: When changing this value, the *STING* button under *Transition Style* of the official "ATEM Software control" changes
	///  - when `0`: the *STING* button is **disabled**
	///  - when `1`: the *STING* button is **enabled**
	public let stingers: UInt8
	public let unknownC: [UInt8]

	public init(with bytes: ArraySlice<UInt8>) {
		mixEffectBlocks      = bytes[relative: 0]
		sources             = bytes[relative: 1]
		downstreamKeyers    = bytes[relative: 2]
		auxiliaryBusses     = bytes[relative: 3]
		mixMinusOutputs     = bytes[relative: 4]
		mediaPlayers        = bytes[relative: 5]
		unknownA            = bytes[relative: 6]
		serialPorts         = bytes[relative: 7]
		maxHyperdecks       = bytes[relative: 8]
		unknownB            = bytes[relative: 9]
		stingers            = bytes[relative: 10]
		unknownC            = Array(bytes[relative: 11..<28 ])
	}
	
	public init(mixEffectBlocks: UInt8,
		 sources: UInt8,
		 downstreamKeyers: UInt8,
		 auxiliaryBusses: UInt8,
		 mixMinusOutputs: UInt8,
		 mediaPlayers: UInt8,
		 unknownA: UInt8,
		 serialPorts: UInt8,
		 maxHyperdecks: UInt8,
		 unknownB: UInt8,
		 stingers: UInt8,
		 unknownC: [UInt8]) {
		
		self.mixEffectBlocks          = mixEffectBlocks
		self.sources                  = sources
		self.downstreamKeyers         = downstreamKeyers
		self.auxiliaryBusses          = auxiliaryBusses
		self.mixMinusOutputs          = mixMinusOutputs
		self.mediaPlayers             = mediaPlayers
		self.unknownA                 = unknownA
		self.serialPorts              = serialPorts
		self.maxHyperdecks            = maxHyperdecks
		self.unknownB                 = unknownB
		self.stingers                 = stingers
		self.unknownC                 = unknownC
	}
	
	public var dataBytes: [UInt8] {
		return [mixEffectBlocks, sources, downstreamKeyers, auxiliaryBusses, mixMinusOutputs, mediaPlayers, unknownA, serialPorts, maxHyperdecks, unknownB, stingers] + unknownC
	}
	
	public var debugDescription: String {
		return "Topology(\n" + ([
			"mixEffectBlocks": mixEffectBlocks,
			"sources": sources,
			"auxiliaryBusses": auxiliaryBusses,
			"downstreamKeyers": downstreamKeyers,
			] as KeyValuePairs ).map{"\t\($0): \($1),"}.joined(separator: "\n") + "\n)"
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
public struct DoCut: Serializable {
	public static let title = MessageTitle(string: "DCut")
	public let debugDescription = "cut"
	public let atemSize: AtemSize
	
	public init(with bytes: ArraySlice<UInt8>) {
		atemSize = AtemSize(rawValue: bytes.first!)!
	}
    
	public init(in atemSize: AtemSize) {
		self.atemSize = atemSize
	}

	public var dataBytes: [UInt8] {
		return [atemSize.rawValue] + [0,0,0]
	}
}

/// Informs a switcher that the preview bus should be changed
public struct ChangePreviewBus: Serializable {
	public static let title = MessageTitle(string: "CPvI")

	public let mixEffect: UInt8
	public let previewBus: VideoSource
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		mixEffect = bytes[relative: 0]
		let sourceNumber = UInt16(from: bytes[relative: 2..<4])
		self.previewBus = try VideoSource.decode(from: sourceNumber)
	}
    
	public init(to newPreviewBus: VideoSource, mixEffect: UInt8 = 0) {
		self.mixEffect = mixEffect
		previewBus = newPreviewBus
	}

	public var dataBytes: [UInt8] {
	return [mixEffect, 0] + previewBus.rawValue.bytes
    }
    
	public var debugDescription: String {return "Change preview bus to \(previewBus)"}
}

/// Informs a switcher that the program bus shoud be changed
public struct ChangeProgramBus: Serializable {
	public static let title = MessageTitle(string: "CPgI")

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
	
	public var debugDescription: String {return "Change program bus to \(programBus)"}
}

/// Informs a switcher that a source should be assigned to the specified auxiliary output
public struct ChangeAuxiliaryOutput: Serializable {
	public static let title = MessageTitle(string: "CAuS")

	/// The source that should be assigned to the auxiliary output
	public let source: VideoSource
	/// The auxiliary output that should be rerouted
	public let output: UInt8

	public init(with bytes: ArraySlice<UInt8>) throws {
		output = bytes[relative: 1]
		let sourceNumber = UInt16(from: bytes[relative: 2..<4])
		self.source = try VideoSource.decode(from: sourceNumber)
	}

	/// Create a message to reroute an auxiliary output.
	/// - Parameters:
	///   - output: The source that should be assigned to the auxiliary output
	///   - newSource: The auxiliary output that should be rerouted
	public init(_ output: UInt8, to newSource: VideoSource) {
		self.source = newSource
		self.output = output
	}

	public var dataBytes: [UInt8] {
		return [1, output] + source.rawValue.bytes
	}

	public var debugDescription: String {return "Change Aux \(output) source to source \(source)"}
}

/// Informs a controller that a source has been routed to an auxiliary output
public struct AuxiliaryOutputChanged: Serializable {
    public static let title = MessageTitle(string: "AuxS")
    
	/// The source that has been routed to the auxiliary output
    public let source: VideoSource
	/// The auxiliary output that has received another route
    public let output: UInt8

    public init(with bytes: ArraySlice<UInt8>) throws {
        output = bytes[relative: 0]
        let sourceNumber = UInt16(from: bytes[relative: 2..<4])
        self.source = try VideoSource.decode(from: sourceNumber)
    }
    
	/// Create a message to inform that a source has been routed to an auxiliary output
	/// - Parameters:
	///   - source: The source that has been assigned to the auxiliary output
	///   - output: The auxiliary output that has been rerouted
    public init(source newSource: VideoSource, output newOutput: UInt8) {
        source = newSource
        output = newOutput
    }
    
    public var dataBytes: [UInt8] {
        return [output, 0] + source.rawValue.bytes
    }
    
    public var debugDescription: String {return "Aux \(output) source changed to source \(source)"}
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
		
		public init(source: VideoSource, longName: String, shortName optionalShortName: String? = nil, externalInterfaces: ExternalInterfaces, kind: VideoSource.Kind, availability: Availability, mixEffects: MixEffects) throws {
			let encodedLongName = try encodeAtem(string: longName, length: PropertiesChanged.longNameLength)
			
			let shortName = optionalShortName ?? String(longName.prefix(4))
			let encodedShortName = try encodeAtem(string: shortName, length: PropertiesChanged.shortNameLength)

			var temp = source.rawValue.bytes
			temp += encodedLongName
			temp += encodedShortName
			temp += [
				0x01,
				externalInterfaces.rawValue,
				0x01
			]
			temp += kind.rawValue.bytes
			temp += [
				0x00,
				availability.rawValue,
				mixEffects.rawValue,
				0x1f,
				0x03
			]

			dataBytes = temp
		}
		
		public var debugDescription: String {
			return """
			VideoSource.PropertiesChanged(
				source: .\(String(describing: id!)),
				longName: "\(longName!)",
				shortName: "\(shortName!)",
				externalInterfaces: \(externalInterfaces.description),
				kind: .\(String(describing: kind!)),
				availability: \(availability.description),
				mixEffects: \(mixEffects.description)
			)
			"""
		}
		
		public var id: VideoSource? {
			return VideoSource(rawValue: .init(from: dataBytes[0..<2]))
		}
		public var longName: String? {
			return String(bytes: dataBytes[ 2..<22].prefix {$0 != 0}, encoding: .utf8)
		}
		public var shortName: String? {
			return String(bytes: dataBytes[22..<26].prefix {$0 != 0}, encoding: .utf8)
		}
		public var externalInterfaces: ExternalInterfaces {
			return ExternalInterfaces(rawValue: dataBytes[27] & 0b1_1111)
		}
		public var kind: Kind? {
			return Kind(rawValue: .init(from: dataBytes[29..<31]))
		}
		public var availability: Availability {
			return Availability(rawValue: dataBytes[32] & 0b1_1111)
		}
		public var mixEffects: MixEffects {
			return MixEffects(rawValue: dataBytes[33] & 0b11)
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
