//
//  MessageTypes.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//

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

public struct RequestTimeCode: Serializable {
	public static let title = MessageTitle(string: "TiRq")

	public init(with bytes: ArraySlice<UInt8>) throws {}
	public init() {}

	public let dataBytes = [UInt8]()
	public let debugDescription = "Command: Request time code"
}

/// Informs a controller that the switchers timecode has changed
public struct NewTimecode: Serializable {
	public typealias Timecode = (hour: UInt8, minute: UInt8, second: UInt8, frame: UInt8)
	public static let title = MessageTitle(string: "Time")
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
/// This message should be sent at the end of the connection initiation. The connection initiation is the sequence of packets that is sent at the very beginning of a connection and they contain messages that represent the state of the device at the moment of conection.
public struct InitiationComplete: Message {
	public static let title = MessageTitle(string: "InCm")
	
	public init(with bytes: ArraySlice<UInt8>) throws {
		print("InCm", bytes)
	}
	
	public let debugDescription = "Initiation complete"
}


/// Informs a controller that the some tally lights might have changed.
public struct SourceTallies: Serializable {
	public static let title = MessageTitle(string: "TlSr")
	
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

import Foundation

@available(OSX 10.12, iOS 10.0, *)
public struct ChangeKeyDVE: Serializable {
	public static let title = MessageTitle(string: "CKDV")

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
