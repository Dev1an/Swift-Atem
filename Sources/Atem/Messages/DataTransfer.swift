//
//  File.swift
//  
//
//  Created by Damiaan on 03/05/2020.
//

public struct LockRequest: Serializable {
	public static let title = MessageTitle(string: "LOCK")
	public let store: UInt16
	public let state: UInt16

	public init(with bytes: ArraySlice<UInt8>) throws {
		store = UInt16(from: bytes)
		state = UInt16(from: bytes[relative: 2..<4])
	}

	public var debugDescription: String {return "Lock store \(store) to \(String(state, radix: 16))"}

	public var dataBytes: [UInt8] {
		return store.bytes + state.bytes
	}
}

public struct LockPositionRequest: Message {
	public static let title = MessageTitle(string: "PLCK")
	public let store: UInt16
	public let index: UInt16
	public let type: UInt16

	public init(with bytes: ArraySlice<UInt8>) throws {
		store = UInt16(from: bytes)
		index = UInt16(from: bytes[relative: 2..<4])
		type = UInt16(from: bytes[relative: 4..<6])
		print(bytes)
	}

	public var debugDescription: String {return "Lock request \(store): for index \(index), type \(type)"}
}

public struct LockChange: Serializable {
	public static let title = MessageTitle(string: "LKST")
	public let store: UInt16
	public let isLocked: Bool

	public init(with bytes: ArraySlice<UInt8>) throws {
		store = .init(from: bytes)
		isLocked = bytes[relative: 2] == 1
	}

	public init(store: UInt16, isLocked: Bool) {
		self.store = store
		self.isLocked = isLocked
	}

	public var dataBytes: [UInt8] {
		return store.bytes + [isLocked ? 1:0, 0]
	}

	public var debugDescription: String { return "Lock for store \(store) is \(isLocked ? "established" : "released")" }
}

public struct LockObtained: Serializable {
	public static let title = MessageTitle(string: "LKOB")
	let frameNumber: UInt16

	public init(with bytes: ArraySlice<UInt8>) throws {
		frameNumber = UInt16(from: bytes)
	}

	public init(store: UInt16) {
		self.frameNumber = store
	}

	public var debugDescription: String { return "Lock obtained" }

	public var dataBytes: [UInt8] {
		return frameNumber.bytes + [0, 0]
	}
}

public struct StartDataTransfer: Serializable {
	public static let title = MessageTitle(string: "FTSD")

	public let transferID: UInt16
	public let store: UInt16
	public let frameNumber: UInt16
	public let size: UInt32
	public let mode: Mode

	public init(with bytes: ArraySlice<UInt8>) throws {
		transferID  = UInt16(from: bytes[relative: Positions.transferID])
		store       = UInt16(from: bytes[relative: Positions.store])
		frameNumber = UInt16(from: bytes[relative: Positions.frameNumber])
		size        = UInt32(from: bytes[relative: Positions.size])
		mode = Mode(rawValue: UInt16(from: bytes[relative: Positions.mode]))!
	}

	public init(transferID: UInt16, store: UInt16, frameNumber: UInt16, size: UInt32, mode: Mode) {
		(self.transferID, self.store, self.frameNumber, self.size, self.mode) = (transferID, store, frameNumber, size, mode)
	}

	public var dataBytes: [UInt8] {
		Array<UInt8>(unsafeUninitializedCapacity: 16) { (pointer, count) in
			pointer.write(transferID.bigEndian, at: Positions.transferID.startIndex)
			pointer.write(store.bigEndian, at: Positions.store.startIndex)
			pointer.write(frameNumber.bigEndian, at: Positions.frameNumber.startIndex)
			pointer.write(size.bigEndian, at: Positions.size.startIndex)
			pointer.write(mode.rawValue.bigEndian, at: Positions.mode.startIndex)
			count = 16
		}
	}
	public var debugDescription: String {
		"Start data transfer (id \(transferID)) to frame \(frameNumber) of store \(store) (mode: \(mode), size: \(size))"
	}

	public enum Mode: UInt16 {
		case noOperation = 0
		case write = 1
		case clear = 2
		case write2 = 256
		case clear2 = 512
	}

	enum Positions {
		static let transferID = 0..<2
		static let store = 2..<4
		static let frameNumber = 6..<8
		static let size = 8..<12
		static let mode = 12..<14
	}
}

public struct ContinueDataTransfer: Serializable {
	public static let title = MessageTitle(string: "FTCD")

	let transferID:   UInt16
	let magicNumber:  UInt8
	let chunkSize:    UInt16
	let chunkCount:   UInt16
	let magicNumber2: UInt16

	public init(with bytes: ArraySlice<UInt8>) throws {
		transferID = UInt16(from: bytes[relative: Positions.transferID])
		magicNumber = bytes[relative: Positions.magicNumber1]
		chunkSize = UInt16(from: bytes[relative: Positions.chunkSize])
		chunkCount = UInt16(from: bytes[relative: Positions.chunkCount])
		magicNumber2 = UInt16(from: bytes[relative: Positions.magicNumber2])
	}

