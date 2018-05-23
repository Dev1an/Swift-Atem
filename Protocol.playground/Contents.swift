//: Playground - noun: a place where people can play

import Foundation

func bytes(from hex: String) -> [UInt8] {
	var bytes = [UInt8]()
	var cursor = hex.startIndex
	while cursor < hex.endIndex {
		let nextCursor = hex.index(cursor, offsetBy: 2)
		bytes.append(UInt8(hex[cursor..<nextCursor], radix: 16)!)
		cursor = nextCursor
	}
	return bytes
}

let x = [0,12,3,4]

let changeProgram = Packet(bytes: bytes(from: "88908001053400000000258f0010000054696d650001000d010003e8001403e8546c496e000801000000000200000178005401e0546c5372001800000000010100020000030000040000050000060200070000080003e80007d10007d2000bc2000bc3000bcc000bcd000faa00139200139c00271a00271b001b59001b5a001f41000100000c01e850726749001c0001"))
for message in changeProgram.messages {
	print(String(bytes: message[messageTitlePosition.advanced(by: message.startIndex)], encoding: .utf8))
	print(message)
}
