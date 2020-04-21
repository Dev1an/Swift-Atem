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
	connection.when{ (change: PreviewBusChanged) in
		print(change) // prints: 'Preview bus changed to input(x)'
	}

	connection.when { (connected: InitiationComplete) in
		print(connected)
	}
}

var sourceString: String
while true {
	print("Enter preview input: ", terminator: "")
	sourceString = readLine() ?? "1"
	guard let sourceNumber = UInt16(sourceString) else {
		print("invalid source")
		continue
	}
	let source = VideoSource.input(sourceNumber)
	controller.send(message: ChangePreviewBus(to: source))
}
