import Foundation
import Dispatch

func fail(_ message: String) -> Never {
  fputs("FAIL: \(message)\n", stderr)
  exit(1)
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
  if !condition() { fail(message) }
}

func same(_ lhs: LunarDate, _ rhs: LunarDate) -> Bool {
  lhs.day == rhs.day && lhs.month == rhs.month && lhs.year == rhs.year
}

func date(_ year: Int, _ month: Int, _ day: Int, in calendar: Calendar) -> Date {
  guard let value = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
    fail("Could not construct \(year)-\(month)-\(day) in \(calendar.timeZone.identifier)")
  }
  return calendar.startOfDay(for: value)
}

func compare(_ value: Date, in timeZone: TimeZone) -> (Int, Int, Int, Int, Bool) {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = timeZone
  let components = calendar.dateComponents([.day, .month, .year], from: value)
  let day = components.day!
  let month = components.month!
  let year = components.year!
  let dayNumber = jdFromDate(day: day, month: month, year: year)
  let offset = timeZone.secondsFromGMT(for: value)
  let cacheHit = (1600...2399).contains(year)
    && LunarMonthSpanCache.shared.value(
      for: dayNumber,
      gregorianYear: year,
      timeZoneIdentifier: timeZone.identifier,
      timeZoneOffsetSeconds: offset
    ) != nil

  let expected = getVietnameseLunarDateExact(value, timeZone)
  let actual = getVietnameseLunarDate(value, timeZone)
  require(same(actual, expected), "\(timeZone.identifier) \(year)-\(month)-\(day): got \(actual.day)/\(actual.month)/\(actual.year), expected \(expected.day)/\(expected.month)/\(expected.year)")
  return (dayNumber, year, offset, expected.day, cacheHit)
}

func runSequence(
  zoneName: String,
  start: (Int, Int, Int),
  end: (Int, Int, Int),
  step: Int
) -> (Int, Int) {
  guard let timeZone = TimeZone(identifier: zoneName) else { fail("Missing timezone \(zoneName)") }
  return runSequence(timeZone: timeZone, start: start, end: end, step: step)
}

func runSequence(
  timeZone: TimeZone,
  start: (Int, Int, Int),
  end: (Int, Int, Int),
  step: Int
) -> (Int, Int) {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = timeZone
  let first = date(start.0, start.1, start.2, in: calendar)
  let last = date(end.0, end.1, end.2, in: calendar)
  var current = first
  var checks = 0
  var misses = 0

  while step > 0 ? current <= last : current >= last {
    let (_, _, _, _, cacheHit) = compare(current, in: timeZone)
    if !cacheHit {
      misses += 1
    }
    checks += 1
    guard let next = calendar.date(byAdding: .day, value: step, to: current), next != current else {
      fail("Date iteration stalled for \(timeZone.identifier)")
    }
    current = next
  }
  return (checks, misses)
}

let primaryZones = [
  ("UTC", (1995, 1, 1), (2035, 12, 31)),
  ("America/New_York", (1995, 1, 1), (2035, 12, 31)),
  ("Australia/Lord_Howe", (1995, 1, 1), (2035, 12, 31)),
  ("Asia/Kathmandu", (1995, 1, 1), (2035, 12, 31)),
  ("Pacific/Apia", (2008, 1, 1), (2016, 12, 31)),
  ("Pacific/Kiritimati", (1990, 1, 1), (2000, 12, 31)),
]

var totalChecks = 0
var totalMisses = 0
for (zone, start, end) in primaryZones {
  let (checks, misses) = runSequence(zoneName: zone, start: start, end: end, step: 1)
  totalChecks += checks
  totalMisses += misses
  print("checked \(checks) days in \(zone); exact fallbacks observed: \(misses)")
}

