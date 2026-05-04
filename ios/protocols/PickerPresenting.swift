//
//  PickerPresenting.swift
//  LunarDatePicker
//
//  Protocol for presenting picker controllers (kept for project references)
//

import UIKit

protocol PickerPresenting {
  func presentPicker(
    params: LDP_PresentParams,
    from viewController: UIViewController
  ) throws
}

