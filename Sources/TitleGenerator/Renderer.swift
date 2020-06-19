//
//  File.swift
//  
//
//  Created by Damiaan on 04/06/2020.
//

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
	import SwiftUI
	import Atem

	@available(OSX 10.15, *)
	extension View {
		func render() -> Data {
			let startTime = Date()

			let width = 1920
			let height = 1080
			let frame = NSRect(x: 0, y: 0, width: width, height: height)
			let view = NSHostingView(rootView: self)
			view.frame = frame
			let data = Data(count: width * height * 4)
			let dataProvider = CGDataProvider(data: data as NSData)!
			let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width*4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
			let imageRep = NSBitmapImageRep(cgImage: cgImage)
			view.cacheDisplay(in: frame, to: imageRep)
			try? imageRep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "/tmp/atem-media.png"))

			print("rendering took", Date().timeIntervalSince(startTime))

	//		let yuv = encodeRunLength(rgbData: imageRep.cgImage!.dataProvider!.data! as Data)
	//		try? yuv.write(to: URL(fileURLWithPath: "/tmp/atem-media.bin"))
			return Media.encodeRunLength(rgbData: imageRep.cgImage!.dataProvider!.data! as Data)
		}
	}
#endif
