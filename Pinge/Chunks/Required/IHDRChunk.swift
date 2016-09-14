//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

open class IHDRChunk: PNGChunk {

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
    case .greyscale:
      guard [1,2,4,8,16].contains(bitDepth) else {
        return false
      }
    case .trueColor:
      guard [8,16].contains(bitDepth) else {
        return false
      }
    case .indexedColor:
      guard [1,2,4,8].contains(bitDepth) else {
        return false
      }
    case .greyscaleWithAlpha:
      guard [8,16].contains(bitDepth) else {
        return false
      }
    case .truecolorWithAlpha:
      guard [8,16].contains(bitDepth) else {
        return false
      }
    }

    return true
  }

  private func extractData() -> Bool {
    let data = DataExtractor(data: Data(bytes: dataBytes))

    guard let width = data.nextUInt32(reverseBytes: true) else {
      return false
    }
    self.width = Int(width)

    guard let height = data.nextUInt32(reverseBytes: true) else {
      return false
    }
    self.height = Int(height)

    guard let bitDepth = data.nextUInt8() else {
      return false
    }
    self.bitDepth = Int(bitDepth)

    guard let colorType = data.nextUInt8() else {
      return false
    }
    guard ColorType.isValidValue(Int(colorType)) else {
      return false
    }
    self.colorType = ColorType(rawValue: Int(colorType))

    guard let compressionMethod = data.nextUInt8() else {
      return false
    }
    self.compressionMethod = Int(compressionMethod)

    guard let filterMethod = data.nextUInt8() else {
      return false
    }
    self.filterMethod = Int(filterMethod)

    guard let interlaceMethod = data.nextUInt8() else {
      return false
    }
    guard InterlaceMethod.isValidValue(Int(interlaceMethod)) else {
      return false
    }
    self.interlaceMethod = InterlaceMethod(rawValue: Int(interlaceMethod))

    return true
  }

}
