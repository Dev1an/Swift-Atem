//
//  TallyLight.swift
//  Atem
//
//  Created by Damiaan on 31/05/18.
//

import Foundation

public struct TallyLight: OptionSet, CustomDebugStringConvertible {
	public let rawValue: UInt8
	
	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
	
	public static let     off = TallyLight(rawValue: 0)
	public static let program = TallyLight(rawValue: 1)
	public static let preview = TallyLight(rawValue: 2)
	
	public var debugDescription: String {
		switch rawValue {
		case 0: return "⚪️ .off"
		case 1: return "🔴 .program"
		case 2: return "❇️ .preview"
		case 3: return "✌️ .program & .preview"
		default:
			preconditionFailure("tally light can never be bigger than 3")
		}
	}
}
