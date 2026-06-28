//
//  DayCell.swift
//  Pods
//
//  Created by Nguyen Van Duong on 7/4/25.
//

import Foundation
import JTAppleCalendar
import UIKit

final class DayCell: JTACDayCell {

  // MARK: - UI Components

  lazy var dateContainerView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  lazy var dateLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(
      ofSize: Constants.FontSize.dateLabel,
      weight: .regular
    )
    return label
  }()

  lazy var lunarDateLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(
      ofSize: Constants.FontSize.lunarDateLabel,
      weight: .regular
    )
    return label
  }()

  lazy var priceLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(
      ofSize: Constants.FontSize.priceLabel,
      weight: .regular
    )
    label.isHidden = true
    return label
  }()


  lazy var selectionBackgroundView: UIView = {
    let view = UIView()
    view.isHidden = true
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.masksToBounds = true
    view.layer.cornerCurve = .continuous
    return view
  }()

  lazy var leftRangeView: UIView = {
    let view = UIView()
    view.layer.masksToBounds = true
    view.layer.cornerCurve = .continuous
    view.layer.cornerRadius = Constants.UI.rangeViewCornerRadius
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  lazy var rightRangeView: UIView = {
    let view = UIView()
    view.layer.masksToBounds = true
    view.layer.cornerCurve = .continuous
    view.layer.cornerRadius = Constants.UI.rangeViewCornerRadius
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  // MARK: - Properties

  private var config: PickerConfig = PickerConfig.default
  

  // MARK: - Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
    setupConstraints()
    applyConfig(.default)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateSelectionBackgroundCornerRadius()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    resetCell()
  }

  // MARK: - Public Methods

  public func applyConfig(_ config: PickerConfig) {
    self.config = config
    updateViewsWithConfig()
  }

  public func configure(for config: ViewConfig) {
    configureVisibility(config)
    configureContent(config)
    configureRangeViews(config)
    
    // Ensure corner radius is updated for visible selection
    if !config.isSelectedViewHidden {
      setNeedsLayout()
    }
  }

  // MARK: - Private Methods

  private func setupViews() {
    // Add base views
    contentView.addSubview(leftRangeView)
    contentView.addSubview(rightRangeView)
    contentView.addSubview(dateContainerView)
    
    // Add date container content
    dateContainerView.addSubview(selectionBackgroundView)
    dateContainerView.addSubview(dateLabel)
    dateContainerView.addSubview(lunarDateLabel)
    dateContainerView.addSubview(priceLabel)
    
  }

  private func setupConstraints() {
    setupDateContainerConstraints()
    setupRangeViewConstraints()
    setupSelectionBackgroundConstraints()
  }

  private func setupDateContainerConstraints() {
    NSLayoutConstraint.activate([
      dateContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      dateContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      dateContainerView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
      
      dateLabel.centerXAnchor.constraint(equalTo: dateContainerView.centerXAnchor),
      dateLabel.topAnchor.constraint(equalTo: dateContainerView.topAnchor),
      
      lunarDateLabel.centerXAnchor.constraint(equalTo: dateContainerView.centerXAnchor),
      lunarDateLabel.topAnchor.constraint(
        equalTo: dateLabel.bottomAnchor,
        constant: Constants.Layout.lunarDateLabelTopSpacing
      ),

      priceLabel.centerXAnchor.constraint(equalTo: dateContainerView.centerXAnchor),
      priceLabel.topAnchor.constraint(
        equalTo: lunarDateLabel.bottomAnchor,
        constant: Constants.Layout.priceLabelTopSpacing
      ),
      priceLabel.bottomAnchor.constraint(equalTo: dateContainerView.bottomAnchor)
    ])
  }

  private func setupRangeViewConstraints() {
    NSLayoutConstraint.activate([
      leftRangeView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      leftRangeView.rightAnchor.constraint(equalTo: contentView.centerXAnchor),
      leftRangeView.topAnchor.constraint(equalTo: dateContainerView.topAnchor, constant: -1),
      leftRangeView.bottomAnchor.constraint(equalTo: dateContainerView.bottomAnchor, constant: 2),
      
      rightRangeView.leftAnchor.constraint(equalTo: contentView.centerXAnchor),
      rightRangeView.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: Constants.Layout.cellPadding
      ),
      rightRangeView.topAnchor.constraint(equalTo: dateContainerView.topAnchor, constant: -1),
      rightRangeView.bottomAnchor.constraint(equalTo: dateContainerView.bottomAnchor, constant: 2)
    ])
  }

  private func setupSelectionBackgroundConstraints() {
    NSLayoutConstraint.activate([
      selectionBackgroundView.centerXAnchor.constraint(equalTo: dateContainerView.centerXAnchor),
      selectionBackgroundView.centerYAnchor.constraint(equalTo: dateContainerView.centerYAnchor),
      selectionBackgroundView.widthAnchor.constraint(equalToConstant: Scale.value(42)),
      selectionBackgroundView.heightAnchor.constraint(equalToConstant: Scale.value(42))
    ])
  }

  

  private func updateViewsWithConfig() {
    let backgroundColor = config.dayCell.rangeBackgroundColor.toUIColor()
    
    leftRangeView.backgroundColor = backgroundColor
    rightRangeView.backgroundColor = backgroundColor
    
    selectionBackgroundView.backgroundColor = config.dayCell.selectedBackgroundColor.toUIColor()
    dateLabel.textColor = config.dayCell.dateLabelColor.toUIColor()
    lunarDateLabel.textColor = config.dayCell.lunarDateLabelColor.toUIColor()
    
    let priceFontSize = config.dayCell.showLunarDate ? Constants.FontSize.priceLabel : Scale.value(9)
    priceLabel.font = UIFont.systemFont(ofSize: priceFontSize, weight: .regular)
  }

  private func updateSelectionBackgroundCornerRadius() {
    selectionBackgroundView.layer.cornerRadius = Scale.value(12)
  }

  private func resetCell() {
    dateLabel.isHidden = false
    lunarDateLabel.isHidden = false
    priceLabel.isHidden = true
    priceLabel.text = nil
    
    selectionBackgroundView.isHidden = true
    leftRangeView.isHidden = true
    rightRangeView.isHidden = true
    
    isUserInteractionEnabled = true
    clipsToBounds = false
    
    // Reset alpha values
    dateLabel.alpha = 1.0
    lunarDateLabel.alpha = 1.0
    priceLabel.alpha = 1.0
  }

  private func configureVisibility(_ config: ViewConfig) {
    let hasDateContent = config.dateLabelText != nil
    
    dateLabel.isHidden = !hasDateContent
    let isLunarEmpty = config.lunarDateLabelText?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
    lunarDateLabel.isHidden = !hasDateContent || isLunarEmpty
    
    let wasHidden = selectionBackgroundView.isHidden
    selectionBackgroundView.isHidden = config.isSelectedViewHidden
    
    // Force update corner radius when selection becomes visible
    if wasHidden && !config.isSelectedViewHidden {
      setNeedsLayout()
      layoutIfNeeded()
      updateSelectionBackgroundCornerRadius()
    }
    
    isUserInteractionEnabled = hasDateContent && config.isDateEnabled && config.lunarDateLabelText != nil
    clipsToBounds = !hasDateContent || config.lunarDateLabelText == nil
  }

  private func configureContent(_ config: ViewConfig) {
    // Configure date labels
    if let dateLabelText = config.dateLabelText {
      dateLabel.text = dateLabelText
      dateLabel.textColor = config.dateLabelColor.toUIColor()
      dateLabel.font = UIFont.systemFont(ofSize: Constants.FontSize.dateLabel, weight: config.dateLabelFontWeight)
      
      lunarDateLabel.text = config.lunarDateLabelText
      lunarDateLabel.textColor = config.lunarDateLabelColor.toUIColor()
      
      // Configure enabled/disabled state
      let alpha: CGFloat = config.isDateEnabled ? 1.0 : 0.4
      dateLabel.alpha = alpha
      lunarDateLabel.alpha = alpha
      priceLabel.alpha = alpha
      
      // Override colors for selected state
      if !config.isSelectedViewHidden {
        let selectedColor = self.config.dayCell.selectedTextColor.toUIColor()
        dateLabel.textColor = selectedColor
        lunarDateLabel.textColor = selectedColor
      }
    }

    // Configure price label
    if let priceText = config.priceText {
      priceLabel.isHidden = false
      priceLabel.text = priceText
      priceLabel.textColor = config.isCheapest
        ? self.config.dayCell.cheapestPriceLabelColor.toUIColor()
        : self.config.dayCell.priceLabelColor.toUIColor()
      // Override for selected state
      if !config.isSelectedViewHidden {
        priceLabel.textColor = self.config.dayCell.selectedTextColor.toUIColor()
      }
    } else if config.showPriceArea {
      // prices truyền vào nhưng ngày này không có data -> hiển thị khoảng trắng để giữ height
      priceLabel.isHidden = false
      priceLabel.text = " "
    } else {
      priceLabel.isHidden = true
    }
  }

  private func configureRangeViews(_ config: ViewConfig) {
    configureRangeView(rightRangeView, for: config.rangeView.rightSideState)
    configureRangeView(leftRangeView, for: config.rangeView.leftSideState)
  }

  private func configureRangeView(_ view: UIView, for state: RangeSideState) {
    switch state {
    case .squared:
      view.isHidden = false
      view.layer.maskedCorners = []
    case .rounded:
      view.isHidden = false
      view.layer.maskedCorners = view == rightRangeView
        ? [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        : [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    case .hidden:
      view.isHidden = true
    }
  }
}

// MARK: - Static Factory Methods

extension DayCell {
  public static func makeViewConfig(
    for state: CellState,
    minimumDate: Date?,
    maximumDate: Date?,
    rangeValue: PickerRange?,
    calendar: Calendar,
    dateLabelColor: ColorWrapper = ColorWrapper.label,
    lunarDateLabelColor: ColorWrapper = ColorWrapper.label
  ) -> ViewConfig {

    var config = ViewConfig()
    config.dateLabelColor = dateLabelColor
    config.lunarDateLabelColor = lunarDateLabelColor

    // Handle out-of-month dates
    if state.dateBelongsTo != .thisMonth {
      config.isSelectedViewHidden = true
      
      // Don't show range views for out-of-month dates (empty dates)
      // This fixes the rendering issue when initial value has empty dates in between
      config.rangeView = RangeViewConfig() // Default hidden state
      
      return config
    }

    config.dateLabelText = state.text

    // Check date constraints
    if let minimumDate = minimumDate, state.date < minimumDate.startOfDay() {
      config.isDateEnabled = false
      return config
    }
    
    if let maximumDate = maximumDate, state.date > maximumDate.endOfDay() {
      config.isDateEnabled = false
      return config
    }

    // Configure selection state
    if state.isSelected {
      // Use custom logic to determine position instead of JTAppleCalendar's selectedPosition()
      let position = determineRangePosition(
        date: state.date,
        rangeValue: rangeValue,
        calendar: calendar
      )
      
      // SIMPLIFIED LOGIC FOR RANGE PICKER ONLY:
      // - From date: show selectionBackgroundView + leftRangeView
      // - To date: show selectionBackgroundView + rightRangeView  
      // - In range: show leftRangeView + rightRangeView (no circle)
      
      config.isSelectedViewHidden = (position == .middle)
      
      // Configure range views with simplified logic
      config.rangeView = calculateSimplifiedRangeConfig(for: position)
    }

    return config
  }



  /// Custom logic to determine range position instead of relying on JTAppleCalendar
  private static func determineRangePosition(
    date: Date,
    rangeValue: PickerRange?,
    calendar: Calendar
  ) -> SelectionRangePosition {
    guard let range = rangeValue else { return .full }
    
    let dateOnly = date.startOfDay(in: calendar)
    let fromDate = range.fromDate.startOfDay(in: calendar)
    let toDateStart = (range.toDate ?? range.fromDate).startOfDay(in: calendar)
    
    // Same day selection - when from date equals to date
    // This happens in two cases:
    // 1. User just selected from date (incomplete selection) → show rightRangeView
    // 2. User completed selection on same day as from date → show only circle
    if fromDate == toDateStart {
      // Same calendar day selection
      if dateOnly == fromDate {
        // Distinguish: if range incomplete (from == to and equal by exact time), treat as single-day selecting
        // Completed same-day range should still show only circle (no range extension)
        return range.toDate == nil ? .full : .full
      }
      return .full
    }
    
    // Check if current date is one of the endpoints BEFORE normalization
    if dateOnly == fromDate {
      return .left  // Always treat fromDate as left (start)
    } else if dateOnly == toDateStart {
      return .right // Always treat toDate as right (end)
    }
    
    // Normalize range to ensure startDate <= endDate
    let startDate = min(fromDate, toDateStart)
    let endDate = max(fromDate, toDateStart)
    
    if dateOnly > startDate && dateOnly < endDate {
      return .middle // Date is within the normalized range
    } else {
      // Date is outside the range but selected (shouldn't happen in normal flow)
      return .full
    }
  }
  
  private static func calculateSimplifiedRangeConfig(
    for position: SelectionRangePosition
  ) -> RangeViewConfig {
    var config = RangeViewConfig()
    
    switch position {
    case .left:
      // From date in a completed range: extend to the right
      config.rightSideState = .squared
    case .right:
      // To date: show circle + leftRangeView (background extends to the left)
      config.leftSideState = .squared
    case .middle:
      // In range: show both leftRangeView and rightRangeView (background both sides)
      config.leftSideState = .squared
      config.rightSideState = .squared
    default:
      // .full - single selection, no range background needed
      break
    }
    
    return config
  }
}

// MARK: - Supporting Types

// Note: CellState.selectedPosition() extension removed as it's no longer needed
// after simplifying the range selection logic.

extension DayCell {
  enum RangeSideState {
    case squared
    case rounded
    case hidden
  }

  struct RangeViewConfig: Hashable {
    var leftSideState: RangeSideState = .hidden
    var rightSideState: RangeSideState = .hidden

    var isHidden: Bool {
      self.leftSideState == .hidden && self.rightSideState == .hidden
    }
  }

  struct ViewConfig {
    var dateLabelText: String?
    var lunarDateLabelText: String?
    var isSelectedViewHidden = true
    var isDateEnabled = true
    var rangeView = RangeViewConfig()
    var dateLabelColor: ColorWrapper = ColorWrapper.label
    var lunarDateLabelColor: ColorWrapper = ColorWrapper.label
    var dateLabelFontWeight: UIFont.Weight = .regular
    /// Giá hiển thị dạng "1.000K", nil = không có data
    var priceText: String?
    /// true = ngày giá rẻ nhất
    var isCheapest: Bool = false
    /// true = prices được truyền vào (kể cả array rỗng) → cần dành chỗ cho price area
    var showPriceArea: Bool = false
  }
}

// MARK: - Configuration Extension

extension PickerConfig {
  public struct DayCell {
    public var dateLabelColor: ColorWrapper = ColorWrapper.customBlack
    public var todayLabelColor: ColorWrapper = ColorWrapper.systemBlue
    public var weekendLabelColor: ColorWrapper = ColorWrapper.customBlack
    public var lunarDateLabelColor: ColorWrapper = ColorWrapper.darkLunarDateColor
    public var showLunarDate: Bool = true
    public var specialDateLabelColor: ColorWrapper = ColorWrapper.darkLunarDateColor
    public var priceLabelColor: ColorWrapper = ColorWrapper.darkLunarDateColor
    public var cheapestPriceLabelColor: ColorWrapper = ColorWrapper.systemBlue
    public var rangeBackgroundColor: ColorWrapper = ColorWrapper.customBlack
    public var selectedBackgroundColor: ColorWrapper = ColorWrapper.systemBlue
    public var selectedTextColor: ColorWrapper = ColorWrapper.customWhite
  }
}
