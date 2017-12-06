struct Connection {
	/// Received packet id's
	var received📦IDs = [UInt16]()
	
	/// The id of the last packet that was sent from this connection
	var lastSent📦ID  =  UInt16(0)
	
	/// The id of the connection. At the initial connection phase this ID is temporarily set. After this phase a permanent ID is assigned.
	public private(set) var id: UID
	
	typealias PacketInterpreter = (Packet) -> Void
	
	private init(with initial📦: Packet) {
		id = initial📦.connectionUID
	}
	
	func interpret(_ packet: Packet) -> [Message] {
		fatalError("not implemented")
	}
	
	func constructKeepAlivePacket() -> Packet {
		fatalError("not implemented")
	}
}
