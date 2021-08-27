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

Use ``send(message:)`` to send a message to all the connected controllers.
```swift
switcher.send(message: Did.Cut())
// Informs all the connected controllers that you performed a cut.
```

## Replying to incoming messages

To reply to incoming messages, initialize the switcher with a `setup` function. Inside the `setup` function add message handlers (using ``SwitcherConnections/when(_:)``) for each message you want to reply to.

You can choose to send your reply only to the controller that send you the message or you can reply to all the connected controllers.

### Reply only to the sender using the message context
To reply only to the controller that sent you the message, use the ``ConnectionState``'s ``ConnectionState/send(_:asSeparatePackage:)`` method.

```swift
let switcher = Switcher { connections in
  connections.when { (request: Do.RequestLockPosition, context) in
    context.send( Did.ObtainLock(store:request.store) )
  }
}
```

### Reply to all connected clients
To reply to all connected clients, use the ``SwitcherConnections``'s ``SwitcherConnections/send(_:)`` method

``Message/Do/ChangeProgramBus/init(to:mixEffect:)``

```swift
let switcher = Switcher { connections in
  connections.when { (request: Do.ChangeProgramBus, context) in
    connections.send( Did.ObtainLock(store:request.store) )
  }
}
```

## Topics

### Initializers
- ``init(eventLoopGroup:setup:)``

### Sending messages
- ``send(message:)``
