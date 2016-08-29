//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public class IDATChunk: PNGChunk {

  private var uncompressedData: NSData!

  // TODO add support for multiple IDAT chunks (contents all concatenated 
  // together make up the zlib stream

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
    let zlib = Zlib(data: data)

    guard let uncompressedData = zlib.inflateStream() else {
      return false
    }

    self.uncompressedData = uncompressedData

    return true
  }

}