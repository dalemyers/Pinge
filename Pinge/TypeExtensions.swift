//
//  TypeExtensions.swift
//  Pinge
//
//  Created by Dale Myers on 11/09/2016.
//  Copyright © 2016 Dale Myers. All rights reserved.
//

import Foundation

internal extension Data {

  internal func uint32(fromOffset offset: Int, reverseBytes: Bool = false) -> UInt32? {

    guard offset + 3 <= self.count else {
      return nil
    }

    var result: UInt32 = 0

    withUnsafeMutablePointer(to: &result, { pResult32 in
      pResult32.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt32>.size, { pResult8 in
        self.copyBytes(to: pResult8, from: offset..<(offset + 4))
      })
    })

    if reverseBytes {
      return CFSwapInt32(result)
    }

    return result
  }

  internal func uint8(fromOffset offset: Int) -> UInt8? {

    guard offset <= self.count else {
      return nil
    }

    var result: UInt8 = 0

    withUnsafeMutablePointer(to: &result, { pResult8 in
      self.copyBytes(to: pResult8, from: offset..<(offset + 1))
    })

    return result
  }

}
