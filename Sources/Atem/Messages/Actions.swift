//
//  MessageTypes.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//

extension Message.Do {
	/// Performs a cut on the atem
	public struct Cut: SerializableMessage {
		public static let title = Message.Title(string: "DCut")
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
}

extension Message.Do {
	/// Performs a auto transition on the atem
	public struct Auto: SerializableMessage {
		public static let title = Message.Title(string: "DAut")
		public let debugDescription = "auto"
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
}

// MARK: - Change Preview Bus
extension Message.Do {
	/// Informs a switcher that the preview bus should be changed
	public struct ChangePreviewBus: SerializableMessage {
		public static let title = Message.Title(string: "CPvI")

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
}
extension Message.Did {
	/// Informs a controller that the preview bus has changed
	public struct ChangePreviewBus: SerializableMessage {
		public static let title = Message.Title(string: "PrvI")

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
}

// MARK: - Change Program Bus
extension Message.Do {
	/// Informs a switcher that the program bus shoud be changed
	public struct ChangeProgramBus: SerializableMessage {
		public static let title = Message.Title(string: "CPgI")

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
}
extension Message.Did {
	/// Informs a controller that the program bus has changed
	public struct ChangeProgramBus: SerializableMessage {
		public static let title = Message.Title(string: "PrgI")

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
}

// MARK: - Change Auxiliary Output
extension Message.Do {
	/// Informs a switcher that a source should be assigned to the specified auxiliary output
	public struct ChangeAuxiliaryOutput: SerializableMessage {
		public static let title = Message.Title(string: "CAuS")

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
}
extension Message.Did {
	/// Informs a controller that a source has been routed to an auxiliary output
	public struct ChangeAuxiliaryOutput: SerializableMessage {
		public static let title = Message.Title(string: "AuxS")

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
}

// MARK: - TimeCode
extension Message.Do {
	public struct GetTimecode: SerializableMessage {
		public static let title = Message.Title(string: "TiRq")

		public init(with bytes: ArraySlice<UInt8>) throws {}
		public init() {}

		public let dataBytes = [UInt8]()
		public let debugDescription = "Command: Request time code"
	}
}
extension Message.Did {
	/// Informs a controller that the switchers timecode has changed
	public struct GetTimecode: SerializableMessage {
		public typealias Timecode = (hour: UInt8, minute: UInt8, second: UInt8, frame: UInt8)
		public static let title = Message.Title(string: "Time")
		public let timecode: Timecode

		public init(hour: UInt8, minute: UInt8, second: UInt8, frame: UInt8) {
			timecode = (hour, minute, second, frame)
		}

		public init(with bytes: ArraySlice<UInt8>) throws {
			timecode = (
				bytes[relative: 0],
				bytes[relative: 1],
				bytes[relative: 2],
				bytes[relative: 3]
			)
		}

		public var dataBytes: [UInt8] {
			[
				timecode.hour,
				timecode.minute,
				timecode.second,
				timecode.frame,
				0,0,3,0xE8
			]
		}

		public var debugDescription: String { return "Switcher time \(timecode)" }
	}
}

// MARK: Transitions
extension Message.Do {
	/// Informs the switcher that it should update its transition position
	public struct ChangeTransitionPosition: SerializableMessage {
		public static let title = Message.Title(string: "CTPs")
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
}
extension Message.Did {
	/// Informs the controller that the transition position has changed
	public struct ChangeTransitionPosition: SerializableMessage {
		public static let title = Message.Title(string: "TrPs")
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
}

// MARK: Tally lights

extension Message.Did {
	/// Informs a controller that the some tally lights might have changed.
	public struct ChangeSourceTallies: SerializableMessage {
		public static let title = Message.Title(string: "TlSr")

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
}

// MARK: Key DVE

import Foundation
extension Message.Do {
	@available(OSX 10.12, iOS 10.0, *)
	public struct ChangeKeyDVE: SerializableMessage {
		public static let title = Message.Title(string: "CKDV")

		public let changedElements: ChangeMask
		public let mixEffectIndex: UInt8
		public let upstreamKey: UInt8
		public let rotation: Measurement<UnitAngle>

		public init(with bytes: ArraySlice<UInt8>) throws {
			changedElements = ChangeMask(rawValue: UInt32(from: bytes[relative: Position.changedElements]))
			mixEffectIndex = bytes[relative: Position.mixEffect]
			upstreamKey = bytes[relative: Position.upstreamKey]
			rotation = Measurement(
				value: Double(UInt32(from: bytes[relative: Position.rotation])) / 10,
				unit: UnitAngle.degrees
			)
		}

		public init(mixEffect: UInt8, key: UInt8, rotation: Measurement<UnitAngle>) {
			changedElements = .rotation
			mixEffectIndex = mixEffect
			upstreamKey = key
			self.rotation = rotation
		}

		public var debugDescription: String {
			"Change Key DVE. \(changedElements)"
		}

		public var dataBytes: [UInt8] {
			.init(unsafeUninitializedCapacity: 64) { (buffer, count) in
				buffer.write(changedElements.rawValue.bigEndian, at: Position.changedElements.lowerBound)
				buffer[Position.mixEffect] = mixEffectIndex
				buffer[Position.upstreamKey] = upstreamKey
				buffer.write(UInt32(rotation.converted(to: .degrees).value * 10).bigEndian, at: Position.rotation.lowerBound)
				count = 64
			}
		}

		enum Position {
			static let changedElements = 0..<4
			static let mixEffect = 4
			static let upstreamKey = 5
			static let rotation = 24..<28
		}

		public struct ChangeMask: OptionSet {
			public let rawValue: UInt32

			public init(rawValue: UInt32) {
				self.rawValue = rawValue
			}

			public static let rotation = Self(rawValue: 1 << 4)
		}
	}
}

// MARK: Change Media Player

public extension Message.Did {
	struct ChangeMediaPlayerFrameDescription: DeserializableMessage {
		public static let title = Message.Title(string: "MPfe")

		public let id: MediaPool.ID
		public let name: String

		public init(with bytes: ArraySlice<UInt8>) throws {
			let bank = bytes[relative: Position.bank]
			let frameIndex = UInt16(from: bytes[relative: Position.frameIndex])
			id = .init(bank: try .decode(from: bank), frame: frameIndex)

			// Read name
			let nameLength = UInt16(from: bytes[relative: Position.nameLength])
			let nameBytes = bytes[relative: Position.name( Int(nameLength) )]
			guard let decodedName = String(bytes: nameBytes, encoding: .utf8) else {
				throw Message.Error.stringNotDecodable(nameBytes)
			}
			name = decodedName
		}

		public var debugDescription: String { "Media player \(id): '\(name)'" }

		enum Position {
			static let bank = 0
			static let frameIndex = 2..<4
			static let nameLength = 22..<24
			static let name = { length in nameLength.endIndex ..< nameLength.endIndex + length }
		}
	}
}

