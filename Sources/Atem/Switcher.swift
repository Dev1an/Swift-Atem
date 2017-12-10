//
//  SwitcherConnection.swift
//  AtemPackageDescription
//
//  Created by Damiaan on 7/12/17.
//

import Sockets
import Dispatch
import Foundation

class Switcher {
	
	let socket: UDPInternetSocket
	
	let networkQueue = DispatchQueue.global(qos: .userInteractive)
	let keepAliveTimer: DispatchSourceTimer
	private var keepAlive = true

	var connectionStates = [ResolvedInternetAddress: ConnectionState]()
	
	init() throws {
		keepAliveTimer = DispatchSource.makeTimerSource(queue: networkQueue)
		keepAliveTimer.schedule(deadline: .now(), repeating: .milliseconds(20), leeway: .milliseconds(10))
		socket = try UDPInternetSocket(address: InternetAddress.localhost(port: 9910))
		try startListening()
	}
	
	func startListening() throws {
		try socket.bind()
		networkQueue.async {
			while self.keepAlive {
				do {
					let (data, sender) = try self.socket.recvfrom()
					self.interpret(data, from: sender)
				} catch {
					self.keepAlive = false
					print(error)
				}
			}
		}
		keepAliveTimer.setEventHandler { [weak self] in
			if let switcher = self {
				for (address, state) in switcher.connectionStates {
					for packet in state.constructKeepAlivePackets() {
//						print("🕹 \(Packet(bytes: packet.bytes))")
						try! switcher.socket.sendto(data: packet.bytes, address: address)
					}
				}
			}
		}
		keepAliveTimer.resume()
	}
	
	deinit {
		keepAliveTimer.cancel()
	}
	
	final func interpret(_ data: [UInt8], from sender: ResolvedInternetAddress) {
		let packet = Packet(bytes: data)
//		print("💻 \(packet)")
		if packet.isConnect {
			networkQueue.async {
				let connect = SerialPacket.connectToController(uid: packet.connectionUID, type: .connect)
				print("🕹 \(Packet(bytes: connect.bytes))")
				try! self.socket.sendto(data: connect.bytes, address: sender)
			}
		} else if let index = connectionStates.index(forKey: sender) {
			let state = connectionStates[index].value
			state.interpret(packet)
			interpret(messages: packet.messages)
		} else if packet.acknowledgement == 0 {
			connectionStates[sender] = ConnectionState.switcher(initialPacket: packet)
		}
	}
	
	func interpret(messages: [ArraySlice<UInt8>]) {}
}

extension ResolvedInternetAddress: Hashable {
	public var hashValue: Int {
		return ("\(ipString()):\(port)").hashValue
	}
}
