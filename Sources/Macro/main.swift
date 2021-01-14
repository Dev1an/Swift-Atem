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
	connection.when{ (change: Config.MacroPool) in
		print(change) // prints: 'Number of macro pool banks: input(x)'
	}

	connection.when { (change: Config.MacroProperties) in
		print(change) // prints: list of macros
	}
	
	connection.when { (connected: Config.InitiationComplete) in
		print(connected)
		print("Type a number to run the macro at that index")
	}

	connection.whenDisconnected = {
		print("Disconnected")
	}
}

var macroIndexString: String
while true {
	macroIndexString = readLine() ?? "1"
	guard let macroIndex = UInt8(macroIndexString) else {
		print("invalid macroIndex")
		continue
	}
	
	controller.send(message: Do.MacroAction(index: UInt16(macroIndex), action: 0))
}
