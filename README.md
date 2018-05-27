# Atem network protocol implementation

Implementation of BlackMagicDesign's ATEM communication protocol in Swift. It is written on top of Apple's new networking library [NIO](https://github.com/apple/swift-nio) and implements both sides of the protocol: the control panel and the switcher side. This means that you can not only use it to control atem switchers but also to connect to your control panels without the need for a switcher. Opening a whole new world of applications for the Atem control panels. An example can be found at [Atem-Simulator](https://github.com/Dev1an/Atem-Simulator)

## Usage

After looking at the following examples, study the [API reference](https://dev1an.github.io/Swift-Atem/) for more details.

### Controller

This example shows how to print a message when the preview bus changes

```swift
try Controller(ipAddress: "10.1.0.67") { handler in
    handler.when{ (change: PreviewBusChanged) in
        print(change) // prints: 'Preview bus changed to input(x)'
    }
}
```

### Switcher

The following example shows you how to emulate the basic functionality of an atem switcher. It forwards the messages containing transition and preview & program bus changes to the connected controller.

```swift
try Switcher { handler in
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
}
```