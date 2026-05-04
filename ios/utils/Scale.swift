import UIKit

enum Scale {
  private static let guidelineBaseWidth: CGFloat = 375

  private static var widthRatio: CGFloat = {
    let screen = UIScreen.main.bounds.size
    let short = min(screen.width, screen.height)
    let ratio = short / guidelineBaseWidth
    return (ratio * 100).rounded() / 100
  }()

  private static var disableScale: Bool = {
    widthRatio <= 1
  }()

  static func value(_ size: CGFloat, factor: CGFloat = 1) -> CGFloat {
    if disableScale { return size }
    let scaled = size + ((size * widthRatio) - size) * factor
    return (scaled * 100).rounded() / 100
  }
}

