//
//  Queue.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 6/16/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import Foundation

public struct Queue {
    fileprivate var array = [Int]()
    fileprivate var nextIndex: Int = 0
    fileprivate var pushIndex: Int = 0

    public init(size: Int) {
        array = [Int](repeating: 0, count: size)
    }

    public var isEmpty: Bool {
        return nextIndex == pushIndex
    }

    public var count: Int {
        return pushIndex - nextIndex
    }

    public mutating func push(_ element: Int) {
        array[pushIndex] = element
        pushIndex += 1
    }

    public mutating func pop() -> Int? {
        nextIndex += 1
        return array[nextIndex - 1]
    }

    public var next: Int? {
        return nextIndex < pushIndex ? array[nextIndex] : nil
    }
}
