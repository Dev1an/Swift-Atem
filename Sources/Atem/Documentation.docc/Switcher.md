# ``Atem/Switcher``
@Metadata {
	@DocumentationExtension(mergeBehavior: append)
}

The software switcher is a component that can
- accept connections from control panels (or ``Controller``s) and keep them alive
- receive messages from connected controllers
- send replies to individual controllers in response to received commands
- send messages to all connected controllers

## Create a simple switcher

To create a switcher that is only used to send messages, use the simplified ``init(eventLoopGroup:setup:)`` initializer.
```swift
let switcher = Switcher()
```

## Sending messages to all connected controllers

Use
