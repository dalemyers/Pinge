//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public class IDATChunk: PNGChunk {

  public override init?(identifier: [Byte], data: [Byte], crc: [Byte]) {
    super.init(identifier: identifier, data: data, crc: crc)

    guard validateCRC() else {
      return nil
    }
  }

}