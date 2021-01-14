//
//  main.swift
//  
//
//  Created by adamtow on 12/01/2021.
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
	connection.when{ (change: Did.ChangeDownstreamKeyerOnAir) in
		print(change) // prints: 'Preview bus changed to input(x)'
	}

	connection.when { (connected: Config.InitiationComplete) in
		print(connected)
		print("Type 1 or 0 and <enter> to change the On Air status of the DSK 1")
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
	
	controller.send(message: Do.ChangeDownstreamKeyerOnAir(to: 0, onAir: sourceNumber == 1))
}
