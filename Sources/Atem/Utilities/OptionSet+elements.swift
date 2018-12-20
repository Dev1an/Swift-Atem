//
//  OptionSet+elements.swift
//  Atem
//
//  Created by Damiaan on 20/12/2018.
//

extension OptionSet where RawValue: FixedWidthInteger, Self: SingleValueDescribable {
	func elements() -> AnySequence<Self> {
		var remainingBits = rawValue
		var bitMask: RawValue = 1
		return AnySequence {
			return AnyIterator {
				while remainingBits != 0 {
					defer { bitMask = bitMask &* 2 }
					if remainingBits & bitMask != 0 {
						remainingBits = remainingBits & ~bitMask
						return Self(rawValue: bitMask)
					}
				}
				return nil
			}
		}
	}
	
	var description: String {
		return "[\(elements().map{"." + ($0.describe() ?? "Unknown")}.joined(separator: ", "))]"
	}
}

public protocol SingleValueDescribable {
	func describe() -> String?
}
