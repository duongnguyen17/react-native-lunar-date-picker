//
//  LunarDateUtil.swift
//  Pods
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation

func jdFromDate(day: Int, month: Int, year: Int) -> Int {
  let a = (14 - month) / 12
  let y = year + 4800 - a
  let m = month + 12 * a - 3
  let jd =
    day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400
    - Constants.Julian.dayConstant
  return jd < Constants.Julian.dayThreshold
    ? day + (153 * m + 2) / 5 + 365 * y + y / 4
      - Constants.Julian.dayConstantOld : jd
}

func getNewMoonDay(k: Int, timeZone: Int) -> Int {
  let T = Double(k) / 1236.85
  let T2 = T * T
  let T3 = T2 * T
  let dr = Double.pi / 180
  let Jd1 =
    2415020.75933 + Constants.Julian.lunarMonthDays * Double(k) + 0.0001178 * T2
    - 0.000000155 * T3
    + 0.00033 * sin((166.56 + 132.87 * T - 0.009173 * T2) * dr)

  let M = 359.2242 + 29.10535608 * Double(k) - 0.0000333 * T2 - 0.00000347 * T3
  let Mpr =
    306.0253 + 385.81691806 * Double(k) + 0.0107306 * T2 + 0.00001236 * T3
  let F = 21.2964 + 390.67050646 * Double(k) - 0.0016528 * T2 - 0.00000239 * T3

  var C1 = (0.1734 - 0.000393 * T) * sin(dr * M)
  C1 += 0.0021 * sin(2 * dr * M)
  C1 -= 0.4068 * sin(dr * Mpr)
  C1 += 0.0161 * sin(2 * dr * Mpr)
  C1 -= 0.0004 * sin(3 * dr * Mpr)
  C1 += 0.0104 * sin(2 * dr * F)
  C1 -= 0.0051 * sin(dr * (M + Mpr))
  C1 -= 0.0074 * sin(dr * (M - Mpr))
  C1 += 0.0004 * sin(dr * (2 * F + M))
  C1 -= 0.0004 * sin(dr * (2 * F - M))
  C1 -= 0.0006 * sin(dr * (2 * F + Mpr))
  C1 += 0.0010 * sin(dr * (2 * F - Mpr))
  C1 += 0.0005 * sin(dr * (2 * Mpr + M))

  let deltaT =
    T < -11
    ? 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T
      * T3
    : -0.000278 + 0.000265 * T + 0.000262 * T2

  let JdNew = Jd1 + C1 - deltaT
  return Int(floor(JdNew + 0.5 + Double(timeZone) / 24))
}

func getSunLongitude(jdn: Int, timeZone: Int) -> Int {
  let T = (Double(jdn) - 2451545.5 - Double(timeZone) / 24) / 36525
  let T2 = T * T
  let dr = Double.pi / 180
  let M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2
  let L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2

  var DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * sin(dr * M)
  DL += (0.019993 - 0.000101 * T) * sin(dr * 2 * M)
  DL += 0.000290 * sin(dr * 3 * M)

  var L = (L0 + DL) * dr
  L -= 2 * Double.pi * floor(L / (2 * Double.pi))
  return Int(floor(L / Double.pi * 6))
}

func getLunarMonth11(year: Int, timeZone: Int, calendar: Calendar) -> Int {
  let comps = DateComponents(year: year, month: 12, day: 31)
  let date = calendar.date(from: comps) ?? Date()
  let d = calendar.dateComponents([.day, .month, .year], from: date)
  let off = jdFromDate(day: d.day!, month: d.month!, year: d.year!) - 2_415_021
  let k = Int(floor(Double(off) / 29.530588853))
  var nm = getNewMoonDay(k: k, timeZone: timeZone)
  if getSunLongitude(jdn: nm, timeZone: timeZone) >= 9 {
    nm = getNewMoonDay(k: k - 1, timeZone: timeZone)
  }
  return nm
}

func getLeapMonthOffset(a11: Int, timeZone: Int) -> Int {
  let k = Int(floor((Double(a11) - 2415021.076998695) / 29.530588853 + 0.5))
  var last = getSunLongitude(
    jdn: getNewMoonDay(k: k + 1, timeZone: timeZone),
    timeZone: timeZone
  )
  for i in 2...14 {
    let arc = getSunLongitude(
      jdn: getNewMoonDay(k: k + i, timeZone: timeZone),
      timeZone: timeZone
    )
    if arc == last { return i - 1 }
    last = arc
  }
  return 0
}

func calculateLunarDate(
  dayNumber: Int,
  timeZone: Int,
  calendar: Calendar,
  year: Int
) -> (Int, Int, Int) {
  let k = Int(
    floor(
      (Double(dayNumber) - Constants.Julian.dayOffset)
        / Constants.Julian.lunarMonthDays
    )
  )
  var monthStart = getNewMoonDay(k: k + 1, timeZone: timeZone)
  if monthStart > dayNumber {
    monthStart = getNewMoonDay(k: k, timeZone: timeZone)
  }

  var a11 = getLunarMonth11(year: year, timeZone: timeZone, calendar: calendar)
  var b11 = getLunarMonth11(
    year: year + 1,
    timeZone: timeZone,
    calendar: calendar
  )
  var lunarYear = year + 1

  if a11 >= monthStart {
    lunarYear = year
    a11 = getLunarMonth11(
      year: year - 1,
      timeZone: timeZone,
      calendar: calendar
    )
    b11 = getLunarMonth11(year: year, timeZone: timeZone, calendar: calendar)
  }

  let lunarDay = dayNumber - monthStart + 1
  let diff = Int(floor(Double(monthStart - a11) / 29))
  var lunarMonth = diff + 11

  if b11 - a11 > 365 {
    let leapMonth = getLeapMonthOffset(a11: a11, timeZone: timeZone)
    if diff >= leapMonth {
      lunarMonth -= 1
    }
  }

  if lunarMonth > 12 {
    lunarMonth -= 12
  }
  if lunarMonth >= 11 && diff < 4 {
    lunarYear -= 1
  }

  return (lunarYear, lunarMonth, lunarDay)
}

public func getVietnameseLunarDate(_ date: Date, _ timeZone: TimeZone)
  -> LunarDate
{
  let calendar = Calendar(identifier: .gregorian)
  let comps = calendar.dateComponents([.day, .month, .year], from: date)
  let day = comps.day ?? 0
  let month = comps.month ?? 0
  let year = comps.year ?? 0
  let dayNumber = jdFromDate(day: day, month: month, year: year)

  // Chuyển đổi TimeZone sang Int (offset giờ)
  let timeZoneOffset = timeZone.secondsFromGMT(for: date) / 3600

  let (lunarYear, lunarMonth, lunarDay) = calculateLunarDate(
    dayNumber: dayNumber,
    timeZone: timeZoneOffset,
    calendar: calendar,
    year: year
  )
  return LunarDate(day: lunarDay, month: lunarMonth, year: lunarYear)
}
