<p align="center">
    <img src="https://img.shields.io/badge/swift-5.1-orange.svg" alt="Swift 5.1">
    <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-brightgreen.svg" alt="Platforms: macOS & Linux">
</p>

# Atem network protocol implementation

Implementation of BlackMagicDesign's ATEM communication protocol in Swift. It is written on top of Apple's  networking library [NIO](https://github.com/apple/swift-nio) and implements both sides of the protocol: the control panel and the switcher side. This means that you can not only use it to control atem switchers but also to connect to your control panels without the need for a switcher. Opening a whole new world of applications for the Atem control panels. An example can be found at [Atem-Simulator](https://github.com/Dev1an/Atem-Simulator)

Starting from version 1.0.0 this package uses Swift 5 and NIO2.

### Tested platforms

- macOS 10.13.4 on a MacBook Pro retina 15" late 2013
- Raspbian GNU/Linux 9 stretch on a Raspberry Pi model 3 B

## Installation

When starting a new project: create a Swift package via [SPM](https://swift.org/package-manager/)

```shell
# Shell
> swift package init # --type empty|library|executable|system-module
```

Then add this library to the [package description](https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md#dependencies)'s dependencies

```swift
.package(url: "https://github.com/Dev1an/Swift-Atem", from: "1.0.0")
```

And resolve this new dependency

```sh
# Shell
> swift package resolve
```

Finally import the `Atem` module in your code

```swift
import Atem
```

You are now ready to create atem controllers and switchers 😎 !

## Usage

After looking at the following examples, study the [API reference](https://dev1an.github.io/Swift-Atem/) for more details.

### Controller

This example shows how to create a controller that connects to a swicther at ip address 10.1.0.67 and print a message whenever the preview bus changes.

```swift
try Controller(ipAddress: "10.1.0.67") { handler in
    handler.when{ (change: PreviewBusChanged) in
        print(change) // prints: 'Preview bus changed to input(x)'
    }
}
```

### Switcher

The following example shows how to emulate the basic functionality of an atem switcher. It will forward incoming messages containing transition and preview & program bus changes to the connected controller.

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
