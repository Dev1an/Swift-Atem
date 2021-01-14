//
//  File.swift
//  
//
//  Created by Damiaan on 19/04/2020.
//

public enum AtemSize: UInt8 {
	case oneME = 0, twoME = 1
}

import Foundation

extension Message.Config {

	/// There are two version numbers in ATEM world: One for the ATEM Software Control application (for instance version 6.0), which is what people usually refer to, and one for the firmware which is often updated with the PC/Mac application versions (for instance 2.15). The latter version number is what "_ver" gives you and a number you can not find anywhere in the application to our knowledge.
	public struct ProtocolVersion: SerializableMessage {
		public static let title = Message.Title(string: "_ver")
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
	public struct ProductName: SerializableMessage {
		public static let title = Message.Title(string: "_pin")
		static let namePosition = 0..<44
		static let tooLongNameCount = namePosition.count + 1
		static let truncationDots = Array("...".utf8)
		public let name: String

		public init(with bytes: ArraySlice<UInt8>) throws {
			// Stores the string constructed from the first non-zero bytes
			guard let string = String(bytes: bytes.prefix(upTo: bytes[relative: Self.namePosition].firstIndex {$0==0} ?? 44), encoding: .utf8) else {
				throw Message.Error.titleNotDeserializable
			}
			self.name = string
		}

		public init(name: String) {
			self.name = name
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
			return fixedString
		}

		public var debugDescription: String {
			return name
		}
	}
	
