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

    guard data.count == 13 else {
      return nil
    }

    guard validateCRC() else {
      return nil
    }

    guard extractData() else {
      return nil
    }

    // It would be more efficient to validate the data as we go, but this 
    // project is about simplicity and clarity.
    guard validateData() else {
      return nil
    }
  }

  private func validateData() -> Bool {
    guard width != 0 && height != 0 else {
      return false
    }

    guard filterMethod == 0 else {
      return false
    }

    guard compressionMethod == 0 else {
      return false
    }

    switch colorType! {
    case .Greyscale:
      guard [1,2,4,8,16].contains(bitDepth) else {
        return false
      }
    case .TrueColor:
      guard [8,16].contains(bitDepth) else {
        return false
      }
    case .IndexedColor:
      guard [1,2,4,8].contains(bitDepth) else {
        return false
      }
    case .GreyscaleWithAlpha:
      guard [8,16].contains(bitDepth) else {
        return false
      }
    case .TruecolorWithAlpha:
      guard [8,16].contains(bitDepth) else {
        return false
      }
    }

    return true
  }

  private func extractData() -> Bool {
    var offset: Int = 0

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
    offset += sizeof(UInt8)

    var reversedFilterMethod: UInt8 = 0
    nsdata.getBytes(&reversedFilterMethod, range: NSMakeRange(offset, sizeof(UInt8)))
    filterMethod = Int(reversedFilterMethod)
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