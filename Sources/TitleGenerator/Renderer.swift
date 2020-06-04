//
//  File.swift
//  
//
//  Created by Damiaan on 04/06/2020.
//

import SwiftUI
import MediaConverter

@available(OSX 10.15, *)
extension View {
	func render() -> Data {
		let frame = NSRect(x: 0, y: 0, width: 1920, height: 1080)
		let view = NSHostingView(rootView: self)
		view.frame = frame
		let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1920, pixelsHigh: 1080, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bitmapFormat: .init(), bytesPerRow: 1920*4, bitsPerPixel: 32)!
		view.cacheDisplay(in: frame, to: imageRep)
		return encodeRunLength(data: imageRep.cgImage!.dataProvider!.data! as Data)
	}
}
