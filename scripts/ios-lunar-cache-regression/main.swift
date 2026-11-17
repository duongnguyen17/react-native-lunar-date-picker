import Foundation
import UIKit

private let cache = LunarPersistentCache.shared
private let prefix = "codex-cache-regression-\(UUID().uuidString)"

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
  guard condition() else {
    fatalError(message)
  }
}

private func cachedEntryCount() -> Int {
  guard
    let storage = Mirror(reflecting: cache).children.first(where: {
      $0.label == "memoryCache"
    })?.value as? [String: (day: Int, month: Int)]
  else {
    fatalError("Could not inspect the cache's private in-memory dictionary")
  }
  return storage.count
}

private func storageKey(_ key: String) -> String {
  "ldp.lunar.\(key)"
}

cache.clearMemory()

let defaults = UserDefaults.standard
// Direct inserts must keep memory bounded.
let seededKeys = (0...1_000).map { "\(prefix).seed.\($0)" }
for (index, key) in seededKeys.enumerated() {
  cache.set((day: index % 30 + 1, month: index % 12 + 1), for: key)
}
expect(cachedEntryCount() <= 1_000, "set() exceeded the in-memory cache limit")

// Cold reads from persistent storage must enforce the same bound.
let readKeys = (0...1_000).map { "\(prefix).read.\($0)" }
for (index, key) in readKeys.enumerated() {
  let value = "\(index % 30 + 1)|\(index % 12 + 1)"
  defaults.set(value, forKey: storageKey(key))
}
cache.clearMemory()
for key in readKeys {
  expect(cache.get(key) != nil, "Cold read missed a seeded persistent cache entry")
}
expect(cachedEntryCount() <= 1_000, "get() exceeded the in-memory cache limit")

// Concurrent users of the shared cache should retain correct values.
let group = DispatchGroup()
let concurrentQueue = DispatchQueue(label: "cache-regression", attributes: .concurrent)
let concurrentKeys = (0..<8).map { "\(prefix).concurrent.\($0)" }
let failureLock = NSLock()
var failure: String?
for (index, key) in concurrentKeys.enumerated() {
  group.enter()
  concurrentQueue.async {
    let expected = (day: index + 1, month: 12 - index)
    for _ in 0..<100 {
      cache.set(expected, for: key)
      guard let actual = cache.get(key), actual.day == expected.day,
        actual.month == expected.month else {
        failureLock.lock()
        failure = "Concurrent cache read returned the wrong value for \(key)"
        failureLock.unlock()
        break
      }
    }
    group.leave()
  }
}
group.wait()
expect(failure == nil, failure ?? "Concurrent cache access failed")

// Wait until the serial persistence queue has written everything, then clear
// memory and confirm a value is restored from UserDefaults.
let persistedKey = "\(prefix).persisted"
let persistedValue = (day: 29, month: 2)
cache.set(persistedValue, for: persistedKey)
let deadline = Date().addingTimeInterval(5)
var restored = false
while Date() < deadline {
  cache.clearMemory()
  if let value = cache.get(persistedKey), value.day == persistedValue.day,
    value.month == persistedValue.month {
    restored = true
    break
  }
  Thread.sleep(forTimeInterval: 0.01)
}
expect(restored, "A persisted value was not available after clearing memory")

expect(cachedEntryCount() > 0, "Memory warning test needs a populated cache")
NotificationCenter.default.post(
  name: UIApplication.didReceiveMemoryWarningNotification,
  object: nil
)
expect(cachedEntryCount() == 0, "Memory warning did not clear cached values")

for key in seededKeys + readKeys + concurrentKeys + [persistedKey] {
  defaults.removeObject(forKey: storageKey(key))
}
cache.clearMemory()
expect(cachedEntryCount() == 0, "clearMemory() did not release cached values")
print("iOS lunar cache regression checks passed")
