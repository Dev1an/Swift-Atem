//
//  ConnectedControllerClient.swift
//  Atem
//
//  Created by Damiaan on 14-11-16.
//
//

import Dispatch
import Socks

class ConnectedAtemControllerClient: AtemControllerClient {
	var receivedPacketNumbers = [UInt16]()
	var myLastNumber = UInt16(1)
	
	final override func packetHandler(_ packet: AtemPacket) {
		if let number = packet.number {
			receivedPacketNumbers.append(number)
		}
	}
	
	final override func send() throws {
		let acknowledgement: (Int, UInt16)?
		if receivedPacketNumbers.count > 0 {
			receivedPacketNumbers.sort()
			var (lastIndex, lastPackageNumber) = (0, receivedPacketNumbers.first!)
			for (index, number) in receivedPacketNumbers.dropFirst().enumerated() {
				if lastPackageNumber == number - 1 {
					(lastIndex, lastPackageNumber) = (index, number)
				} else {
					break
				}
			}
			acknowledgement = (lastIndex, lastPackageNumber)
		} else {
			acknowledgement = nil
		}
		
		let packetNumber = myLastNumber + 1
		let packet = SerialAtemPacket(connectionUID: id, messages: [], number: myLastNumber, acknowledgement: acknowledgement?.1)
		let socket = try UDPClient(address: address)
		try socket.send(bytes: packet.bytes)
		if let numberOfAck = acknowledgement?.0 {
			receivedPacketNumbers.removeFirst(numberOfAck+1)
		}
		myLastNumber = packetNumber
		print("ack", acknowledgement)
		print("sent data #\(UInt16(from:id)):\(packetNumber)")
	}
}
