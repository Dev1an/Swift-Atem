//
//  ControllerInfo.swift
//  Atem
//
//  Created by Damiaan on 12-11-16.
//
//

import Dispatch
import Socks
import SocksCore

let sendQueue = DispatchQueue(label: "send")

class AtemControllerClient {
	let address: ResolvedInternetAddress
	let atem: Atem
	let id: UID
	var selfDestructor: DispatchWorkItem?
	var sender: DispatchWorkItem?
	
	init(address: ResolvedInternetAddress, firstPacket packet: AtemPacket, atem: Atem) throws {
		self.address = address
		self.atem = atem
		id = packet.connectionUID
		
		receive(packet)
		try startSending()
	}
	
	func packetHandler(_ : AtemPacket) {}
	func send() throws {}
	
	func receive(_ packet: AtemPacket) {
		renewSelfDestructor()
		packetHandler(packet)
	}
	
	func renewSelfDestructor() {
		selfDestructor?.cancel()
		selfDestructor = DispatchWorkItem {
			self.atem.controllerConnections.removeValue(forKey: UInt16(from: self.id))
			self.selfDestructor = nil
			
			if let sender = self.sender {
				sender.cancel()
				self.sender = nil
			}
			print("removed client \(UInt16(from: self.id)) from atem")
		}
		DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.2, execute: selfDestructor!)
	}
	
	func startSending() throws {
		try send()
		sender = nil
		renewSender()
	}
	
	func renewSender() {
		sender?.cancel()
		sender = DispatchWorkItem {
			do {
				try self.startSending()
			} catch {
				print(error)
			}
		}
		DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.2, execute: sender!)
	}

}
