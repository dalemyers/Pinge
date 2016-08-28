//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public class PLTEChunk: PNGChunk {

  public var paletteEntries = [UIColor]()

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

    guard data.count % 3 == 0 else {
      return false
    }

    guard data.count >= 3 && data.count <= (256 * 3) else {
      return false
    }

    let nsdata = NSData(bytes: &data, length: data.count)

    for i in 0..<(data.count / 3) {
      var red: UInt8 = 0
      var green: UInt8 = 0
      var blue: UInt8 = 0
      nsdata.getBytes(&red,   range: NSMakeRange(i * 3 + 0, sizeof(UInt8)))
      nsdata.getBytes(&green, range: NSMakeRange(i * 3 + 1, sizeof(UInt8)))
      nsdata.getBytes(&blue,  range: NSMakeRange(i * 3 + 2, sizeof(UInt8)))
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