import Foundation

/// Finds the dates whose displayed price or cheapest-price styling changed.
enum PriceUpdateDiff {
  static func changedKeys(
    from old: [String: LDP_PriceData],
    to new: [String: LDP_PriceData]
  ) -> Set<String> {
    let keys = Set(old.keys).union(new.keys)
    return Set(keys.filter { key in
      guard let previous = old[key], let current = new[key] else { return true }
      return previous.price != current.price
        || (previous.isCheapest ?? false) != (current.isCheapest ?? false)
    })
  }
}
