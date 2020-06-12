//
//  File.swift
//  
//
//  Created by Damiaan on 11/06/2020.
//

import Foundation
import Atem

//analyzeGrid()

//var decompressed = try Data(contentsOf: URL(fileURLWithPath: "/Users/damiaan/Documents/Projecten/ATEM/Research/communication/Change input name/input10 image/decompressed.bin"))

//for x in 0..<13800 { decompressed[x] = 0 }

//for x in 0..<28800 { decompressed[x] = 34 }

//let text = try Data(contentsOf: URL(fileURLWithPath: "/tmp/atem-label.bin"))
//let convertedText = Data(text.map{grayColorTable[Int($0)]})
//
//decompressed[convertedText.indices] = convertedText
//
if #available(OSX 10.15, *) {

//	analyzeGrid()

	let compressed = Label(text: "Media player 1").render()
	try connect(ip: "10.1.0.210").uploadLabel(source: .mediaPlayer(0), labelImage: compressed)
	dispatchMain()
} else {
	// Fallback on earlier versions
}


