import Socks
import Foundation

do {
	let atem = try Atem()
} catch {
	print("Error \(error)")
}


//do {
//	let sock = try UDPClient(address: InternetAddress.localhost(port: 3456))
//	try sock.send(bytes: [0,0])
//} catch {
//	
//}
