//
//  Constants.swift
//  LunarDatePicker
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation
import UIKit

enum Constants {

  // MARK: - UI Dimensions
  enum UI {
    static let cellSizeWithoutPrice: CGFloat = Scale.value(44)
    static let rangeViewCornerRadius: CGFloat = 6
    static let weekViewHeight: CGFloat = Scale.value(28)
    static let defaultPickerSize = CGSize(width: 445, height: 550)
    static let minimumLineSpacing: CGFloat = Scale.value(8)
    static let minimumInteritemSpacing: CGFloat = 0
    static let closeIconSize: CGFloat = Scale.value(20)
  }

  // MARK: - Font Sizes
  enum FontSize {
    static let dateLabel: CGFloat = Scale.value(16)
    static let lunarDateLabel: CGFloat = Scale.value(8)
    static let monthHeader: CGFloat = Scale.value(17)
    static let weekLabel: CGFloat = Scale.value(12)
    static let title: CGFloat = Scale.value(17)
    // Inline originals scaled
    static let headerLabelSmall: CGFloat = Scale.value(11)
    static let headerLabelMedium: CGFloat = Scale.value(12)
    static let confirmButtonTitle: CGFloat = Scale.value(14)
  }

  // MARK: - Layout Constants
  enum Layout {
    static let defaultCornerRadius: CGFloat = 4
    static let weekViewHorizontalPadding: CGFloat = Scale.value(2)
    static let calendarHorizontalPadding: CGFloat = Scale.value(6)
    static let weekViewSidePadding: CGFloat = Scale.value(4)
    /// Khoảng cách từ lunarDate tới date
    static let lunarDateLabelTopSpacing: CGFloat = Scale.value(2)
    static let monthHeaderLeftPadding: CGFloat = Scale.value(8)
    static let monthHeaderRightPadding: CGFloat = Scale.value(-16)
    static let monthHeaderTopPadding: CGFloat = Scale.value(20)
    static let monthHeaderBottomPadding: CGFloat = Scale.value(-14)
    static let cellPadding: CGFloat = Scale.value(1)
    static let monthHeaderHeight: CGFloat = Scale.value(58)
    // Inline originals scaled
    static let confirmButtonVerticalPadding: CGFloat = Scale.value(13)
    // Top header paddings/divider
    static let topHeaderVerticalPadding: CGFloat = Scale.value(8)
    static let topHeaderDividerThickness: CGFloat = Scale.value(1)
    // Confirm button margins (constraints) inline originals
    static let confirmButtonHorizontalMargin: CGFloat = Scale.value(12)
    static let confirmButtonTopMargin: CGFloat = Scale.value(12)
    static let confirmButtonBottomMargin: CGFloat = Scale.value(4)
  }

  // MARK: - Calendar Configuration
  enum Calendar {
    static let numberOfRows = 6
    static let yearRangeOffset = 10
  }

  // MARK: - Weekday Names
  enum WeekdayNames {
    static let english = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
  }

  // MARK: - Month Names
  enum MonthNames {
    static let english = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ]
  }

  // MARK: - Performance Configuration
  enum Performance {
    static let maxCacheSize = 500
  }

  // MARK: - Date Range Configuration
  enum Julian {
    static let dayOffset = 2415021.076998695
    static let lunarMonthDays = 29.530588853
    static let dayThreshold = 2_299_161
    static let dayConstant = 32045
    static let dayConstantOld = 32083
  }
}
