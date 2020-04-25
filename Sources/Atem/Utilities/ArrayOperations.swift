//
//  ArrayOperations.swift
//  AtemPackageDescription
//
//  Created by Damiaan on 6/12/17.
//

import Foundation

extension Collection {
	/// Finds such index N that predicate is true for all elements up to
	/// but not including the index N, and is false for all elements
	/// starting with index N.
	/// Behavior is undefined if there is no such N.
	func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
		var low = startIndex
		var high = endIndex
		while low != high {
			let mid = index(low, offsetBy: distance(from: low, to: high)/2)
			if predicate(self[mid]) {
				low = index(after: mid)
			} else {
				high = mid
			}
		}
		return low
	}
}

extension Array where Element: Comparable {
	public mutating func sortedInsert(_ element: Element, isOrderedBefore: (Element)->Bool) {
		insert(element, at: binarySearch(predicate: isOrderedBefore))
	}

	public mutating func sortedUpsert(_ element: Element) {
		let index = binarySearch(predicate: {$0 < element})
		if index == count || self[index] != element {
			insert(element, at: index)
		}
	}
}