// Full supported fast-path span, plus pre-epoch and fractional fixed offsets.
let fullUtc = runSequence(
  timeZone: TimeZone(secondsFromGMT: 0)!,
  start: (1600, 1, 1),
  end: (2399, 12, 31),
  step: 1
)
totalChecks += fullUtc.0
totalMisses += fullUtc.1
for (offset, start, end) in [
  (19_800, (1980, 1, 1), (1990, 12, 31)),
  (20_700, (1980, 1, 1), (1990, 12, 31)),
  (-12_600, (1980, 1, 1), (1990, 12, 31)),
] {
  let result = runSequence(
    timeZone: TimeZone(secondsFromGMT: offset)!,
    start: start,
    end: end,
    step: 1
  )
  totalChecks += result.0
  totalMisses += result.1
}
let preEpoch = runSequence(
  zoneName: "UTC",
  start: (1930, 1, 1),
  end: (1975, 12, 31),
  step: 1
)
totalChecks += preEpoch.0
totalMisses += preEpoch.1

// Reverse iteration tests lookup independence from chronological insertion.
let reverse = runSequence(
  zoneName: "America/Los_Angeles",
  start: (2028, 12, 31),
  end: (2020, 1, 1),
  step: -1
)
totalChecks += reverse.0
totalMisses += reverse.1

guard let randomZone = TimeZone(identifier: "America/Santiago") else {
  fail("Missing timezone America/Santiago")
}
var randomCalendar = Calendar(identifier: .gregorian)
randomCalendar.timeZone = randomZone
let randomStart = date(1970, 1, 1, in: randomCalendar)
var randomState: UInt64 = 0x5eed
for _ in 0..<1_200 {
  randomState = randomState &* 6_364_136_223_846_793_005 &+ 1
  let dayOffset = Int(randomState % UInt64(20 * 365))
  let sample = randomCalendar.date(byAdding: .day, value: dayOffset, to: randomStart)!
  _ = compare(sample, in: randomZone)
  totalChecks += 1
}

// Named-zone civil-date skips and date-line transitions.
for (zone, y, m, d) in [
  ("Pacific/Apia", 2011, 12, 29),
  ("Pacific/Apia", 2011, 12, 31),
  ("Pacific/Kiritimati", 1994, 12, 30),
  ("Pacific/Kiritimati", 1995, 1, 1),
] {
  let timeZone = TimeZone(identifier: zone)!
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = timeZone
  _ = compare(date(y, m, d, in: calendar), in: timeZone)
}

// Same civil JDN must not reuse metadata from another time-zone identifier or
// a different actual offset.
let contextZone = TimeZone(secondsFromGMT: 19_800)!
var contextCalendar = Calendar(identifier: .gregorian)
contextCalendar.timeZone = contextZone
let contextDate = date(2123, 7, 15, in: contextCalendar)
let contextComponents = contextCalendar.dateComponents([.day, .month, .year], from: contextDate)
let contextJdn = jdFromDate(day: contextComponents.day!, month: contextComponents.month!, year: contextComponents.year!)
_ = getVietnameseLunarDate(contextDate, contextZone)
require(
  LunarMonthSpanCache.shared.value(
    for: contextJdn,
    gregorianYear: contextComponents.year!,
    timeZoneIdentifier: "GMT+0600",
    timeZoneOffsetSeconds: 19_800
  ) == nil,
  "Cache crossed time-zone identifier contexts"
)
require(
  LunarMonthSpanCache.shared.value(
    for: contextJdn,
    gregorianYear: contextComponents.year!,
    timeZoneIdentifier: contextZone.identifier,
    timeZoneOffsetSeconds: 19_801
  ) == nil,
  "Cache crossed actual GMT-offset contexts"
)

// Pre-epoch modern dates remain eligible; Gregorian-cutover and distant dates
// always use the unchanged exact implementation.
for (zone, y, m, d) in [
  ("UTC", 1600, 1, 1),
  ("UTC", 1582, 10, 15),
  ("UTC", 1599, 12, 31),
  ("UTC", 2399, 12, 31),
  ("UTC", 2400, 1, 1),
] {
  let timeZone = TimeZone(identifier: zone)!
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = timeZone
  _ = compare(date(y, m, d, in: calendar), in: timeZone)
}

