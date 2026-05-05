//
//  PickerPresenter.swift
//  LunarDatePicker
//
//  Service for presenting picker controllers
//

import UIKit

final class PickerPresenter {

  // MARK: - Properties

  private let configurationBuilder: ConfigurationProviding
  private let dateConverter: DateConverting
  private let controllerFactory: PickerControllerFactoryProtocol

  // MARK: - Initialization

  init(
    configurationBuilder: ConfigurationProviding = ConfigurationBuilder(),
    dateConverter: DateConverting = DateConverter(),
    controllerFactory: PickerControllerFactoryProtocol =
      PickerControllerFactory()
  ) {
    self.configurationBuilder = configurationBuilder
    self.dateConverter = dateConverter
    self.controllerFactory = controllerFactory
  }

  // Intentionally no direct present method; Coordinator drives presentation

  // MARK: - Internal Methods

  func createPickerController(
    from params: LDP_PresentParams,
    globalConfig: LDP_ConfigParams?
  ) -> PickerController<PickerRange> {
    let pickerConfig = configurationBuilder.buildPickerConfig(
      from: params,
      globalConfig: globalConfig
    )

    let controller = controllerFactory.makeRangePickerController(
      config: pickerConfig
    )
    configureCommonDateProperties(controller, params: params, globalConfig: globalConfig)
    configureInitialRangeValue(controller, params: params, globalConfig: globalConfig)
    return controller
  }

  // MARK: - Private Methods

  private func configureCommonDateProperties<T: PickerValue>(
    _ controller: PickerController<T>,
    params: LDP_PresentParams,
    globalConfig: LDP_ConfigParams?
  ) {
    // Get timezone from config, fallback to current timezone
    let timeZone = globalConfig.flatMap { config in
      TimeZone(secondsFromGMT: Int(config.timeZoneOffset * 3600))
    }
    
    if let maximumDate = params.maximumDate {
      controller.maximumDate = dateConverter.dateFromString(maximumDate, timeZone: timeZone)
    }

    if let minimumDate = params.minimumDate {
      controller.minimumDate = dateConverter.dateFromString(minimumDate, timeZone: timeZone)
    }
  }

  private func configureInitialRangeValue(
    _ controller: PickerController<PickerRange>,
    params: LDP_PresentParams,
    globalConfig: LDP_ConfigParams?
  ) {
    guard let initialValue = params.initialValue else { return }

    // Get timezone from config, fallback to current timezone
    let timeZone = globalConfig.flatMap { config in
      TimeZone(secondsFromGMT: Int(config.timeZoneOffset * 3600))
    }

    guard let fromDate = dateConverter.dateFromString(initialValue.from, timeZone: timeZone) else { return }

    let isSingle = (params.mode == .single)
    if isSingle {
      // Single mode: set only from, leave to nil
      controller.initialValue = PickerRange(from: fromDate, to: nil)
    } else if let toDateString = initialValue.to,
              let toDate = dateConverter.dateFromString(toDateString, timeZone: timeZone) {
      // Full range with both from and to
      controller.initialValue = PickerRange(from: fromDate, to: toDate)
    } else {
      // Only from date provided, keep range incomplete (to = nil)
      controller.initialValue = PickerRange(from: fromDate, to: nil)
    }
  }
 

  // No-op: doneHandler is configured by Coordinator
  
}

// MARK: - Supporting Types

extension PickerPresenter {}
