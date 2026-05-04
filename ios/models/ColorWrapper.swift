//
//  ColorWrapper.swift
//  LunarDatePicker
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation
import UIKit

/// A wrapper struct for UIColor that can be safely used in Swift-C++ interop
/// This struct contains primitive types that can be bridged to C++ without issues
public struct ColorWrapper {
  public let red: Double
  public let green: Double
  public let blue: Double
  public let alpha: Double

  public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  /// Create from UIColor - internal to avoid Swift-C++ interop exposure
  internal init(from uiColor: UIColor) {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

    self.red = Double(r)
    self.green = Double(g)
    self.blue = Double(b)
    self.alpha = Double(a)
  }
}

// MARK: - Predefined Colors
extension ColorWrapper {
  public static let customBlack = ColorWrapper(
    red: 18.0 / 255.0,
    green: 18.0 / 255.0,
    blue: 18.0 / 255.0,
    alpha: 1.0
  )
  public static let customWhite = ColorWrapper(
    red: 1.0,
    green: 1.0,
    blue: 1.0,
    alpha: 1.0
  )
  public static let weekendColor = ColorWrapper(
    red: 2.0 / 255.0,
    green: 88.0 / 255.0,
    blue: 156.0 / 255.0,
    alpha: 1.0
  )
  public static let darkLunarDateColor = ColorWrapper(
    red: 107.0 / 255.0,
    green: 115.0 / 255.0,
    blue: 128.0 / 255.0,
    alpha: 1.0
  )
  public static let lightLunarDateColor = darkLunarDateColor
  public static let systemBlue = ColorWrapper(
    red: 0.0,
    green: 122.0 / 255.0,
    blue: 1.0,
    alpha: 1.0
  )
  public static let systemRed = ColorWrapper(
    red: 1.0,
    green: 59.0 / 255.0,
    blue: 48.0 / 255.0,
    alpha: 1.0
  )
  public static let label = ColorWrapper(
    red: 0.0,
    green: 0.0,
    blue: 0.0,
    alpha: 1.0
  )
  public static let tertiaryLabel = ColorWrapper(
    red: 60.0 / 255.0,
    green: 60.0 / 255.0,
    blue: 67.0 / 255.0,
    alpha: 0.3
  )
}

// MARK: - Internal UIColor Conversion
// This extension is internal to prevent Swift-C++ interop exposure
extension ColorWrapper {
  /// Convert to UIColor for actual usage
  func toUIColor() -> UIColor {
    return UIColor(
      red: CGFloat(red),
      green: CGFloat(green),
      blue: CGFloat(blue),
      alpha: CGFloat(alpha)
    )
  }

  /// Convenience computed property for internal use
  var uiColor: UIColor {
    return toUIColor()
  }

  /// Create ColorWrapper from hex string (e.g., "#FF0000" or "FF0000")
  init(fromHex hexString: String) {
    let hex = hexString.trimmingCharacters(
      in: CharacterSet.alphanumerics.inverted
    )
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (
        255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17
      )
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }

    self.init(
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      alpha: Double(a) / 255
    )
  }
}
