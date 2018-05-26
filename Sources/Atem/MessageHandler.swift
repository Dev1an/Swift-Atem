//
//  MessageHandler.swift
//  Atem
//
//  Created by Damiaan on 26/05/18.
//

struct MessageHandler {
	
	/// A registry with handlers for each message.
	/// The keys in the registry are the message names and the values are functions that interprete and react on a message.
	private var registry: [UInt32: Any]
	
	public mutating func whenCut(_ handler: @escaping (Int)->()) {
		registry["DCut".quadBytes] = handler
	}
	
	func handle(message: ArraySlice<UInt8>) {
		
	}
}
