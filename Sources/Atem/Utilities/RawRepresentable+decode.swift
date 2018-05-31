//
//  Enum+decode.swift
//  Atem
//
//  Created by Damiaan on 31/05/18.
//

import Foundation

struct UnsupportedRawValue<R: RawRepresentable>: LocalizedError {
	let value: R.RawValue
	var errorDescription: String? {
		return "Unable to interpret \(R.self) with raw representation: \(value)"
	}
}

extension RawRepresentable {
	static func decode(from value: Self.RawValue) throws -> Self {
		guard let result = Self.init(rawValue: value) else {
			throw UnsupportedRawValue<Self>(value: value)
		}
		return result
	}
}
