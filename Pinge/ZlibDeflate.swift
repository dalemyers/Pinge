//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

class ZlibDeflate {

  private var crcValue: [Byte]
  private var compressedData: [Byte]
  private var uncompressedData = NSMutableData()
  private var windowSize: Int = 0
  private var dictionaryIdentifierPresent: Bool = false
  private var compressionLevel: Int = 0

  init?(data: [Byte]) {
    guard data.count >= 6 else {
      return nil
    }

    compressedData = Array(data[2..<(data.count - 4)])
    crcValue = Array(data[(data.count - 4) ..< data.count])

    guard extractMetadata(data) else {
      return nil
    }
  }

  private func extractMetadata(data: [Byte]) -> Bool {
    let cmf = data[0]
    let flg = data[1]

    let compressionMethod = cmf & 0x0F
    let compressionInfo = (cmf >> 4) & 0x0F

    // Deflate compression
    guard compressionMethod == 8 else {
      return false
    }

    // Get window size
    guard compressionInfo <= 7 else {
      return false
    }

    windowSize = Int(pow(2.0, Double(compressionInfo + 8)))

    // Make sure a preset dictionary hasn't been specified (not allowed for PNG)
    guard Int((flg >> 5) & 0x01) == 0 else {
      return false
    }

    // Get the compression level (0, 1, 2 or 3)
    compressionLevel = Int((flg >> 6) & 0x03)

    // Check the flag check sum
    guard ((Int(cmf) * 256) + Int(flg)) % 31 == 0 else {
      return false
    }

    return true
  }

  internal func deflate() -> NSData? {


    return uncompressedData
  }

}