# ``Atem/Controller``
@Metadata {
	@DocumentationExtension(mergeBehavior: append)
}

This controller can:
- send commands to an ATEM Switcher
- react upon incomming state change messages from the ATEM Switcher

To make an anology with real world devices: this class can be compared to a BlackMagicDesign Control Panel. It is used to control a production switcher.

## Creating a simple controller

When you only need to **send** messages from your controller, you can create a controller using ``init(forSwitcherAt:eventLoopGroup:setup:)``. Simply pass it the IP address of the switcher you want to control:

```swift
let controller = try Controller(forSwitcherAt: "10.1.0.67")
```

## Sending messages

To send a message, pass it to the controller's ``send(message:)`` method.

```swift
controller.send( Do.Cut() )
```

## Receiving messages

To receive messages from the switcher, you need to setup a listener during the initialisation of your controller:
```swift
try Controller(forSwitcherAt: "10.1.0.67") { connection in
  connection.when{ (change: PreviewBusChanged) in
    print(change) // prints: 'Preview bus changed to input(x)'
  }
}
```

## Topics

### Initializers
- ``init(forSwitcherAt:eventLoopGroup:setup:)``
- ``init(socket:eventLoopGroup:setup:)``

### Sending messages
- ``send(message:)``

### Uploading images
- ``uploadStill(slot:data:uncompressedSize:name:description:)``
- ``uploadLabel(source:labelImage:longName:shortName:)``
