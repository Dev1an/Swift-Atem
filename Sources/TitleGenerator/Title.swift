//
//  File.swift
//  
//
//  Created by Damiaan on 04/06/2020.
//

import SwiftUI

@available(OSX 10.15, *)
struct Title: View {
	let text: String
	@State var ding = 0.5

	@available(OSX 10.15, *)
	var body: some View {
		Text(text)
			.font(.system(size: 200))
			.shadow(radius: 10)
			.padding()
			.background(Color.black.opacity(0.3))
			.cornerRadius(10)
	}
}
