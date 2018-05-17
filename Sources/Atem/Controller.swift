//
//  Controller.swift
//  Atem
//
//  Created by Damiaan on 9/12/17.
//

//import Foundation
//
//import Dispatch
//
//class Controller {
//	let socket: UDPTranceiver
//	let networkQueue = DispatchQueue.global(qos: .userInteractive)
//	let keepAliveTimer: DispatchSourceTimer
//	private var keepAlive = true
//	
//	let connectionState = ConnectionState.controller()
//
//	init(switcherAddress: String) throws {
//		keepAliveTimer = DispatchSource.makeTimerSource(queue: networkQueue)
//		keepAliveTimer.schedule(deadline: .now(), repeating: .milliseconds(20), leeway: .milliseconds(10))
//		socket = try UDPInternetSocket(address: InternetAddress(hostname: switcherAddress, port: 9910))
//		try startListening()
//		startSending()
//	}
//	
//	private func startListening() throws {
//		networkQueue.async {
//			while self.keepAlive {
//				do {
//					let (data, sender) = try self.socket.recvfrom()
//					let packet = Packet(bytes: data)
//					print("🕹 \(packet)")
//					self.connectionState.interpret(packet)
//				} catch {
//					self.keepAlive = false
//					print(error)
//				}
//			}
//		}
//	}
//	
//	private func startSending() {
//		keepAliveTimer.setEventHandler { [weak self] in
//			if let controller = self {
//				for packet in controller.connectionState.constructKeepAlivePackets() {
//					print("💻 \(Packet(bytes: packet.bytes))")
//					try! controller.socket.sendto(data: packet.bytes)
//				}
//			}
//		}
//		keepAliveTimer.resume()
//	}
//
//}
