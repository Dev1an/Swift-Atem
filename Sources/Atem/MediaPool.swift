//
//  File.swift
//  
//
//  Created by Damiaan on 05/12/2020.
//

/// A namespace for media pool related datastructures
public enum MediaPool {
	public enum Bank: RawRepresentable {
		public typealias RawValue = UInt8

		case still
		case clip(index: UInt8)

		public init?(rawValue: UInt8) {
			switch rawValue {
			case 0: self = .still
			case 1...4:
				self = .clip(index: rawValue - 1)
			default:
				return nil
			}
		}

		public var rawValue: UInt8 {
			switch self {
				case .still: return 0
				case .clip(let index): return index + 1
			}
		}
	}

	public struct ID {
		let bank: Bank
		let frame: UInt16
	}
}
