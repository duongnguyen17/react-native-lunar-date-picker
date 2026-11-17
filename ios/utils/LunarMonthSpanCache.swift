import Foundation

/// Bounded cache for exact lunar-month metadata.
final class LunarMonthSpanCache {
  static let shared = LunarMonthSpanCache()

  private struct Span {
    let startDayNumber: Int
    let gregorianYear: Int
    let timeZoneIdentifier: String
    let timeZoneOffsetSeconds: Int
    let lunarMonth: Int
    let lunarYear: Int
    var hasDay30: Bool
  }

  private let lock = NSLock()
  private let maximumSpanCount = 24
  private var spans: [Span] = []

  private init() {}

  func value(
    for dayNumber: Int,
    gregorianYear: Int,
    timeZoneIdentifier: String,
    timeZoneOffsetSeconds: Int
  ) -> LunarDate? {
    lock.lock()
    defer { lock.unlock() }

    guard let index = spans.lastIndex(where: { span in
      span.gregorianYear == gregorianYear
        && span.timeZoneIdentifier == timeZoneIdentifier
        && span.timeZoneOffsetSeconds == timeZoneOffsetSeconds
        && ((1...29).contains(dayNumber - span.startDayNumber + 1)
          || (dayNumber - span.startDayNumber + 1 == 30 && span.hasDay30))
    }) else { return nil }

    let span = spans.remove(at: index)
    spans.append(span)
    return LunarDate(
      day: dayNumber - span.startDayNumber + 1,
      month: span.lunarMonth,
      year: span.lunarYear
    )
  }

  func recordExact(
    _ lunarDate: LunarDate,
    dayNumber: Int,
    gregorianYear: Int,
    timeZoneIdentifier: String,
    timeZoneOffsetSeconds: Int
  ) {
    guard (1...30).contains(lunarDate.day), (1...12).contains(lunarDate.month)
    else { return }
    let start = dayNumber - lunarDate.day + 1

    lock.lock()
    defer { lock.unlock() }

    let index = spans.firstIndex(where: {
      $0.startDayNumber == start
        && $0.gregorianYear == gregorianYear
        && $0.timeZoneIdentifier == timeZoneIdentifier
        && $0.timeZoneOffsetSeconds == timeZoneOffsetSeconds
    })
    let old = index.map { spans.remove(at: $0) }
    let hasDay30: Bool
    if lunarDate.day == 30 {
      hasDay30 = true
    } else if let old,
      old.lunarMonth == lunarDate.month,
      old.lunarYear == lunarDate.year
    {
      hasDay30 = old.hasDay30
    } else {
      hasDay30 = false
    }
    spans.append(
      Span(
        startDayNumber: start,
        gregorianYear: gregorianYear,
        timeZoneIdentifier: timeZoneIdentifier,
        timeZoneOffsetSeconds: timeZoneOffsetSeconds,
        lunarMonth: lunarDate.month,
        lunarYear: lunarDate.year,
        hasDay30: hasDay30
      )
    )
    if spans.count > maximumSpanCount {
      spans.removeFirst(spans.count - maximumSpanCount)
    }
  }
}
