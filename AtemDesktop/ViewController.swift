//
//  ViewController.swift
//  AtemDesktop
//
//  Created by Damiaan on 08-11-16.
//
//

import Cocoa
import Socks

class ViewController: NSViewController {
	@IBOutlet weak var messageLabel: NSTextField!
	@IBOutlet weak var messageDateLabel: NSTextField!

	override func viewDidLoad() {
		super.viewDidLoad()

		DispatchQueue.global(qos: .userInteractive).async {
			do {
				let server = try SynchronousUDPServer(port: 8080)
				print("Listening on port \(server.address.port)")
				try server.startWithHandler { (received, client) in
					if let textReceived = try? received.toString() {
						self.messageLabel.stringValue = textReceived
						self.messageDateLabel.objectValue = Date()
					}
				}
			} catch {
				print("Error \(error)")
			}
		}
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}

