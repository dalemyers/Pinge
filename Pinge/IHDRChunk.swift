//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public class IHDRChunk: PNGChunk {

  public var width: Int!
  public var height: Int!
  public var bitDepth: Int!
  public var colorType: ColorType!
  public var compressionMethod: Int!
  public var filterMethod: Int!
  public var interlaceMethod: InterlaceMethod!

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
    var offset: Int = 0

    guard data.count == 13 else {
      return false
    }

    let nsdata = NSData(bytes: &data, length: data.count)

    var reversedWidth: UInt32 = 0
    nsdata.getBytes(&reversedWidth, range: NSMakeRange(offset, sizeof(UInt32)))
    width = Int(CFSwapInt32(reversedWidth))
    offset += 4

    var reversedHeight: UInt32 = 0
    nsdata.getBytes(&reversedHeight, range: NSMakeRange(offset, sizeof(UInt32)))
    height = Int(CFSwapInt32(reversedHeight))
    offset += sizeof(UInt32)

    var reversedBitDepth: UInt8 = 0
    nsdata.getBytes(&reversedBitDepth, range: NSMakeRange(offset, sizeof(UInt8)))
    bitDepth = Int(reversedBitDepth)
    offset += sizeof(UInt8)

    var reversedColorType: UInt8 = 0
    nsdata.getBytes(&reversedColorType, range: NSMakeRange(offset, sizeof(UInt8)))
    guard ColorType.isValidValue(Int(reversedColorType)) else {
      return false
    }
    colorType = ColorType(rawValue: Int(reversedColorType))
    offset += sizeof(UInt8)

    var reversedCompressionMethod: UInt8 = 0
    nsdata.getBytes(&reversedCompressionMethod, range: NSMakeRange(offset, sizeof(UInt8)))
    compressionMethod = Int(reversedCompressionMethod)
    guard compressionMethod == 0 else {
      return false
    }
    offset += sizeof(UInt8)

    var reversedFilterMethod: UInt8 = 0
    nsdata.getBytes(&reversedFilterMethod, range: NSMakeRange(offset, sizeof(UInt8)))
    filterMethod = Int(reversedFilterMethod)
    guard filterMethod == 0 else {
      return false
    }
    offset += sizeof(UInt8)

    var reversedInterlaceMethod: UInt8 = 0
    nsdata.getBytes(&reversedInterlaceMethod, range: NSMakeRange(offset, sizeof(UInt8)))
    guard InterlaceMethod.isValidValue(Int(reversedInterlaceMethod)) else {
      return false
    }
    interlaceMethod = InterlaceMethod(rawValue: Int(reversedInterlaceMethod))

    return true
  }

}