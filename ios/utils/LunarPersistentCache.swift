//
//  LunarPersistentCache.swift
//  LunarDatePicker
//
//  Persistent cache for lunar date calculations using UserDefaults (disk only)
//

import Foundation
 

final class LunarPersistentCache {
  static let shared = LunarPersistentCache()
  private init() {}

  private let prefix = "ldp.lunar."
  private let defaults = UserDefaults.standard

  func get(_ key: String) -> (day: Int, month: Int)? {
    guard let str = defaults.string(forKey: prefix + key) else { return nil }
    let comps = str.split(separator: "|")
    guard comps.count == 2, let d = Int(comps[0]), let m = Int(comps[1]) else { return nil }
    return (d, m)
  }

  func set(_ value: (day: Int, month: Int), for key: String) {
    let str = "\(value.day)|\(value.month)"
    // Move disk I/O operation to background queue to avoid blocking main thread
    DispatchQueue.global(qos: .background).async {
      self.defaults.set(str, forKey: self.prefix + key)
    }
  }
}

