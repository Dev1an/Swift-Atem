//
//  Enum+decode.swift
//  Atem
//
//  Created by Damiaan on 31/05/18.
//

import Foundation


/// An error indicating that no instance of `RawRepresentable` can be created using `value`
struct UnsupportedRawValue<R: RawRepresentable>: LocalizedError {
	/// The value that is not supported by the `RawRepresentable`
	let value: R.RawValue
	
	/// A textual description of the error
	var errorDescription: String? {
		return "Unable to interpret \(R.self) with raw representation: \(value)"
	}
}

extension RawRepresentable {
	/// Factory method that tries to create a new instance for a `Type` that is `RawRepresentable`
	/// and throws an `UnsupportedRawValue` when the `Type`'s `init?(rawValue:)` returns nil.
	///
	/// - Parameter value: the raw value for the new instance
	/// - Returns: a new instance with rawValue `value`
	/// - Throws: whenever the `Type` does not support `value` as rawValue
	static func decode(from value: Self.RawValue) throws -> Self {
		guard let result = Self.init(rawValue: value) else {
			throw UnsupportedRawValue<Self>(value: value)
		}
		return result
	}
}
