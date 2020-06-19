//
//  File.swift
//  
//
//  Created by Damiaan on 11/06/2020.
//

import Foundation
import Atem

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
if #available(OSX 10.15, *) {
	let compressed = Label(text: "Media player 1").render()
	try connect(ip: "10.1.0.210").uploadLabel(source: .mediaPlayer(0), labelImage: compressed)
	dispatchMain()
} else {
	// Fallback on earlier versions
}
#else
	print("Cannot render label using SwiftUI")
#endif
