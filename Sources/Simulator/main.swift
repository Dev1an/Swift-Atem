//
//  File.swift
//  
//
//  Created by Damiaan on 20/11/2019.
//

import Atem
import Dispatch

let switcher = try Switcher { handler, allControllers in
    handler.when { (change: ChangePreviewBus, _) in
		allControllers.send(PreviewBusChanged(to: change.previewBus, mixEffect: change.mixEffect))
    }
    handler.when{ (change: ChangeProgramBus, _) in
		allControllers.send(ProgramBusChanged(to: change.programBus, mixEffect: change.mixEffect))
	}
    handler.when { (change: ChangeTransitionPosition, _) in
		allControllers.send(
            TransitionPositionChanged(
                to: change.position,
                remainingFrames: 250 - UInt8(change.position/40),
                mixEffect: change.mixEffect
            )
        )
    }
	handler.when { (change: ChangeAuxiliaryOutput, _) in
		allControllers.send(AuxiliaryOutputChanged(source: change.source, output: change.output))
	}
}

print(switcher)
dispatchMain()
//print(switcher)
