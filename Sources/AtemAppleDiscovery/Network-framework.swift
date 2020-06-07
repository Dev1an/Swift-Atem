//
//  File.swift
//  
//
//  Created by Damiaan on 07/06/2020.
//

import Network
import NIO

enum NetworkDiscovery {
	func discover() {
		if #available(OSX 10.15, *) {
			let browser = NWBrowser(for: .bonjourWithTXTRecord(type: "_blackmagic._tcp.", domain: nil), using: .udp)
			let result = DispatchGroup()
			browser.browseResultsChangedHandler = { services, changes in
				for service in services {
					if case .bonjour(let record) = service.metadata {
						if record["class"] == "AtemSwitcher" {
							print(record)
						}
					}
				}
				result.leave()
			}

			let queue = DispatchQueue(label: "Bonjour browser")
			result.enter()
			browser.start(queue: queue)

			result.wait()
		} else {
			// Fallback on earlier versions
		}
	}
}
