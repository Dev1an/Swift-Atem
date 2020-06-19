//
//  File.swift
//
//
//  Created by Damiaan on 21/04/2020.
//

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)

import Atem

if #available(OSX 10.15, *) {
	let address: String
	if CommandLine.arguments.count > 1 {
		address = CommandLine.arguments[1]
	} else {
		print("Enter switcher IP address: ", terminator: "")
		address = readLine() ?? "10.1.0.210"
	}
	print("Trying to connect to switcher with IP addres", address)

	let controller = try Controller(ipAddress: address) { connection in
		connection.when { (connected: Config.InitiationComplete) in
			print(connected)
			print("Type some text to send to the atem")
		}

		connection.whenDisconnected = {
			print("Disconnected")
		}

		connection.whenError = { error in
			print("Error", error)
		}
	}

	while true {
		let text = readLine() ?? "Sample text"
		controller.uploadStill(
			slot: 1,
			data: Title(text: text).render(),
			uncompressedSize: 1920*1080*4
		)
	}
} else {
	print("Rendering SwiftUI is only available on macOS")
}

#else
	print("Rendering SwiftUI is only available on macOS")
#endif
