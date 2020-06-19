//
//  File.swift
//  
//
//  Created by Damiaan on 07/06/2020.
//

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)

import Foundation
import NIO

public class AtemBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
	let browser = NetServiceBrowser()
	var recognizers = Set<Recognizer>()
	public private(set) var discoveredAtems = [NetService: Info]()

	public typealias AtemAppearanceHandler = (Info) -> Void
	public var atemDidAppearHandler: AtemAppearanceHandler = { atem in
		print("No 'appear' handler attached to AtemBrowser.")
		print("Attach a handler using <AtemBrowser>.atemFoundHandler = {atem in <do something here>}")
		print("Atem found", atem)
	}
	public var atemDidDisappearHandler: AtemAppearanceHandler = { atem in
		print("No 'disappear' handler attached to AtemBrowser.")
		print("Attach a handler using <AtemBrowser>.atemLostHandler = {atem in <do something here>}")
		print("Atem lost", atem)
	}

	public override init() {
		super.init()
		browser.delegate = self
	}

	public convenience init(whenFindingAtem handler: @escaping AtemAppearanceHandler) {
		self.init()
		atemDidAppearHandler = handler
		start()
	}

	public func start() {
		browser.searchForServices(ofType: "_blackmagic._tcp.", inDomain: "local.")
	}

	public func stop() {
		browser.stop()
	}

	public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
		recognizers.insert( Recognizer(service: service, browser: self) )
	}

	public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
		if let atem = discoveredAtems.removeValue(forKey: service) {
			atemDidDisappearHandler(atem)
		} else {
			print("Warning: no description found for lost atem", service)
		}
	}

	class Recognizer: NSObject, NetServiceDelegate {
		static let atemClassData = "AtemSwitcher".data(using: .ascii)!
		let service: NetService
		unowned let browser: AtemBrowser
		var addresses: Set<SocketAddress>?
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
				self.addresses = Set(addresses)
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
			service.resolve(withTimeout: 5)
		}

		func isFullyRecognised() {
			let description = Info(service: service, addresses: addresses!, rawProperties: properties!)
			browser.atemDidAppearHandler(description)
			browser.discoveredAtems[service] = description
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

	public struct Info: Hashable {
		public let service: NetService
		public let addresses: Set<SocketAddress>
		public let rawProperties: [String: Data]

		/// All properties except the ones listed in `Info.Key`
		public private(set) lazy var unknownProperties: [String: Data] = {
			let keys = Set( Key.allCases.map(\.rawValue) )
			return rawProperties.filter { !keys.contains($0.key) }
		}()

		nonmutating public func getString(_ key: Key) -> String? {
			guard let data = rawProperties[key.rawValue] else { return nil }
			return String(data: data, encoding: .utf8)
		}

		public enum Key: String, CaseIterable {
			case name = "name"
			case releaseVersion = "release version"
			case internalVersion = "internal version"
			case protocolVersion = "protocol version"
			case uid = "unique id"
		}

		public static func == (lhs: Self, rhs: Self) -> Bool {
			let uidKey = Key.uid.rawValue
			if lhs.service == rhs.service { return true }
			if let left = lhs.rawProperties[uidKey], let right = rhs.rawProperties[uidKey] {
				return left == right
			}
			return Set(lhs.addresses) == Set(rhs.addresses)
		}
	}
}

//let browser = AtemBrowser()
//browser.start()
//
//RunLoop.main.run()


#endif
