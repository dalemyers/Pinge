//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

open class PLTEChunk: PNGChunk {

  public var paletteEntries = [UIColor]()

  public override init?(identifier: [Byte], data: [Byte], crc: [Byte]) {
    super.init(identifier: identifier, data: data, crc: crc)

    guard data.count % 3 == 0 else {
      return nil
    }

    guard data.count >= 3 && data.count <= (256 * 3) else {
      return nil
    }

    guard validateCRC() else {
      return nil
    }

    guard extractData() else {
      return nil
    }
  }

  private func extractData() -> Bool {

    for i in 0..<(dataBytes.count / 3) {
      let red: UInt8 = dataBytes[i * 3 + 0]
      let green: UInt8 = dataBytes[i * 3 + 1]
      let blue: UInt8 = dataBytes[i * 3 + 2]
      let color = UIColor(
        red: (CGFloat(red) / 255.0),
        green: (CGFloat(green) / 255.0),
        blue: (CGFloat(blue) / 255.0),
        alpha: 1.0
      )
      paletteEntries.append(color)
    }

    return true
  }

}
