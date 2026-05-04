//
//  PickerControllerFactory.swift
//  LunarDatePicker
//
//  Factory for creating picker controller instances
//

import Foundation

/// Factory protocol for creating picker controllers
protocol PickerControllerFactoryProtocol {
  func makeRangePickerController(config: PickerConfig) -> PickerController<PickerRange>
}

/// Default implementation of PickerControllerFactoryProtocol
final class PickerControllerFactory: PickerControllerFactoryProtocol {

  // MARK: - PickerControllerFactoryProtocol

  func makeRangePickerController(config: PickerConfig) -> PickerController<PickerRange> {
    return PickerController<PickerRange>(config: config)
  }
}
