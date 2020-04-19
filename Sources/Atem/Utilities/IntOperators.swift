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
		self.init(slice.withUnsafeBufferPointer{
			$0.baseAddress!.withMemoryRebound(to: Self.self, capacity: 1) {$0.pointee.byteSwapped}
		})
	}
}

extension UInt16 {
	var bytes: [UInt8] {
		var copy = self
		return withUnsafeBytes(of: &copy, { [ $0[1], $0[0] ] })
	}
}

extension UInt32 {
	var bytes: [UInt8] {
		var copy = self
		return withUnsafeBytes(of: &copy, { [ $0[3], $0[2], $0[1], $0[0] ] })
	}
}

extension ArraySlice {
	subscript(relative index: Index) -> Element {
		return self[startIndex + index]
	}
	
	subscript<R: AdvancableRange>(relative range: R) -> SubSequence where R.Bound == Index {
		return self[range.advanced(by: startIndex)]
	}
}

protocol AdvancableRange: RangeExpression where Bound: Strideable {
	func advanced(by stride: Bound.Stride) -> Self
}

extension CountableRange: AdvancableRange {
	func advanced(by stride: Bound.Stride) -> CountableRange<Bound> {
		return CountableRange(uncheckedBounds: (lower: lowerBound.advanced(by: stride), upper: upperBound.advanced(by: stride)))
	}
}

extension CountablePartialRangeFrom: AdvancableRange {
	func advanced(by stride: Bound.Stride) -> CountablePartialRangeFrom<Bound> {
		return CountablePartialRangeFrom(lowerBound.advanced(by: stride))
	}
}
