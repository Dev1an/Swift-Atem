import Foundation

/// Stores all relevant information to keep an ATEM connection alive.
/// Use this store to interprete incoming packets and construct new outgoing packets.
class ConnectionState {
	/// Received packet id's. Contains all the packets that should still be acknowledged
	var received📦IDs = [UInt16]()
	
	/// The id of the last packet that was sent from this connection
	var lastSent📦ID: UInt16
	
	/// List of packets that are ready to be sent, ordered by packet number.
	/// - Attention: adding packets to this list in the wrong order, may cause them never to be sent.
	private var outBox: [SerialPacket]
	
	// List of messages that should be sent
	private var messageOutBox = [UInt8]()
	
	/// The id of the connection. At the initial connection phase this ID is temporarily set. After this phase a permanent ID is assigned.
	private(set) var id: UID

	private init(id: UID, outBox: [SerialPacket], lastSent📦ID: UInt16) {
		self.id = id
		self.outBox = outBox
		self.lastSent📦ID = lastSent📦ID
	}
	
	static func switcher(id: UInt16) -> ConnectionState {
		let idSlice = id.bytes[0..<2]
		return ConnectionState(
			id: idSlice,
			outBox: [
				SerialPacket(connectionUID: idSlice, data: initialMessage1,  number:  1),
				SerialPacket(connectionUID: idSlice, data: initialMessage2,  number:  2),
				SerialPacket(connectionUID: idSlice, data: initialMessage3,  number:  3),
				SerialPacket(connectionUID: idSlice, data: initialMessage4,  number:  4),
				SerialPacket(connectionUID: idSlice, data: initialMessage5,  number:  5),
				SerialPacket(connectionUID: idSlice, data: initialMessage6,  number:  6),
				SerialPacket(connectionUID: idSlice, data: initialMessage7,  number:  7),
				SerialPacket(connectionUID: idSlice, data: initialMessage8,  number:  8),
				SerialPacket(connectionUID: idSlice, number: 9)
			],
			lastSent📦ID: 9
		)
	}
	
	static func controller(id: UID) -> ConnectionState {
		return ConnectionState(
			id: id,
			outBox: [],
			lastSent📦ID: 0
		)
	}
	
	/// Interprets data and returns the messages that it contains
	func parse(_ packet: Packet) -> [ArraySlice<UInt8>] {
		if let packetID = packet.number {
			received📦IDs.sortedInsert(packetID)
			if packet.isConnect {
				outBox.removeAll()
			} else if packetID == 1 {
				id = packet.connectionUID
			}
		}
		if let acknowledgedID = packet.acknowledgement {
			let upperBound = outBox.binarySearch { $0.number < acknowledgedID }
			if upperBound < outBox.endIndex {
				outBox.removeSubrange(0...upperBound)
			}
		}
		return packet.messages
	}
	
	func send(message: [UInt8]) {
		messageOutBox.append(contentsOf: message)
	}
	
	/// Returns packets that aren't acknowledged yet
	/// and marks them as retransmission.
	private func assembleOldPackets() -> [SerialPacket] {
		let originalOutBox = outBox
		for index in outBox.indices { outBox[index].makeRetransmission() }
		let oldPackets: [SerialPacket]
		if received📦IDs.isEmpty {
			oldPackets = originalOutBox
		} else {
			var (index, lastSequentialId) = (0, received📦IDs.first!)
			for id in received📦IDs[1...] {
				if id == lastSequentialId + 1 {
					lastSequentialId += 1
					index += 1
				} else {
					break
				}
			}
			received📦IDs.removeSubrange(...index)
			oldPackets = originalOutBox + [SerialPacket(connectionUID: id, number: nil, acknowledgement: lastSequentialId)]
		}
		
		return oldPackets
	}
	
	func assembleOutgoingPackets() -> [SerialPacket] {
		lastSent📦ID = (lastSent📦ID + 1) % UInt16.max
		let newPacket = SerialPacket(connectionUID: id, data: messageOutBox, number: lastSent📦ID)
		messageOutBox.removeAll(keepingCapacity: true)
		outBox.append(newPacket)
		outBox[outBox.endIndex-1].makeRetransmission()
		return assembleOldPackets() + [newPacket]
	}

	static func id(firstBit: Bool) -> UID {
		let randomNumber = arc4random()
		let  firstByte = UInt8((randomNumber & 0x0700) >> 8)
		let secondByte = UInt8( randomNumber & 0x00FF)
		if firstBit {
			return [firstByte | 0b10000000, secondByte]
		} else {
			return [firstByte & 0b01111111, secondByte]
		}
	}
}
