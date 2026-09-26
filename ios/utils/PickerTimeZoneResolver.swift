import Foundation

/// Resolves a fixed UTC offset or falls back to the current device timezone.
enum PickerTimeZoneResolver {
  static func resolve(offsetHours: Double?) -> TimeZone {
    guard let offsetHours = offsetHours, offsetHours.isFinite else { return .current }
    let offsetSeconds = offsetHours * 3_600
    guard (-64_800...64_800).contains(offsetSeconds) else { return .current }
    return TimeZone(secondsFromGMT: Int(offsetSeconds.rounded())) ?? .current
  }
}
