//
//  Copyright 2013-2016 Microsoft Inc.
//

import Foundation

public enum ColorType: Int {
  case Greyscale = 0,
  TrueColor = 2,
  IndexedColor = 3,
  GreyscaleWithAlpha = 4,
  TruecolorWithAlpha = 6

  static func isValidValue(colorType: Int) -> Bool {
    return colorType >= 0 && colorType <= 6 && colorType != 1 && colorType != 5
  }

  func samples() -> Int {
    switch self {
    case .Greyscale:
      return 1
    case .TrueColor:
      return 3
    case .IndexedColor:
      return 1
    case .GreyscaleWithAlpha:
      return 2
    case .TruecolorWithAlpha:
      return 4
    }
  }
}

public enum InterlaceMethod: Int {
  case None = 0, Adam7 = 1

  static func isValidValue(interlaceMethod: Int) -> Bool {
    return interlaceMethod == 0 || interlaceMethod == 1
  }
}

public enum FilterType: Int {
  case None = 0,
    Sub = 1,
    Up = 2,
    Average = 3,
    Paeth = 4
}