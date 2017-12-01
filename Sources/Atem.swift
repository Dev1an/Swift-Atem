//
//  Atem.swift
//  Atem
//
//  Created by Damiaan on 12-11-16.
//
//

import Foundation
import Socks
import SocksCore

class Atem {
	let server: SynchronousUDPServer
	var controllerConnections = [UInt16: AtemControllerClient]()
	
	init() throws {
		server = try SynchronousUDPServer(port: 9910, bindLocalhost: true)
		
		try server.startWithHandler { (received: [UInt8], sender: UDPClient) in
			let packet = AtemPacket(bytes: received)
			print(packet)
			let connectionID = UInt16(from: packet.connectionUID)
			if let connection = controllerConnections[connectionID] {
				connection.receive(packet)
			} else {
				let connection: AtemControllerClient
				if packet.isConnect {
					connection = try ConnectingAtemControllerClient(address: sender.socket.address, firstPacket: packet, atem: self)
				} else {
					connection = try ConnectedAtemControllerClient(address: sender.socket.address, firstPacket: packet, atem: self)
				}
				controllerConnections[connectionID] = connection
			}
		}
	}
}
