//
//  File.swift
//  
//
//  Created by Damiaan on 19/04/2020.
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
	static let tooLongNameCount = namePosition.count + 1
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
		"Topology(\n" + ([
			"mixEffectBlocks": mixEffectBlocks,
			"sources": sources,
			"downstreamKeyers": downstreamKeyers,
			"auxiliaryBusses": auxiliaryBusses,
			"mixMinusOutputs": mixMinusOutputs,
			"mediaPlayers": mediaPlayers,
			"serialPorts": serialPorts,
			"maxHyperdecks": maxHyperdecks,
			"stingers": stingers
		] as KeyValuePairs ).map{"\t\($0): \($1),"}.joined(separator: "\n") + "\n)"
	}

}

public struct MixEffectConfiguration: Serializable {
	public static let title = MessageTitle(string: "_MeC")

	/// The block index. Starts counting at 0 so first block is 0
	public let block: UInt8

	/// The number of keyers on this block
	public let numberOfKeyers: UInt8

	public init(with bytes: ArraySlice<UInt8>) throws {
		block = bytes[relative: 0]
		numberOfKeyers = bytes[relative: 1]
	}

	public init(block: UInt8, numberOfKeyers: UInt8) {
		self.block = block
		self.numberOfKeyers = numberOfKeyers
	}

	public var dataBytes: [UInt8] {
		return [block, numberOfKeyers, 0, 0]
	}

	public var debugDescription: String {
		"Mix effect block \(block) has \(numberOfKeyers) keyers"
	}
}

public struct MediaPoolConfiguration: Serializable {
	public static let title = MessageTitle(string: "_mpl")

	/// The number of stills that can be stored
	public let stillCapacity: UInt8
	/// The number of clips that can be stored
	public let clipCapacity: UInt8

	public init(with bytes: ArraySlice<UInt8>) throws {
		stillCapacity = bytes[relative: 0]
		clipCapacity = bytes[relative: 1]
	}

	public init(stills: UInt8, clips: UInt8) {
		stillCapacity = stills
		clipCapacity = clips
	}

	public var dataBytes: [UInt8] {
		return [stillCapacity, clipCapacity, 0, 0]
	}

	public var debugDescription: String {
		"Media pool with capacity for \(stillCapacity) stills and \(clipCapacity) clips"
	}
}

public struct MultiViewConfiguration: Serializable {
	public static let title = MessageTitle(string: "_MvC")

	/// The number inputs that are included in the multiview
	public let inputCount: UInt8
	/// The number multiviews that can be generated
	public let multiviewCount: UInt8

	public let unknown: [UInt8]

	public init(with bytes: ArraySlice<UInt8>) throws {
		inputCount = bytes[relative: 0]
		multiviewCount = bytes[relative: 1]
		unknown = Array(bytes[relative: 2...])
	}

	public init(inputs: UInt8, multiviews: UInt8, unknownBytes: [UInt8]) {
		inputCount = inputs
		multiviewCount = multiviews
		unknown = unknownBytes
	}

	public var dataBytes: [UInt8] {
		return [inputCount, multiviewCount] + unknown
	}

	public var debugDescription: String {
		"\(multiviewCount) multiviews with \(inputCount) inputs"
	}
}
