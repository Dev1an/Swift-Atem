//
//  File.swift
//  
//
//  Created by Damiaan on 11/06/2020.
//

import Foundation
import Atem

if #available(OSX 10.15, *) {
	#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
	let compressed = Label(text: "Media player 1").render()
	#else
	let compressed = fatalError("Cannot render SwiftUI label on Linux")
	#endif
	try connect(ip: "10.1.0.210").uploadLabel(source: .mediaPlayer(0), labelImage: compressed)
	dispatchMain()
} else {
	// Fallback on earlier versions
}


