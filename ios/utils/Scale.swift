import UIKit

enum Scale {
  private static let baseWidth: CGFloat = 390
  private static let maxWidth: CGFloat = 430
  private static let baseSpacing: CGFloat = 4

  static func value(_ size: CGFloat, factor: CGFloat = 1) -> CGFloat {
    let screenWidth = UIScreen.main.bounds.size.width
    let calcWidth = min(screenWidth, maxWidth)
    let rawSize = (size / baseWidth) * calcWidth
    
    // Trên iOS: làm tròn đến 2 chữ số thập phân
    return (rawSize * 100).rounded() / 100
  }

  static func spacing(_ multiplier: CGFloat) -> CGFloat {
    let designSize = baseSpacing * multiplier
    return value(designSize)
  }
}

