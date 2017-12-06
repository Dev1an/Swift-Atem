//
//  Packet.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation
public typealias UID = ArraySlice<UInt8>

let headerLength            = 12

let connectionUidPosition   = 2 ..< 4
let acknowledgementPosition = 4 ..< 6
let numberPosition          = 10..<12

/// Slice 4 ..< 8
let messageTitlePosition    = 4 ..< 8

let connectMessagePosition  = 12..<20
let atemConnectMessageBytes: [UInt8] = [2,0,0,6,0,0,0,0]
let controllerConnectMessageBytes: [UInt8] = [1,0,0,0,0,0,0,0]

public struct Packet: CustomDebugStringConvertible {
	public var isRepeated: Bool
	public let isConnect: Bool
	public var number: UInt16?
	public var acknowledgement: UInt16?
	public let connectionUID: UID
	public let messages: [Message]
	
	public init(bytes: [UInt8]) {
		let packetLength = Int(bytes[0] & 0b111) << 8 + Int(bytes[1])
		let type = PacketTypes(rawValue: bytes[0])
		isRepeated = type.contains(.retransmission)
		isConnect =  type.contains(.connect)
		number = type.contains(.sync) || type.contains(.connect) ? UInt16(from: bytes[numberPosition]) : nil
		acknowledgement = type.contains(.acknowledge)            ? UInt16(from: bytes[acknowledgementPosition]) : nil
		connectionUID = bytes[connectionUidPosition]
		if isConnect {
			messages = []
		} else {
			var messages = [Message]()
			var cursor = headerLength
			while cursor < packetLength-1 {
				let length = Int(bytes[cursor]) << 8 + Int(bytes[cursor+1])
				do {
					messages.append(try getMessage(from: bytes[cursor ..< cursor+length]))
				} catch {
					print(error)
				}
				cursor += length
			}
			self.messages = messages
		}
	}
		
	/// A textual representation of the packet
	public var debugDescription: String {
		let uid = UInt16(from: connectionUID[connectionUID.startIndex ..< connectionUID.endIndex])
		if isConnect {
			if let _ = acknowledgement {
				return "AtemPacket acknwoledgement for connect with ID \(uid)" + (isRepeated ? " (repeated)" : "")
			} else {
				return "AtemPacket connect with ID \(uid)" + (isRepeated ? " (repeated)" : "")
			}
		} else {
			if let number = number {
				if let acknowledgement = acknowledgement {
					return "AtemPacket #\(uid):\(number) acknowledges: \(acknowledgement), messages: \(messages)"
				} else {
					return "AtemPacket #\(uid):\(number) messages: \(messages)"
				}
			} else {
				if let acknowledgement = acknowledgement {
					return "AtemPacket #\(uid):/ acknowledges: \(acknowledgement)"
				} else {
					return "AtemPacket #\(uid):/"
				}
			}
		}
	}
}

struct SerialAtemPacket {
	var bytes: [UInt8]
	
	init<C: Collection>(connectionUID: UID, data: C, number: UInt16? = nil, acknowledgement: UInt16? = nil) where C.Iterator.Element == UInt8 {
		bytes = Array(repeating: UInt8(0), count: headerLength) + data
		
		var type = PacketTypes()
		
		bytes[connectionUidPosition] = connectionUID
		if let number = number {
			type.insert(.sync)
			bytes[numberPosition] = ArraySlice(number.bytes)
		}
		if let acknowledgement = acknowledgement {
			type.insert(.acknowledge)
			bytes[acknowledgementPosition] = ArraySlice(acknowledgement.bytes)
		}
		
		bytes[0] = type.rawValue | (UInt8(bytes.count >> 8) & 0b111)
		bytes[1] = UInt8(bytes.count & 0b11111111)
	}
	
	init(connectionUID: UID, number: UInt16? = nil, acknowledgement: UInt16? = nil) {
		self.init(connectionUID: connectionUID, data: [UInt8](), number: number, acknowledgement: acknowledgement)
	}
	
	init(connectionUID: UID, messages: [Serializable], number: UInt16? = nil, acknowledgement: UInt16? = nil) {
		self.init(connectionUID: connectionUID, data: messages.map { $0.serialize() } .joined(), number: number, acknowledgement: acknowledgement)
	}
	
	mutating func makeRetransmission() {
		bytes[0] = bytes[0] | PacketTypes.retransmission.rawValue
	}
	
	/// Creates a connect packet to send to an ATEM Switcher
	static func connectToCore(uid: UID, type: PacketTypes) -> [UInt8] {
		return [type.rawValue, 20, uid.first!, uid.last!, 0, 0, 0, 0, 0, 0, 0, 0] + controllerConnectMessageBytes
	}
	
	/// Creates a connection packet to send to an ATEM Controller such as the PC software or the broadcast panel
	static func connectToController(uid: UID, type: PacketTypes) -> [UInt8] {
		return [type.rawValue, 20, uid.first!, uid.last!, 0, 0, 0, 0, 0, 0, 0, 0] + atemConnectMessageBytes
	}
	
	/// A textual representation of the packet
	var debugDescription: String {
		return "serial packet: \(bytes)"
	}
	
}
