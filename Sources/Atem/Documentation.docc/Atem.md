# ``Atem``

Implementation of BlackMagicDesign's ATEM network communication protocol.

## Overview

Swift-Atem is written on top of Apple's  networking library [NIO](https://github.com/apple/swift-nio) and implements both sides of the protocol: the controller and the switcher side. This means that you can not only use it to control physical atem switchers but also to connect your control panels to a self made software switcher without the need for an actual physical switcher. This opens a whole new world of applications for the Atem control panels. An example of a software switcher can be found at [Atem-Simulator](https://github.com/Dev1an/Atem-Simulator).

## Topics

### Essentials

This is some explanatory text

- ``Controller``
- ``Switcher``
