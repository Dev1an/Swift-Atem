//
//  ConnectingControllerClient.swift
//  Atem
//
//  Created by Damiaan on 14-11-16.
//
//

import Socks
import Dispatch

class ConnectingAtemControllerClient: AtemControllerClient {
	final override func packetHandler(_ connectionPacket: AtemPacket) {
		if connectionPacket.acknowledgement != nil {
			selfDestructor?.perform()
			selfDestructor = nil
		}
	}
	
	final override func send() throws {
		print("sending connect to \(address)")
		let socket = try UDPClient(address: address)
		try socket.send(bytes: SerialAtemPacket.connectToController(uid: id, type: .connect))
		try socket.send(bytes: SerialAtemPacket(connectionUID: id, number: 1).bytes)
		try socket.send(bytes: SerialAtemPacket(connectionUID: id, messages: [
			ProtocolVersion(major: 2, minor: 21),
			AtemType(string: "ATEM 1 M/E Production Studio 4K"),
			Topology(
				mixEffectBanks: 1,
				sources: 0x1f,
				colorGenerators: 2,
				auxiliaryBusses: 3,
				downstreamKeyers: 2,
				stingers: 1,
				digitalVideoEffects: 1,
				superSources: 0,
				standardDefinitionOutput: true
			),
			ConnectionInitiationEnd.default,
			], number: 2).bytes)
	}
	
	deinit {
		print("deinit #\(UInt16(from: id))")
	}
}
