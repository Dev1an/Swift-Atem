//
//  IntOperators.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation

extension UInt8 {
	var firstBit: Bool {return self & 1 == 1}
}

extension FixedWidthInteger {
	init(from slice: ArraySlice<UInt8>) {
		self.init(slice.withUnsafeBytes{ $0.load(as: Self.self).byteSwapped })
	}
}

extension UInt16 {
	var bytes: [UInt8] {
		var copy = self
		return withUnsafeBytes(of: &copy, { [ $0[1], $0[0] ] })
	}
}

extension CountableRange {
	public func advanced(by stride: Bound.Stride) -> CountableRange<Bound> {
		return CountableRange(uncheckedBounds: (lower: lowerBound.advanced(by: stride), upper: upperBound.advanced(by: stride)))
	}
}
