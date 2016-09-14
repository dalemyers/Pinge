//
//  DataExtractor.swift
//  Pinge
//
//  Created by Dale Myers on 14/09/2016.
//  Copyright © 2016 Dale Myers. All rights reserved.
//

import Foundation

internal class DataExtractor {

  private var offset = 0
  private var data: Data

  init(data: Data, offset: Int = 0) {
    self.data = data
    self.offset = offset
  }

  internal func remainingData() -> Bool {
    return offset < self.data.count
  }

  internal func bytesRemaining() -> Int {
    return self.data.count - offset
  }

  internal func nextUInt8() -> UInt8? {

    guard offset <= self.data.count else {
      return nil
    }

    var result: UInt8 = 0

    withUnsafeMutablePointer(to: &result, { pResult8 in
      self.copyNextBytes(to: pResult8, length: 1)
    })

    return result
  }

  internal func nextUInt32(reverseBytes: Bool = false) -> UInt32? {

    guard offset + 3 <= self.data.count else {
      return nil
    }

    var result: UInt32 = 0

    withUnsafeMutablePointer(to: &result, { pResult32 in
      pResult32.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt32>.size, { pResult8 in
        self.copyNextBytes(to: pResult8, length: 4)
      })
    })

    if reverseBytes {
      return CFSwapInt32(result)
    }

    return result
  }

  internal func copyNextBytes(to pointer: UnsafeMutablePointer<UInt8>, length: Int) {
    var length = length

    // If our copy will exceed the bounds, shrink the length parameter to fit
    if offset + length >= self.data.count {
      length = self.data.count - offset
    }

    guard length > 0 else {
      return
    }

    self.data.copyBytes(to: pointer, from: offset..<(offset + length))

    offset += length
  }

}
