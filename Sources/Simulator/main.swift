//
//  File.swift
//  
//
//  Created by Damiaan on 20/11/2019.
//

import Atem
import Dispatch

let switcher = Switcher { controllers in
    controllers.when { (change: ChangePreviewBus, _) in
		controllers.send(PreviewBusChanged(to: change.previewBus, mixEffect: change.mixEffect))
    }
    controllers.when{ (change: ChangeProgramBus, _) in
		controllers.send(ProgramBusChanged(to: change.programBus, mixEffect: change.mixEffect))
	}
    controllers.when { (change: ChangeTransitionPosition, _) in
		controllers.send(
            TransitionPositionChanged(
                to: change.position,
                remainingFrames: 250 - UInt8(change.position/40),
                mixEffect: change.mixEffect
            )
        )
    }
	controllers.when { (change: ChangeAuxiliaryOutput, _) in
		controllers.send(AuxiliaryOutputChanged(source: change.source, output: change.output))
	}

	controllers.when { (request: LockPositionRequest, connection) in
		print("Lock request")
		connection.send(LockObtained(frameNumber: 0))
		connection.send(LockChange(store: 0, isLocked: true))
	}
	controllers.when { (request: StartDataTransfer, connection) in
		print(request)
		connection.send(
			ContinueDataTransfer(transferID: request.transferID, chunkSize: 1396, chunkCount: 20)
		)
	}
	controllers.when { (fileDescription: SetFileDescription, connection) in
		print(fileDescription)
	}
	controllers.when { (data: TransferData, connection) in
		print("Got data. Sending transfer finish")
		connection.send(DataTransferCompleted(id: data.transferID))
		connection.send(LockChange(store: 0, isLocked: false))
	}

	
}

dispatchMain()
