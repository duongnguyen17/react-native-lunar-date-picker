//
//  WeekView.swift
//  Pods
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation
import UIKit

final class WeekView: UIView {

  public lazy var stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.backgroundColor = self.config.backgroundColor.toUIColor()
    stackView.spacing = 0
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.alignment = .center
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
  }()

  private let config: PickerConfig.WeekView
  private let calendar: Calendar
  
  // Cached weekend indices for better performance
  private lazy var weekendIndices: Set<Int> = {
    let weekendCount = 2 // Last 2 days are typically weekend (SAT, SUN)
    let totalDays = config.weekdayNames.count
    return Set((totalDays - weekendCount)..<totalDays)
  }()

  init(calendar: Calendar, config: PickerConfig.WeekView) {
    self.config = config
    self.calendar = calendar
    super.init(frame: .zero)
    self.configureUI()
    self.configureSubviews()
    self.configureConstraints()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func configureUI() {
    self.translatesAutoresizingMaskIntoConstraints = false
    self.backgroundColor = self.config.backgroundColor.toUIColor()
    self.layer.cornerRadius = Constants.Layout.defaultCornerRadius
  }

  private func configureSubviews() {
    for (index, weekdaySymbol) in self.config.weekdayNames.enumerated() {
      self.stackView.addArrangedSubview(
        self.makeWeekLabel(for: weekdaySymbol, isWeekend: weekendIndices.contains(index))
      )
    }

    self.addSubview(self.stackView)
  }

  func makeWeekLabel(for symbol: String, isWeekend: Bool) -> UILabel {
    let label = UILabel()
    label.text = symbol.uppercased()
    label.font = .systemFont(
      ofSize: Constants.FontSize.weekLabel,
      weight: .medium
    )
    label.textAlignment = .center

    label.textColor =
      (isWeekend ? self.config.weekendLabelColor : self.config.weekLabelColor)
      .toUIColor()

    return label
  }

  private func configureConstraints() {
    NSLayoutConstraint.activate([
      self.stackView.leftAnchor.constraint(
        equalTo: self.leftAnchor,
        constant: Constants.Layout.weekViewHorizontalPadding
      ),
      self.stackView.rightAnchor.constraint(
        equalTo: self.rightAnchor,
        constant: -Constants.Layout.weekViewHorizontalPadding
      ),
      self.stackView.topAnchor.constraint(equalTo: self.topAnchor),
      self.stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
    ])
    NSLayoutConstraint.activate([
      self.heightAnchor.constraint(equalToConstant: Constants.UI.weekViewHeight)
    ])
  }



}

extension PickerConfig {

  public struct WeekView {

    public var weekdayNames: [String] = Constants.WeekdayNames.english

    public var backgroundColor = ColorWrapper.customWhite

    public var weekLabelColor = ColorWrapper.customBlack

    public var weekendLabelColor = ColorWrapper.customBlack
  }
}
