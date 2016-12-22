//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public typealias Byte = UInt8
public enum ColorType: Int {
  case greyscale = 0
  case trueColor = 2
  case indexedColor = 3
  case greyscaleWithAlpha = 4
  case truecolorWithAlpha = 6

  static func isValidValue(_ colorType: Int) -> Bool {
    return colorType >= 0 && colorType <= 6 && colorType != 1 && colorType != 5
  }

  func samples() -> Int {
    switch self {
    case .greyscale:
      return 1
    case .trueColor:
      return 3
    case .indexedColor:
      return 1
    case .greyscaleWithAlpha:
      return 2
    case .truecolorWithAlpha:
      return 4
    }
  }
}

public enum InterlaceMethod: Int {
  case none = 0
  case adam7 = 1

  static func isValidValue(_ interlaceMethod: Int) -> Bool {
    return interlaceMethod == 0 || interlaceMethod == 1
  }
}

public enum FilterType: Int {
  case none = 0
  case sub = 1
  case up = 2
  case average = 3
  case paeth = 4
}