// Exercise simultaneous reads/inserts against the shared span cache.
let concurrentZone = TimeZone(identifier: "Asia/Kathmandu")!
var concurrentCalendar = Calendar(identifier: .gregorian)
concurrentCalendar.timeZone = concurrentZone
let concurrentStart = date(2022, 1, 1, in: concurrentCalendar)
var concurrentDates: [Date] = []
for index in 0..<512 {
  concurrentDates.append(
    concurrentCalendar.date(byAdding: .day, value: (index * 37) % 1600, to: concurrentStart)!
  )
}
let mismatchLock = NSLock()
var concurrencyMismatches = 0
DispatchQueue.concurrentPerform(iterations: concurrentDates.count) { index in
  let value = concurrentDates[index]
  let expected = getVietnameseLunarDateExact(value, concurrentZone)
  let actual = getVietnameseLunarDate(value, concurrentZone)
  if !same(actual, expected) {
    mismatchLock.lock()
    concurrencyMismatches += 1
    mismatchLock.unlock()
  }
}
require(concurrencyMismatches == 0, "Concurrent cache access changed results")

let spanMirror = Mirror(reflecting: LunarMonthSpanCache.shared)
guard let spanStorage = spanMirror.children.first(where: { $0.label == "spans" })?.value as? [Any] else {
  fail("Could not inspect bounded span storage")
}
require(spanStorage.count <= 24, "Span cache exceeded its 24-entry bound")

// Verify month-local sequential access uses far fewer exact fallbacks, then
// compare inclusive warm-cache and exact-oracle wall time on the same samples.
let benchmarkZone = TimeZone(identifier: "Europe/London")!
var benchmarkCalendar = Calendar(identifier: .gregorian)
benchmarkCalendar.timeZone = benchmarkZone
let benchmarkStart = date(2070, 1, 1, in: benchmarkCalendar)
let (benchmarkChecks, benchmarkMisses) = runSequence(
  zoneName: benchmarkZone.identifier,
  start: (2070, 1, 1),
  end: (2080, 12, 31),
  step: 1
)
require(benchmarkMisses < benchmarkChecks / 5, "Sequential span cache did not reduce exact fallbacks enough")

var samples: [Date] = []
for day in 0..<365 {
  samples.append(benchmarkCalendar.date(byAdding: .day, value: day, to: benchmarkStart)!)
}
for sample in samples { _ = getVietnameseLunarDate(sample, benchmarkZone) }
let repetitions = 80
let wrappedStart = Date.timeIntervalSinceReferenceDate
var checksum = 0
for _ in 0..<repetitions {
  for sample in samples { checksum += getVietnameseLunarDate(sample, benchmarkZone).day }
}
let wrappedMilliseconds = (Date.timeIntervalSinceReferenceDate - wrappedStart) * 1000
let exactStart = Date.timeIntervalSinceReferenceDate
for _ in 0..<repetitions {
  for sample in samples { checksum += getVietnameseLunarDateExact(sample, benchmarkZone).day }
}
let exactMilliseconds = (Date.timeIntervalSinceReferenceDate - exactStart) * 1000

print("validated \(totalChecks) serial date accesses; observed span exact fallbacks \(totalMisses)")
print("sequential 11-year stream: \(benchmarkMisses)/\(benchmarkChecks) exact fallbacks")
print("warm wrapper \(Int(wrappedMilliseconds))ms vs exact oracle \(Int(exactMilliseconds))ms over \(samples.count * repetitions) conversions")
print("bounded span count: \(spanStorage.count)/24; concurrent checks: \(concurrentDates.count)")
print("benchmark checksum: \(checksum)")
print("PASS: lunar span cache equals exact oracle across tested dates/time zones")