	public init(transferID: UInt16, chunkSize: UInt16, chunkCount: UInt16, magic1: UInt8 = 26, magic2: UInt16 = 0x8b00) {
		(self.transferID,self.magicNumber,self.chunkSize,self.chunkCount,magicNumber2) = (transferID,magic1,chunkSize,chunkCount,magic2)
	}

	public var dataBytes: [UInt8] {
		Array<UInt8>(unsafeUninitializedCapacity: 12) { (pointer, count) in
			pointer.write(transferID.bigEndian, at: Positions.transferID.startIndex)
			pointer[Positions.magicNumber1] = magicNumber
			pointer.write(chunkSize.bigEndian, at: Positions.chunkSize.startIndex)
			pointer.write(chunkCount.bigEndian, at: Positions.chunkCount.startIndex)
			pointer.write(magicNumber2.bigEndian, at: Positions.magicNumber2.startIndex)
			count = 12
		}
	}
	public var debugDescription: String {
		"Continue Data Transfer command"
	}

	enum Positions {
		static let transferID = 0..<2
		static let magicNumber1 = 2
		static let chunkSize = 6..<8
		static let chunkCount = 8..<10
		static let magicNumber2 = 10..<12
	}
}

struct SetFileDescription: Serializable {
	public static let title = MessageTitle(string: "FTFD")

	let transferID: UInt16
	let name, description: String
	let hash: ArraySlice<UInt8>

	public init(with bytes: ArraySlice<UInt8>) throws {
		transferID = UInt16(from: bytes[relative: Positions.transferID])
		name = bytes[relative: Positions.name].withUnsafeBufferPointer({ (pointer) -> String in
			String(cString: pointer.baseAddress!)
		})
		description = bytes[relative: Positions.description].withUnsafeBufferPointer({ (pointer) -> String in
			String(cString: pointer.baseAddress!)
		})
		hash = bytes[relative: Positions.hash]
	}

	public init(transferID: UInt16, name: String, description: String, hash: [UInt8]) {
		self.transferID = transferID
		self.name = name
		self.description = description
		self.hash = hash.prefix(Positions.hash.count)
	}

	public var dataBytes: [UInt8] {
		Array<UInt8>(unsafeUninitializedCapacity: 212) { (pointer, count) in
			pointer.write(transferID.bigEndian, at: Positions.transferID.startIndex)
			var index = Positions.name.startIndex
			for letter in name.data(using: .ascii)! {
				pointer[index] = letter
				index += 1
			}
			if index < Positions.name.endIndex {
				pointer[index] = 0
			}
			index = Positions.description.startIndex
			for letter in description.data(using: .ascii)! {
				pointer[index] = letter
				index += 1
			}
			if index < Positions.description.endIndex {
				pointer[index] = 0
			}
			index = Positions.hash.startIndex
			for byte in hash {
				pointer[index] = byte
				index += 1
			}
			count = 212
		}
	}

	public var debugDescription: String {"File '\(name)': \(description) (Transfer ID: \(transferID), hash: \(hash))"}

	enum Positions {
		static let transferID = 0..<2
		static let name = 2..<66
		static let description = 66..<194
		static let hash = 194..<210
	}
}

struct TransferData: Serializable {
	public static let title = MessageTitle(string: "FTDa")

	public let transferID: UInt16
	public let body: [UInt8]

	public init(with bytes: ArraySlice<UInt8>) throws {
		transferID = UInt16(from: bytes[relative: Positions.transferID])
		let size = Int(UInt16(from: bytes[relative: Positions.size]))
		assert(bytes.count-Positions.body >= size, "incorrect size")
		body = Array(bytes[Positions.body ..< Positions.body + size])
	}

	public init(transferID: UInt16, data: [UInt8]) {
		self.transferID = transferID
		body = data
	}

	public var dataBytes: [UInt8] {
		Array<UInt8>(unsafeUninitializedCapacity: 4) { (pointer, count) in
			pointer.write(transferID.bigEndian, at: Positions.transferID.startIndex)
			pointer.write(UInt16(body.count).bigEndian, at: Positions.size.startIndex)
			count = 4
		} + body
	}

	var debugDescription: String { "Transfer \(body.count) bytes of data (ID: \(transferID)" }

	enum Positions {
		static let transferID = 0..<2
		static let size = 2..<4
		static let body = 4
	}
}

struct DataTransferCompleted: Serializable {
	public static let title = MessageTitle(string: "FTDC")

	public let transferID: UInt16

	public init(with bytes: ArraySlice<UInt8>) throws {
		transferID = UInt16(from: bytes[0..<2])
	}

	public var dataBytes: [UInt8] {
		[UInt8](unsafeUninitializedCapacity: 4) { (pointer, count) in
			pointer.write(transferID.bigEndian, at: 0)
			count = 4
		}
	}

	var debugDescription: String { "Data transfer \(transferID) completed" }
}
