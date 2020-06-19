//
//  File.swift
//  
//
//  Created by Damiaan on 04/06/2020.
//

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)

import SwiftUI

@available(OSX 10.15, *)
struct Title: View {
	let text: String
	@State var ding = 0.5

	@available(OSX 10.15, *)
	var body: some View {
		Text(text)
			.font(.system(size: 30))
			.shadow(color: Color.black.opacity(0.5), radius: 0, x: 1, y: 1)
			.shadow(color: Color.black.opacity(0.5), radius: 3)
			.foregroundColor(.white)
			.padding()
			.background(Color.black.opacity(0.3))
			.cornerRadius(5)
			.frame(width: 1920, height: 1080)
//			.background(Color(.sRGB, white: 1, opacity: 0.063))
//			.frame(width: 1080, height: 1920, alignment: .leading)
//			.rotationEffect(.degrees(90))
	}
}

#endif
