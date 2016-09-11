//
// Copyright Dale Myers
//

import Foundation

open class IDATChunk: PNGChunk {

  public override init?(identifier: [Byte], data: [Byte], crc: [Byte]) {
    super.init(identifier: identifier, data: data, crc: crc)

    guard validateCRC() else {
      return nil
    }
  }

}