	/// Information about the ATEM product
	public struct ProductInfo: SerializableMessage {
		public static let title = Message.Title(string: "_pin")
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
				throw Message.Error.titleNotDeserializable
			}
			let modelNumber = bytes[relative: Self.modelPosition]
			guard let model = Model(rawValue: modelNumber) else {
				throw Message.Error.unknownModel(modelNumber)
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
	public struct Topology: SerializableMessage {
		public static let title = Message.Title(string: "_top")

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

	public struct MixEffect: SerializableMessage {
		public static let title = Message.Title(string: "_MeC")

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

	public struct MediaPool: SerializableMessage {
		public static let title = Message.Title(string: "_mpl")

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
	
	public struct MacroPool: SerializableMessage {
		public static let title = Message.Title(string: "_MAC")

		/// The number of macro banks that are available
		public let banks: UInt8
		
		public init(with bytes: ArraySlice<UInt8>) throws {
			banks = bytes[relative: 0]
		}

		public init(banks: UInt8) {
			self.banks = banks
		}

		public var dataBytes: [UInt8] {
			return [banks, 0, 0, 0]
		}

		public var debugDescription: String {
			"Number of macros: \(banks)"
		}
	}
	
	public struct MacroProperties: SerializableMessage {
		public static let title = Message.Title(string: "MPrp")
		static let defaultText = " ".data(using: .utf8)! + [0]
		
		/// The number of macro banks that are available
		public let macroIndex: UInt8
		public let isUsed: Bool
		public let nameLength: UInt16
		public let descriptionLength: UInt16
		public let nameBytes: ArraySlice<UInt8>
		public let descriptionBytes: ArraySlice<UInt8>
		
		public var name: String? {
			String(bytes: nameBytes, encoding: .utf8)
		}
		public var description: String? {
			String(bytes: descriptionBytes, encoding: .utf8)
		}
		
		public init(with bytes: ArraySlice<UInt8>) throws {
			self.macroIndex = bytes[relative: 1]
			self.isUsed = bytes[relative: 2] == 1
			self.nameLength = UInt16(from: bytes[relative: 4..<6])
			self.descriptionLength = UInt16(from: bytes[relative: 6..<8])
			
			let nameEnd: Int = Int(8 + nameLength)
			self.nameBytes = bytes[relative: 8..<nameEnd]
			
			let descriptionEnd: Int = nameEnd + Int(descriptionLength)
			
			self.descriptionBytes = bytes[relative: nameEnd..<descriptionEnd]
		}

		public init(macroIndex: UInt8, isUsed: Bool, name: String, description: String) {
			self.macroIndex = macroIndex
			self.isUsed = isUsed
			self.nameBytes = ArraySlice(name.data(using: .utf8) ?? MacroProperties.defaultText)
			self.descriptionBytes = ArraySlice(description.data(using: .utf8) ?? MacroProperties.defaultText)
			self.nameLength = UInt16(name.count)
			self.descriptionLength = UInt16(description.count)
		}

		public var dataBytes: [UInt8] {
			let isUsedInt: UInt8 = isUsed == true ? 1 : 0
			
			return [0, macroIndex, isUsedInt, 0] + nameLength.bytes + descriptionLength.bytes + nameBytes + descriptionBytes
		}

		public var debugDescription: String {
			"Macro: \(macroIndex)\nisUsed: \(isUsed)\nName: \(name ?? "No Name")\nDescription: \(description ?? "No Description")\n"
		}
	}

	public struct MultiView: SerializableMessage {
		public static let title = Message.Title(string: "_MvC")

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

	/// Informs a controller that a connection is succesfully established.
	/// This message should be sent at the end of the connection initiation. The connection initiation is the sequence of packets that is sent at the very beginning of a connection and they contain messages that represent the state of the device at the moment of conection.
	public struct InitiationComplete: SerializableMessage {
		public static let title = Message.Title(string: "InCm")

		public init(with bytes: ArraySlice<UInt8>) throws {
			print("InCm", bytes)
		}

		public let dataBytes = [UInt8(1), 0, 0, 0]

		public let debugDescription = "Initiation complete"
	}
}

public extension Message.Do {
	/// See `VideoSource.DoChangeProperties`
	typealias ChangeSourceProperties = VideoSource.DoChangeProperties
}

public extension Message.Did {
	/// See `VideoSource.DidChangeProperties`
	typealias ChangeSourceProperties = VideoSource.DidChangeProperties
}

extension VideoSource {
	/// The properties (like name and port types) of a video source
	public struct DidChangeProperties: SerializableMessage {
		public static let title: Message.Title = Message.Title(string: "InPr")
		static let defaultText = " ".data(using: .utf8)! + [0]

		// MARK: - Properties
		public let id: VideoSource
		public let longNameBytes: ArraySlice<UInt8>
		public let shortNameBytes: ArraySlice<UInt8>
		public let externalInterfaces: ExternalInterfaces
		public let rawKind: UInt16
		public let routingOptions: RoutingOptions
		public let mixEffects: MixEffects

		public var longName: String? {
			String(bytes: longNameBytes, encoding: .utf8)
		}
		public var shortName: String? {
			String(bytes: shortNameBytes, encoding: .utf8)
		}
		public var kind: Kind? { Kind(rawValue: rawKind) }

		// MARK: - Initialisation

		/// Initialize from a byte array
		public init(with bytes: ArraySlice<UInt8>) throws {
			assert(bytes.count > Position.last)
			id = VideoSource(rawValue: UInt16(from: bytes[relative: Position.id]))
			longNameBytes = bytes[relative: Position.longName].prefix {$0 != 0}
			shortNameBytes = bytes[relative: Position.shortName].prefix {$0 != 0}
			externalInterfaces = .init(rawValue: bytes[relative: Position.externalInterfaces])
			rawKind = UInt16(from: bytes[relative: Position.kind])
			routingOptions = RoutingOptions(rawValue: bytes[relative: Position.routingOptions])
			mixEffects = MixEffects(rawValue: bytes[relative: Position.mixEffects])
		}

		/// Manual initialization
		public init(source: VideoSource, longName: String, shortName: String, externalInterfaces: ExternalInterfaces, kind: VideoSource.Kind, routingOptions: RoutingOptions, mixEffects: MixEffects) {
			id = source
			longNameBytes = ArraySlice(longName.data(using: .utf8) ?? DidChangeProperties.defaultText)
			shortNameBytes = ArraySlice(shortName.data(using: .utf8) ?? DidChangeProperties.defaultText)
			self.externalInterfaces = externalInterfaces
			rawKind = kind.rawValue
			self.routingOptions = routingOptions
			self.mixEffects = mixEffects
		}

		// MARK: - Serialization

		public var dataBytes: [UInt8] {
			[UInt8](unsafeUninitializedCapacity: 36) { (buffer, count) in
				buffer.write(id.rawValue.bigEndian, at: Position.id.lowerBound)
				buffer.write(data: Data(longNameBytes), to: Position.longName)
				buffer.write(data: Data(shortNameBytes), to: Position.shortName)
				buffer.write(UInt16.zero, at: Position.unknownA.lowerBound)
				buffer[Position.isExternal] = !(kind?.isInternal ?? false) ? 1 : 0
				buffer[Position.externalInterfaces] = externalInterfaces.rawValue
				buffer[Position.unknownB] = 0
				buffer.write(rawKind.bigEndian, at: Position.kind.lowerBound)
				buffer[Position.unknownC] = 0
				buffer[Position.routingOptions] = routingOptions.rawValue
				buffer[Position.mixEffects] = mixEffects.rawValue
				count = 36
			}
		}

		public var debugDescription: String {
			return """
			VideoSource.DoChangeProperties(
				source: .\(String(describing: id)),
				longName: "\(longName!)",
				shortName: "\(shortName!)",
				externalInterfaces: \(externalInterfaces.description),
				kind: .\(kind.map{String(describing: $0)} ?? ".raw(\(rawKind)"),
				availability: \(routingOptions.description),
				mixEffects: \(mixEffects.description)
			)
			"""
		}

		enum Position {
			static let id = 0..<2
			static let longName = 2..<22
			static let shortName = 22..<26
			static let unknownA = 26..<28
			static let isExternal = 28
			static let externalInterfaces = 29
			static let unknownB = 30
			static let kind = 31..<33
			static let unknownC = 33
			static let routingOptions = 34
			static let mixEffects = 35

			static let last = Position.mixEffects
		}
	}

	public struct DoChangeProperties: SerializableMessage {
		public static let title = Message.Title(string: "CInL")

		public let changeMask: ChangeMask
		public let input: UInt16
		public let longName: String
		public let shortName: String

		public init(with bytes: ArraySlice<UInt8>) throws {
			fatalError("unimplemented")
		}

		public init(input: UInt16, longName: String?, shortName: String?) {
			self.input = input

			var changedElements = ChangeMask(rawValue: 0)
			if let longName = longName {
				assert(longName.count <= Position.longName.count) // TODO check ascii byte length
				changedElements.insert(.longName)
				self.longName = longName
			} else {
				self.longName = "! Not Set !"
			}
			if let shortName = shortName {
				assert(shortName.count <= Position.shortName.count) // TODO check ascii byte length
				changedElements.insert(.shortName)
				self.shortName = shortName
			} else {
				self.shortName = "! Not Set !"
			}

			self.changeMask = changedElements
		}

		public var debugDescription: String {
			"Change input properties \(changeMask)"
		}

		public var dataBytes: [UInt8] {
			.init(unsafeUninitializedCapacity: 32) { (buffer, count) in
				buffer[Position.changeMask] = changeMask.rawValue
				buffer[Position.changeMask + 1] = 0 // unknown byte
				buffer.write(input.bigEndian, at: Position.input.lowerBound)
				if changeMask.contains(.longName) { buffer.write(longName, to: Position.longName) }
				if changeMask.contains(.shortName) { buffer.write(longName, to: Position.shortName) }

				buffer.write(UInt16(0), at: 30) // TODO may be removed
				count = 32
			}
		}

		enum Position {
			static let changeMask = 0
			static let input = 2..<4
			static let longName = 4..<24
			static let shortName = 24..<28
			static let externalPortType = 28..<30
		}

		public struct ChangeMask: OptionSet {
			public let rawValue: UInt8

			public init(rawValue: UInt8) {
				self.rawValue = rawValue
			}

			public static let longName  = Self(rawValue: 1 << 0)
			public static let shortName = Self(rawValue: 1 << 1)
			public static let externalPortType = Self(rawValue: 1 << 2)
		}
	}
}
