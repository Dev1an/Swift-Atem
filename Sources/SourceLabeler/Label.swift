//
//  File.swift
//  
//
//  Created by Damiaan on 12/06/2020.
//

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)

import SwiftUI
import Atem

@available(OSX 10.15, *)
struct Label: View {
	let text: String
	@State var ding = 0.5

	@available(OSX 10.15, *)
	var body: some View {
		VStack(spacing: 0) {
			label(text: text, size: 20).frame(height: 50)
			label(text: text, size: 15).frame(height: 40)
		}
			.frame(width: 320, height: 90, alignment: .top)
			.background(Color.clear)
	}

	func label(text: String, size: CGFloat) -> some View {
		Text(text)
			.font(.system(size: size))
			.shadow(color: Color.black.opacity(0.5), radius: 0, x: 1, y: 1)
			.shadow(color: Color.black.opacity(0.5), radius: 3)
			.foregroundColor(.white)
			.padding(.horizontal)
			.padding(.vertical, 4)
			.background(Color.black)
			.cornerRadius(5)
			.overlay(
				RoundedRectangle(cornerRadius: 5)
					.stroke(Color(white: 0.7), lineWidth: 2)
					.foregroundColor(.clear)
			)
			.padding(2)
	}

	func render() -> Data {
		let width = 320
		let height = 90
		let frame = NSRect(x: 0, y: 0, width: width, height: height)
		let view = NSHostingView(rootView: self)
		view.frame = frame
		let data = Data(count: width * height * 2)
		let dataProvider = CGDataProvider(data: data as NSData)!
		let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 16, bytesPerRow: width*2, space: CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
		let imageRep = NSBitmapImageRep(cgImage: cgImage)

		print(imageRep)
		view.cacheDisplay(in: frame, to: imageRep)
		try? imageRep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "/tmp/atem-label.png"))

		let dataWithAlphaLayer = imageRep.cgImage!.dataProvider!.data! as Data

		var indexedData = Data(capacity: width*height)
		
		for i in 0 ..< width*height {
			let alpha = dataWithAlphaLayer[i*2+1]
			switch alpha {
			case 0 ..< UInt8(transparencyColorTable.endIndex):
				indexedData.append(transparencyColorTable[Int(alpha)])
			case 255:
				indexedData.append( grayColorTable[Int(dataWithAlphaLayer[i*2])] )
			default:
				indexedData.append( grayColorTable[179] )
			}
		}
		try? indexedData.write(to: URL(fileURLWithPath: "/tmp/atem-label.bin"))

		assert(indexedData.count == width*height)

		return Media.encodeRunLength(rawData: indexedData)
	}

}

#endif
