//
//  File.swift
//  
//
//  Created by Damiaan on 20/11/2019.
//

import Atem
import Dispatch

let switcher = try Switcher { handler in
    handler.when { (change: ChangePreviewBus) in
        return [PreviewBusChanged(to: change.previewBus, mixEffect: change.mixEffect)]
    }
    handler.when{ (change: ChangeProgramBus) in
        return [ProgramBusChanged(to: change.programBus, mixEffect: change.mixEffect)]
    }
    handler.when { (change: ChangeTransitionPosition) in
        return [
            TransitionPositionChanged(
                to: change.position,
                remainingFrames: 250 - UInt8(change.position/40),
                mixEffect: change.mixEffect
            )
        ]
    }
	handler.when { (change: ChangeAuxiliaryOutput) in
		return [AuxiliaryOutputChanged(source: change.source, output: change.output)]
	}
}

print(switcher)
dispatchMain()
//print(switcher)
