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
	let compressed = Label(text: "Preview 🎥").render()

	let upload = DispatchGroup()
	upload.enter()
	let controller = try connect(ip: "10.1.0.210")
	controller.uploadLabel(source: .preview(me: 0), labelImage: compressed)
	upload.wait()

	print(controller)

} else {
	// Fallback on earlier versions
}
#else
	print("Cannot render label using SwiftUI")
#endif
