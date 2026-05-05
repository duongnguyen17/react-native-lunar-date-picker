//
//  LunarDatePickerCoordinator.swift
//  LunarDatePicker
//
//  Coordinator for managing lunar date picker presentation flow
//

import UIKit

/// Coordinator responsible for managing the lunar date picker presentation flow
final class LunarDatePickerCoordinator {

  // MARK: - Properties

  private let configurationBuilder: ConfigurationProviding
  private let presenter: PickerPresenter
  private let dateConverter: DateConverting
  private var globalConfig: LDP_ConfigParams?
  private var currentRangeController: PickerController<PickerRange>?

  // MARK: - Initialization

  init(
    configurationBuilder: ConfigurationProviding = ConfigurationBuilder(),
    dateConverter: DateConverting = DateConverter(),
    presenter: PickerPresenter? = nil
  ) {
    self.configurationBuilder = configurationBuilder
    self.dateConverter = dateConverter
    self.presenter =
      presenter
      ?? PickerPresenter(
        configurationBuilder: configurationBuilder,
        dateConverter: dateConverter
      )
  }
  
  deinit {
    cleanup()
  }

  // MARK: - Public Methods

  /// Configures the global settings for the date picker
  /// - Parameter config: Global configuration parameters
  func configure(with config: LDP_ConfigParams) {
    self.globalConfig = config
  }

  /// Cập nhật giá cho một tháng — delegate xuống PickerController đang hiển thị
  func updatePrices(with params: LDP_PriceUpdateParams) {
    currentRangeController?.updatePrices(params.prices)
  }

  
  
  /// Cleanup method to clear all references and prevent memory leaks
  func cleanup() {
    currentRangeController?.cleanup()
    currentRangeController = nil
  }

  /// Presents the date picker with the specified parameters
  /// - Parameters:
  ///   - params: Presentation parameters
  /// - Throws: An error if the presentation fails
  func present(with params: LDP_PresentParams) throws {
    guard let rootViewController = getTopMostViewController() else {
      throw LunarDatePickerError.noRootViewController
    }

    let controller = presenter.createPickerController(
      from: params,
      globalConfig: globalConfig
    )
    currentRangeController = controller
    configureAndPresent(
      rangeController: controller,
      params: params,
      from: rootViewController
    )
  }

  // MARK: - Private Methods

  private func getTopMostViewController() -> UIViewController? {
    guard
      let windowScene = UIApplication.shared.connectedScenes.first
        as? UIWindowScene,
      let rootViewController = windowScene.windows.first?.rootViewController
    else {
      return nil
    }
    return findTopViewController(from: rootViewController)
  }

  private func findTopViewController(from viewController: UIViewController) -> UIViewController {
    if let presented = viewController.presentedViewController {
      // Đệ quy lên Controller đang được present (như FormSheet)
      return findTopViewController(from: presented)
    }
    if let navigationController = viewController as? UINavigationController {
      if let visible = navigationController.visibleViewController {
        return findTopViewController(from: visible)
      }
    }
    if let tabBarController = viewController as? UITabBarController {
      if let selected = tabBarController.selectedViewController {
        return findTopViewController(from: selected)
      }
    }
    return viewController
  }

  private func configureAndPresent(
    rangeController: PickerController<PickerRange>,
    params: LDP_PresentParams,
    from viewController: UIViewController
  ) {
    // Configure prices
    if let prices = params.prices {
      rangeController.hasPrices = true
      for price in prices {
        rangeController.priceMap[price.date] = price
      }
    }

    // Configure callbacks
    rangeController.onMounted = params.onMounted
    rangeController.onSelectFromDate = params.onSelectFromDate
    rangeController.noticeText = params.notice

    rangeController.doneHandler = { [weak self] selected in
      guard let selected = selected,
        let self = self
      else { return }

      // Get timezone from config, fallback to current timezone
      let timeZone = self.globalConfig.flatMap { config in
        TimeZone(secondsFromGMT: Int(config.timeZoneOffset * 3600))
      }

      let isSingle = rangeController.config.controller.isSingleMode
      let result: LDP_Range
      if isSingle {
        // Single mode: to should be empty in callback
        result = LDP_Range(
          from: self.dateConverter.stringFromDate(selected.fromDate, timeZone: timeZone),
          to: nil
        )
      } else {
        result = self.dateConverter.rangeFromDates(
          from: selected.fromDate,
          to: selected.toDate ?? selected.fromDate,
          timeZone: timeZone
        )
      }
      
      // Call completion BEFORE clearing callbacks
      params.onDone(result)

      self.currentRangeController = nil
    }
    
    rangeController.cancelHandler = { [weak self] in
      self?.cleanup()
    }
    rangeController.present(above: viewController)
  }
}

// MARK: - Error Types

enum LunarDatePickerError: LocalizedError {
  case noRootViewController
  case invalidConfiguration
  case presentationFailed

  var errorDescription: String? {
    switch self {
    case .noRootViewController:
      return "Unable to find root view controller for presentation"
    case .invalidConfiguration:
      return "Invalid configuration parameters provided"
    case .presentationFailed:
      return "Failed to present the date picker"
    }
  }
}
