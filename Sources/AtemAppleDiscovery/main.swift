//
//  File.swift
//  
//
//  Created by Damiaan on 07/06/2020.
//

import Foundation
import NIO

public class AtemBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
	let browser = NetServiceBrowser()
	var recognizers = Set<Recognizer>()
	public typealias AtemFoundHandler = ([SocketAddress], [String: Data]) -> Void
	public var atemFoundHandler: AtemFoundHandler = { addresses, properties in
		print("No handler attached to AtemBrowser.")
		print("Attach a handler using <AtemBrowser>.atemFoundHandler = {address, properties in <do something here>}")
		print("Atem found", addresses, properties)
	}

	public override init() {
		super.init()
		browser.delegate = self
	}

	public convenience init(whenFindingAtem handler: @escaping AtemFoundHandler) {
		self.init()
		atemFoundHandler = handler
		start()
	}

	public func start() {
		browser.searchForServices(ofType: "_blackmagic._tcp.", inDomain: "local.")
	}

	public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
		recognizers.insert( Recognizer(service: service, browser: self) )
	}

	public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
		print(service.name, "went away")
	}

	class Recognizer: NSObject, NetServiceDelegate {
		static let atemClassData = "AtemSwitcher".data(using: .ascii)!
		let service: NetService
		unowned let browser: AtemBrowser
		var addresses: [SocketAddress]?
		var properties: [String: Data]?

		init(service: NetService, browser: AtemBrowser) {
			self.service = service
			self.browser = browser
			super.init()
			service.delegate = self
			service.startMonitoring()
			service.resolve(withTimeout: 5)
		}

		func netServiceDidResolveAddress(_ sender: NetService) {
			if let addresses = sender.addresses?.compactMap(socketAddress(from:)), !addresses.isEmpty {
				self.addresses = addresses
				if properties != nil {
					isFullyRecognised()
				}
			} else {
				print("Warning: No IP address found for resolved service", service)
				unregister()
			}
		}

		func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
			sender.stopMonitoring()
			let dictionary = NetService.dictionary(fromTXTRecord: data)

			if dictionary["class"] == Self.atemClassData {
				properties = dictionary
				if addresses != nil {
					isFullyRecognised()
				}
			} else {
				unregister()
			}
		}

		func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
			print("Warning: Address for", service.name, "could not be resolved")
		}

		func isFullyRecognised() {
			browser.atemFoundHandler(addresses!, properties!)
			unregister()
		}

		func unregister() {
			service.delegate = nil
			browser.recognizers.remove(self)
		}

		func socketAddress(from data: Data) -> SocketAddress? {
			data.withUnsafeBytes { buffer -> SocketAddress? in
				guard let pointer = buffer.baseAddress else {
					print("Error (bonjour): IP address buffer has no base address")
					return nil
				}
				let family = pointer.assumingMemoryBound(to: sockaddr.self).pointee.sa_family
				switch family {
					case UInt8(AF_INET): return SocketAddress(
							pointer.assumingMemoryBound(to: sockaddr_in.self).pointee,
							host: service.hostName!
					)
					case UInt8(AF_INET6): return SocketAddress(
							pointer.assumingMemoryBound(to: sockaddr_in6.self).pointee,
							host: service.hostName!
					)
					default:
						print("Warning (bonjour): Address is not IPv4 nor IPv6 for service", service)
						return nil
				}
			}
		}
	}
}

let browser = AtemBrowser { addresses, properties in
	print("atem found on", addresses, properties)
}

RunLoop.main.run()
