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
    var offset: Int = 0

    let data = Data(bytes: dataBytes)

    guard let width = data.uint32(fromOffset: offset, reverseBytes: true) else {
      return false
    }
    self.width = Int(width)
    offset += 4

    guard let height = data.uint32(fromOffset: offset, reverseBytes: true) else {
      return false
    }
    self.height = Int(height)
    offset += 4

    guard let bitDepth = data.uint8(fromOffset: offset) else {
      return false
    }
    self.bitDepth = Int(bitDepth)
    offset += 1

    guard let colorType = data.uint8(fromOffset: offset) else {
      return false
    }
    guard ColorType.isValidValue(Int(colorType)) else {
      return false
    }
    self.colorType = ColorType(rawValue: Int(colorType))
    offset += 1

    guard let compressionMethod = data.uint8(fromOffset: offset) else {
      return false
    }
    self.compressionMethod = Int(compressionMethod)
    offset += 1

    guard let filterMethod = data.uint8(fromOffset: offset) else {
      return false
    }
    self.filterMethod = Int(filterMethod)
    offset += 1

    guard let interlaceMethod = data.uint8(fromOffset: offset) else {
      return false
    }
    guard InterlaceMethod.isValidValue(Int(interlaceMethod)) else {
      return false
    }
    self.interlaceMethod = InterlaceMethod(rawValue: Int(interlaceMethod))

    return true
  }

}
