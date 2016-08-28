//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public typealias Byte = UInt8

public class PNGChunk {

  internal var identifier: [Byte]
  internal var data: [Byte]
  internal var crc: [Byte]

  public var isAncillary: Bool {
    return true
  }

  public init?(identifier: [Byte], data: [Byte], crc: [Byte]) {
    guard identifier.count == 4 else {
      return nil
    }

    guard crc.count == 4 else {
      return nil
    }

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