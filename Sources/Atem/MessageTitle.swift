//
//  MessageTitle.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//

import Foundation

/// An ASCII String of exactly 4 characters. A list of available titles can be found in [Skarhoj's protocol description](http://skaarhoj.com/fileadmin/BMDPROTOCOL.html) under the column "CMD".
public struct MessageTitle: CustomStringConvertible {
	/// The position of the title in a message. (Ignoring the first four bytes of a message)
	/// Slice `0 ..< 4`
	static let position = 0 ..< 4
	
	/// A `Swift.String` representation of the title
	public let description: String
	/// A `UInt32` representation of the title
	let number: UInt32
	
	init(string: String) {
		description = string
		number = Array(string.utf8).withUnsafeBytes{ $0.load(as: UInt32.self).byteSwapped }
	}
}
