import Foundation

#if os(macOS)
let random = arc4random
#endif


/// Stores all relevant information to keep an ATEM connection alive.
/// Use this store to interprete incoming packets and construct new outgoing packets.
class ConnectionState {
	#if os(Linux)
	    private static let seed: Void = srandom(UInt32(time(nil)))
	#endif

	/// Received packet id's. Contains all the packets that should still be acknowledged
	var received📦IDs = [UInt16]()
	
	/// The id of the last packet that was sent from this connection
	var lastSent📦ID: UInt16 = 0
	
	/// List of packets that are ready to be sent, ordered by packet number.
	/// - Attention: adding packets to this list in the wrong order, may cause them never to be sent.
	private var packetOutBox = [SerialPacket]()
	
	// List of messages that should be sent
	private var messageOutBox = [UInt8]()
	private var messageOutBoxPages = [Int]()
	
	/// The id of the connection. At the initial connection phase this ID is temporarily set. After this phase a permanent ID is assigned.
	private(set) var id: UID

	init(id: UID) {
		self.id = id
	}
	
	/// Interprets data and returns the messages that it contains
	func parse(_ packet: Packet) -> [ArraySlice<UInt8>] {
		if let packetID = packet.number {
			received📦IDs.sortedInsert(packetID)
			if packet.isConnect {
				packetOutBox.removeAll()
			} else if packetID == 1 {
				id = packet.connectionUID
			}
		}
		if let acknowledgedID = packet.acknowledgement {
			let upperBound = packetOutBox.binarySearch { $0.number < acknowledgedID }
			if upperBound < packetOutBox.endIndex {
				packetOutBox.removeSubrange(0...upperBound)
			}
		}
		return packet.messages
	}
	
	func send(message: [UInt8]) {
		let oldCount = messageOutBox.count
		messageOutBox.append(contentsOf: message)
		if messageOutBox.count > 1420 {
			messageOutBoxPages.append(oldCount)
		}
	}
	
	/// Returns old packets that aren't acknowledged yet together with new packets
	func assembleOutgoingPackets() -> [SerialPacket] {
		// Retreive the number of the first missing packet
		let acknowledgementNumber: UInt16?
		if received📦IDs.isEmpty {
			acknowledgementNumber = nil
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
			acknowledgementNumber = lastSequentialId
		}
		var newPackets = [SerialPacket]()
		newPackets.reserveCapacity(messageOutBoxPages.count+1)
		var startIndex = 0
		for endIndex in messageOutBoxPages + [messageOutBox.endIndex] {
			lastSent📦ID = (lastSent📦ID + 1) % UInt16.max
			newPackets.append(SerialPacket(connectionUID: id, data: messageOutBox[startIndex..<endIndex], number: lastSent📦ID, acknowledgement: acknowledgementNumber))
			startIndex = endIndex
		}
		messageOutBox.removeAll(keepingCapacity: true)
		messageOutBoxPages.removeAll(keepingCapacity: true)
		let result = packetOutBox + newPackets
		for index in newPackets.indices {
			newPackets[index].makeRetransmission()
		}
		packetOutBox.append(contentsOf: newPackets)
		return result
	}

	static func id(firstBit: Bool) -> UID {
		let randomNumber = random() % UInt32(UInt16.max)
		let  firstByte = UInt8((randomNumber & 0x0700) >> 8)
		let secondByte = UInt8( randomNumber & 0x00FF)
		if firstBit {
			return [firstByte | 0b10000000, secondByte]
		} else {
			return [firstByte & 0b01111111, secondByte]
		}
	}
}
