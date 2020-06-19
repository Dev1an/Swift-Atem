//
//  File.swift
//  
//
//  Created by Damiaan on 21/04/2020.
//

import Foundation
import Atem

let address: String
if CommandLine.arguments.count > 1 {
	address = CommandLine.arguments[1]
} else {
	print("Enter switcher IP address: ", terminator: "")
	address = readLine() ?? "10.1.0.210"
}
print("Trying to connect to switcher with IP addres", address)

let controller = try Controller(ipAddress: address) { connection in
	connection.when{ (change: Did.ChangePreviewBus) in
		print(change) // prints: 'Preview bus changed to input(x)'
	}

	connection.when { (connected: Config.InitiationComplete) in
		print(connected)
		print("Type a number and press <enter> to change the current preview")
	}

	connection.whenDisconnected = {
		print("Disconnected")
	}
}

var sourceString: String
while true {
	sourceString = readLine() ?? "1"
	guard let sourceNumber = UInt16(sourceString) else {
		print("invalid source")
		continue
	}
	let source = VideoSource.input(sourceNumber)
	controller.send(message: Do.ChangePreviewBus(to: source))
}
