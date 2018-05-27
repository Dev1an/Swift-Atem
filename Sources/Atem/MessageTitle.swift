//
//  MessageTitle.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//

import Foundation

public struct MessageTitle: CustomStringConvertible {
	/// The position of the title in a message. (Ignoring the first four bytes of a message)
	/// Slice `0 ..< 4`
	static let position = 0 ..< 4
	
	public let description: String
	let number: UInt32
	
	init(string: String) {
		description = string
		number = Array(string.utf8).withUnsafeBytes{ $0.load(as: UInt32.self).byteSwapped }
	}
}
