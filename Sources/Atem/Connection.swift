import Foundation

/// Stores all relevant information to keep an ATEM connection alive.
///
/// Used internally by ``Controller`` and ``Switcher`` objects to decide how to interprete incoming packets and construct new outgoing packets.
public class ConnectionState { // TODO: Make this a struct?
	/// Received packet id's. Contains all the packets that should still be acknowledged
	var lastRead📦ID: UInt16? {
		didSet {
			if lastRead📦ID != nil { lastRead📦needsConfirmation = true }
		}
	}
	var lastRead📦needsConfirmation = false
	var unread📦s = [Packet]()
	
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
	
	/// Interprets data and returns the new messages it contains in sequential order
	func parse(_ packet: Packet) -> [ArraySlice<UInt8>] {
		let messagesToReadNow: [ArraySlice<UInt8>]
		if let packetID = packet.number {
			if packet.isConnect {
				packetOutBox.removeAll()
				messagesToReadNow = []
				lastRead📦ID = packetID
			} else if packetID == 1 {
				id = packet.connectionUID
				print("connected using id", id)
				messagesToReadNow = packet.messages
				lastRead📦ID = packetID
			} else {
				if let lastRead = lastRead📦ID {
					if packetID == lastRead + 1 {
						lastRead📦ID = packetID
						messagesToReadNow = packet.messages + checkUnread📦s()
					} else if packetID <= lastRead {
						lastRead📦needsConfirmation = true
						messagesToReadNow = []
						print("package \(String(packetID, radix: 16)) already read")
					} else {
						print("missing a packet. Got", String(packetID, radix: 16), "needed", String(lastRead + 1, radix: 16))
						messagesToReadNow = []
						addUnread(📦: packet)
					}
				} else {
					print("missing a packet. Got", String(packetID, radix: 16), "but lastRead📦ID = nil")
					messagesToReadNow = []
					addUnread(📦: packet)
				}
			}

		} else {
			// Packets with messages should have a number
			// So messages within unnumbered packets are discarded
			messagesToReadNow = []
		}
		if let acknowledgedID = packet.acknowledgement {
			let upperBound = packetOutBox.binarySearch { $0.number < acknowledgedID }
			if upperBound < packetOutBox.endIndex {
				packetOutBox.removeSubrange(0...upperBound)
			}
		}

		return messagesToReadNow
	}
	
	func send(message: [UInt8], asSeparatePackage needsSeparatepackage: Bool = false) {
		if needsSeparatepackage || messageOutBox.count + message.count > 1420 {
			messageOutBoxPages.append(messageOutBox.count)
		}
		messageOutBox.append(contentsOf: message)
	}

	/// Sends the specified message.
	///
	/// - Parameter message: A message that can be serialized
	/// - Parameter needsSeparatePackage: Indicates the need to create a new package when transmitting this message over the network
	///
	/// Messages are sent in packages. One packet can contain multiple messages. Only use this method when you explicitly need to send your messages in a new packet. Otherwise use
	public func send(_ message: SerializableMessage, asSeparatePackage needsSeparatePackage: Bool = false) {
		send(message: message.serialize(), asSeparatePackage: needsSeparatePackage)
	}
	
	/// Returns old packets that aren't acknowledged yet together with new packets
	func assembleOutgoingPackets() -> [SerialPacket] {
		let acknowledgementNumber: UInt16?
		if lastRead📦needsConfirmation {
			acknowledgementNumber = lastRead📦ID
			lastRead📦needsConfirmation = false
		} else {
			acknowledgementNumber = nil
		}
		var newPackets = [SerialPacket]()
		newPackets.reserveCapacity(messageOutBoxPages.count+1)
		var startIndex = 0
		for endIndex in messageOutBoxPages + [messageOutBox.endIndex] {
			lastSent📦ID = (lastSent📦ID + 1) % 0b1000_0000_0000_0000
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

	private func addUnread(📦 packet: Packet) {
		let index = unread📦s.binarySearch { previous in previous.number! < packet.number! }
		if index == unread📦s.count || unread📦s[index].number! != packet.number {
			unread📦s.insert(packet, at: index)
		}
	}

	/// Iterates over the unread packets ordered by their `packer.number`
	/// - Returns: All the messages that came in before but were not acknowledged immediateley because of a previous missing packet
	private func checkUnread📦s() -> [ArraySlice<UInt8>] {
		var messagesToReadNow = [ArraySlice<UInt8>]()
		if let lastReadId = lastRead📦ID, let firstUnreadNumber = unread📦s.first?.number, firstUnreadNumber == lastReadId + 1 {
			var lastSequentialNumber = firstUnreadNumber
			for (index, packet) in unread📦s.enumerated() {
				if packet.number == lastSequentialNumber {
					lastSequentialNumber += 1
					messagesToReadNow.append(contentsOf: packet.messages)
					lastRead📦ID = packet.number
				} else {
					unread📦s.removeSubrange(0..<index)
					return messagesToReadNow
				}
			}
		}
		return messagesToReadNow
	}

	static func id(firstBit: Bool) -> UID {
		let randomNumber = UInt32.random(in: 0 ..< UInt32(UInt16.max))
		let  firstByte = UInt8((randomNumber & 0x0700) >> 8)
		let secondByte = UInt8( randomNumber & 0x00FF)
		if firstBit {
			return [firstByte | 0b10000000, secondByte]
		} else {
			return [firstByte & 0b01111111, secondByte]
		}
	}
}
