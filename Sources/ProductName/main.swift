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
	connection.when{ (change: Config.ProductName) in
		print(change)
	}

	connection.when { (connected: Config.InitiationComplete) in
		print(connected)
	}

	connection.whenDisconnected = {
		print("Disconnected")
	}
}

var sourceString: String
while true {
	
}
