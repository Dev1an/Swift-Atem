//
//  File.swift
//  
//
//  Created by Damiaan on 20/11/2019.
//

import Atem
import Dispatch
import Foundation

let switcher = Switcher { controllers in
	controllers.when { (change: Do.ChangePreviewBus, _) in
		controllers.send(Did.ChangePreviewBus(to: change.previewBus, mixEffect: change.mixEffect))
    }
	controllers.when{ (change: Do.ChangeProgramBus, _) in
		controllers.send(Did.ChangeProgramBus(to: change.programBus, mixEffect: change.mixEffect))
	}
	controllers.when { (change: Do.ChangeTransitionPosition, _) in
		controllers.send(
			Did.ChangeTransitionPosition(
                to: change.position,
                remainingFrames: 250 - UInt8(change.position/40),
                mixEffect: change.mixEffect
            )
        )
    }
	controllers.when { (change: Do.ChangeAuxiliaryOutput, _) in
		controllers.send(Did.ChangeAuxiliaryOutput(source: change.source, output: change.output))
	}

	controllers.when { (request: Do.GetTimecode, connection) in
		let date = Calendar(identifier: .gregorian).dateComponents([.hour, .minute, .second, .nanosecond], from: Date())
		let timecode = Did.GetTimecode(
			hour: UInt8(date.hour!),
			minute: UInt8(date.minute!),
			second: UInt8(date.second!),
			frame: UInt8(date.nanosecond! / 20_000_000)
		)
		connection.send(timecode)
	}

	var data = Data()
	var transfer: Do.StartDataTransfer?
	var fileDescription: Do.SetFileDescription?

	controllers.when { (request: Do.RequestLockPosition, connection) in
		print(request)

		connection.send(Did.ObtainLock(store: 0))
		connection.send(Did.ChangeLock(store: 0, isLocked: true))
	}
	controllers.when { (request: Do.StartDataTransfer, connection) in
		data.removeAll(keepingCapacity: true)
		data.reserveCapacity(Int(request.size))
		transfer = request
		print(request)
		connection.send(
			Do.RequestDataChunks(transferID: request.transferID, chunkSize: 1396, chunkCount: 20)
		)
	}
	controllers.when { (newFileDescription: Do.SetFileDescription, connection) in
		print(newFileDescription)
		if transfer?.transferID == newFileDescription.transferID {
			fileDescription = newFileDescription
			try? data.write(to: URL(fileURLWithPath: "/tmp/atemMedia-\(newFileDescription.name).bin"))
		} else {
			print("File description does not match transfer id")
		}
	}
	controllers.when { (newData: Do.TransferData, connection) in
		print("Got data.")

		if let transfer = transfer, newData.transferID == transfer.transferID {
			data.append(contentsOf: newData.body)

			if let fileDescription = fileDescription, data.count >= transfer.size {
				print("received all bytes for", fileDescription.name)
				connection.send(Did.FinishDataTransfer(id: transfer.transferID))
				connection.send(Did.ChangeLock(store: 0, isLocked: false))
			} else {
				print(Int(transfer.size) - data.count, "bytes remaining")
			}
		}
	}

	
}

dispatchMain()
