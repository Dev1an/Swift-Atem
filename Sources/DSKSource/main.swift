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
	
	connection.when{ (change: Did.ChangeDownstreamKeyer) in
		print(change) // prints: 'Preview bus changed to input(x)'
	}

	connection.when { (connected: Config.InitiationComplete) in
		print(connected)
		print("Type a source <enter> to change the fill source of the DSK 1")
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
	
	let fillSource = VideoSource(rawValue: sourceNumber)

	controller.send(message: Do.ChangeDownstreamKeyerFillSource(to: 0, fillSource: fillSource))
}
