//
//  MonthHeader.swift
//  Pods
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation
import JTAppleCalendar
import UIKit

final class MonthHeader: JTACMonthReusableView {

  // MARK: - Outlets

  private lazy var monthLabel: UILabel = {
    let label = UILabel()
    label.text = "Month name"
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(
      ofSize: Constants.FontSize.monthHeader,
      weight: .semibold
    )
    label.textAlignment = .left
    return label
  }()

  private var monthNames: [String] = Constants.MonthNames.english

  private var leftAnchorConstraint: NSLayoutConstraint?
  private var rightAnchorConstraint: NSLayoutConstraint?
  private var topAnchorConstraint: NSLayoutConstraint?
  private var bottomAnchorConstraint: NSLayoutConstraint?

  private lazy var monthFormatter = DateFormatter()

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.configureSubviews()
    self.configureConstraints()
    self.applyConfig(PickerConfig.default.monthHeader)
  }

  @available(*, unavailable)
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Configuration

  private func configureSubviews() {
    self.addSubview(self.monthLabel)
  }

  private func configureConstraints() {
    self.leftAnchorConstraint = self.monthLabel.leftAnchor.constraint(
      equalTo: self.leftAnchor
    )
    self.rightAnchorConstraint = self.monthLabel.rightAnchor.constraint(
      equalTo: self.rightAnchor
    )
    self.topAnchorConstraint = self.monthLabel.topAnchor.constraint(
      equalTo: self.topAnchor
    )
    self.bottomAnchorConstraint = self.monthLabel.bottomAnchor.constraint(
      equalTo: self.bottomAnchor
    )
    NSLayoutConstraint.activate(
      [
        self.leftAnchorConstraint, self.rightAnchorConstraint,
        self.topAnchorConstraint, self.bottomAnchorConstraint,
      ].compactMap({ $0 })
    )
  }

  internal func configure(for date: Date, calendar: Calendar = .current) {
    // Use DateFormatter with provided calendar locale/timezone for localization
    self.monthFormatter.locale = calendar.locale
    self.monthFormatter.timeZone = calendar.timeZone
    self.monthFormatter.dateFormat = "LLLL yyyy"
    self.monthLabel.text = self.monthFormatter.string(from: date)
  }

  internal func applyConfig(_ config: PickerConfig.MonthHeader) {
    self.monthLabel.textColor = config.labelColor.toUIColor()
    self.monthNames = config.monthNames

    self.leftAnchorConstraint?.constant =
      Constants.Layout.monthHeaderLeftPadding
    self.rightAnchorConstraint?.constant =
      Constants.Layout.monthHeaderRightPadding
    self.topAnchorConstraint?.constant = Constants.Layout.monthHeaderTopPadding
    self.bottomAnchorConstraint?.constant =
      Constants.Layout.monthHeaderBottomPadding

    self.monthFormatter.dateFormat = "LLLL yyyy"
    self.monthFormatter.locale = .current
  }

}

extension PickerConfig {

  public struct MonthHeader {

    public var monthNames: [String] = Constants.MonthNames.english

    public var labelColor = ColorWrapper.customBlack
  }

}
