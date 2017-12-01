//
//  IntOperators.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation

infix operator <<+

extension UInt8 {
	var firstBit: Bool {return self & 1 == 1}
}

extension UInt16 {
	/// Combines a slice of two bytes into an UInt16
	init(from slice: ArraySlice<UInt8>) {
		self.init(UInt16(slice.first!) << 8 + UInt16(slice.last!))
	}
}

extension UInt32 {
	/// Combines a slice of four bytes into an UInt32
	init(from slice: ArraySlice<UInt8>) {
		self.init(UInt32(slice.first!) << 24 + UInt32(slice[slice.startIndex+1]) << 16 + UInt32(slice[slice.startIndex+2]) << 8 + UInt32(slice[slice.startIndex+3]))
	}
}

extension UInt16 {
	var bytes: [UInt8] {
		return [
			UInt8(self >> UInt16(8)        ),
			UInt8(self &  UInt16(UInt8.max))
		]
	}
}

extension CountableRange {
	func advanced(by stride: Bound.Stride) -> CountableRange<Bound> {
		return CountableRange(uncheckedBounds: (lower: lowerBound.advanced(by: stride), upper: upperBound.advanced(by: stride)))
	}
}
