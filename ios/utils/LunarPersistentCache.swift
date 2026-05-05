//
//  LunarPersistentCache.swift
//  LunarDatePicker
//
//  Persistent cache for lunar date calculations using UserDefaults (disk only)
//

import Foundation
import UIKit

final class LunarPersistentCache {
  static let shared = LunarPersistentCache()

  private let prefix = "ldp.lunar."
  private let defaults = UserDefaults.standard
  
  // In-memory cache for fast synchronous reads on main thread
  private var memoryCache: [String: (day: Int, month: Int)] = [:]
  private let lock = NSLock()

  private init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(clearMemory),
      name: UIApplication.didReceiveMemoryWarningNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc public func clearMemory() {
    lock.lock()
    memoryCache.removeAll(keepingCapacity: false)
    lock.unlock()
  }

  func get(_ key: String) -> (day: Int, month: Int)? {
    lock.lock()
    if let cached = memoryCache[key] {
      lock.unlock()
      return cached
    }
    lock.unlock()

    guard let str = defaults.string(forKey: prefix + key) else { return nil }
    let comps = str.split(separator: "|")
    guard comps.count == 2, let d = Int(comps[0]), let m = Int(comps[1]) else { return nil }
    let result = (d, m)
    
    lock.lock()
    memoryCache[key] = result
    // Simple size limit to prevent memory unbounded growth
    if memoryCache.count > 1000 {
      let keysToRemove = memoryCache.keys.prefix(200)
      for k in keysToRemove {
        memoryCache.removeValue(forKey: k)
      }
    }
    lock.unlock()
    
    return result
  }

  func set(_ value: (day: Int, month: Int), for key: String) {
    lock.lock()
    memoryCache[key] = value
    lock.unlock()
    
    let str = "\(value.day)|\(value.month)"
    // Move disk I/O operation to background queue to avoid blocking main thread
    DispatchQueue.global(qos: .background).async {
      self.defaults.set(str, forKey: self.prefix + key)
    }
  }
}
