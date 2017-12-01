//
//  ViewController.swift
//  AtemControl
//
//  Created by Damiaan on 1/12/17.
//

import Cocoa
import Atem_R

class ViewController: NSViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		print(Atem().text)
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}

