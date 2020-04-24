//
//  File.swift
//  
//
//  Created by Damiaan on 20/11/2019.
//

import Atem
import Dispatch
import Foundation

let address: String
if CommandLine.arguments.count > 1 {
	address = CommandLine.arguments[1]
} else {
	print("Enter switcher IP address: ", terminator: "")
	address = readLine() ?? "192.168.8.149"
}
print("Trying to connect to switcher with IP addres", address)

let controller = try Controller(ipAddress: address) { connection in
	connection.when { (version: ProtocolVersion) in
		print(version)
	}

	connection.when { (change: InitiationComplete) in
		print("Initiation complete")
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			exit(EXIT_SUCCESS)
		}
	}
}

dispatchMain()

//import Foundation
//
//let messsages = try "[" + (2...18).map { index in
//	let file = try Data(contentsOf: URL(fileURLWithPath: "/tmp/packet\(index)"))
//	return "[" + file.map{"0x" + String($0, radix: 16)}.joined(separator: ", ") + "]"
//}.joined(separator: ",\n") + "]"
//
//print(messsages)
