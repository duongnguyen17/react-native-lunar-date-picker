import Foundation

struct LDP_PriceData {
  let date: String
  let price: Double
  let isCheapest: Bool?
}

func price(_ date: String, _ amount: Double, _ cheapest: Bool? = nil) -> LDP_PriceData {
  LDP_PriceData(date: date, price: amount, isCheapest: cheapest)
}

let previous = [
  "01/11/2026": price("01/11/2026", 100),
  "02/11/2026": price("02/11/2026", 200, true),
  "03/11/2026": price("03/11/2026", 300),
]
let updated = [
  "01/11/2026": price("01/11/2026", 100, false),
  "02/11/2026": price("02/11/2026", 200, false),
  "04/11/2026": price("04/11/2026", 400),
]
precondition(PriceUpdateDiff.changedKeys(from: previous, to: updated) == [
  "02/11/2026", "03/11/2026", "04/11/2026",
])
precondition(PriceUpdateDiff.changedKeys(from: updated, to: updated).isEmpty)
precondition(PriceUpdateDiff.changedKeys(from: updated, to: [:]) == Set(updated.keys))
let changedAmount = ["01/11/2026": price("01/11/2026", 101)]
let originalAmount = ["01/11/2026": price("01/11/2026", 100)]
precondition(PriceUpdateDiff.changedKeys(from: originalAmount, to: changedAmount) == ["01/11/2026"])
print("PASS: price additions, changes, removals and unchanged snapshots")
