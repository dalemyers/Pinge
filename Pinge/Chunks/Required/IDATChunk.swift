//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public class IDATChunk: PNGChunk {

  private var uncompressedData: NSData!

  public override init?(identifier: [Byte], data: [Byte], crc: [Byte]) {
    super.init(identifier: identifier, data: data, crc: crc)

    guard validateCRC() else {
      return nil
    }

    guard extractData() else {
      return nil
    }
  }

  private func extractData() -> Bool {

    guard let deflator = ZlibDeflate(data: data) else {
      return false
    }

    guard let uncompressedData = deflator.deflate() else {
      return false
    }

    self.uncompressedData = uncompressedData

    return true
  }

}