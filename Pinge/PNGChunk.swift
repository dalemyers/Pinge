//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public typealias Byte = UInt8

public class PNGChunk {

  internal var identifier: [Byte]
  internal var data: [Byte]
  internal var crc: [Byte]

  public init?(identifier: [Byte], data: [Byte], crc: [Byte]) {
    self.identifier = identifier
    self.data = data
    self.crc = crc
  }

  public func chunkIdentifier() -> String {
    guard let stringIdentifier = String(bytes: identifier, encoding: NSUTF8StringEncoding) else {
      return "????"
    }
    return stringIdentifier
  }

  internal func validateCRC() -> Bool {
    // TODO
    return true
  }

}