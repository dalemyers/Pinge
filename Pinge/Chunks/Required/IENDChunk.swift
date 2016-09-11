//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

open class IENDChunk: PNGChunk {

  public override init?(identifier: [Byte], data: [Byte], crc: [Byte]) {
    super.init(identifier: identifier, data: data, crc: crc)

    guard data.count == 0 else {
      return nil
    }

    guard validateCRC() else {
      return nil
    }
  }

}
