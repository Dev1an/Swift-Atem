//
//  File.swift
//  File
//
//  Created by Damiaan on 26/08/2021.
//

import NIO

public let sharedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
