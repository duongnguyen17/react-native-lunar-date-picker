//
//  PickerController.swift
//  LunarDatePicker
//
//  Main picker controller for displaying calendar view
//

import Foundation
import JTAppleCalendar
import UIKit

/// Generic picker controller that handles both single date and date range selection
/// - Parameter Value: The type of value being selected (Date or PickerRange)
final class PickerController<Value: PickerValue>: UIViewController {

  // MARK: - UI Components

  /// Cancel button in navigation bar
  private lazy var cancelBarButtonItem: UIBarButtonItem = {
    let barButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "xmark"),
      style: .plain,
      target: self,
      action: #selector(self.cancel)
    )
    barButtonItem.tintColor = self.config.controller.titleColor.toUIColor()
    return barButtonItem
  }()

  /// Confirm button in navigation bar (right side)
  private lazy var confirmBarButtonItem: UIBarButtonItem = {
    let barButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "checkmark"),
      style: .done,
      target: self,
      action: #selector(self.confirmTapped)
    )
    barButtonItem.tintColor = self.config.controller.submitButtonColor.toUIColor()
    barButtonItem.isEnabled = false
    return barButtonItem
  }()

  /// Title label displayed in navigation bar
  private lazy var titleUI: UIView = {
    let titleLabel = UILabel()
    titleLabel.text = self.config.controller.title
    titleLabel.font = UIFont.systemFont(
      ofSize: Constants.FontSize.title,
      weight: .semibold
    )
    titleLabel.textAlignment = .center
    titleLabel.contentMode = .center
    titleLabel.textColor = self.config.controller.titleColor.toUIColor()

    return titleLabel
  }()

  /// Main calendar view
  private lazy var calendarView: JTACMonthView = {
    let configManager = CalendarConfigurationManager(
      config: self.config,
      minimumDate: self.privateMinimumDate,
      maximumDate: self.privateMaximumDate
    )
    let monthView = configManager.createCalendarView(for: Value.self)
    monthView.ibCalendarDelegate = self
    monthView.ibCalendarDataSource = self
    return monthView
  }()

  /// Week day names header view
  private lazy var weekView: WeekView = {
    let view = WeekView(
      calendar: self.config.calendar,
      config: self.config.weekView
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  // MARK: - Properties

  /// Configuration for the picker
  internal let config: PickerConfig

  /// Reuse identifiers for collection view cells
  internal let dayCellReuseIdentifier = "DayCellReuseIdentifier"
  internal let monthHeaderReuseIdentifier = "MonthHeaderReuseIdentifier"

  /// Cache for lunar date calculations only (not UI state)
  private var lunarDateCache: [String: (day: Int, month: Int)] = [:]

  /// Reusable calendar instance for better performance
  private var calendar: Calendar {
    return self.config.calendar
  }

  /// Date constraints
  internal var privateMinimumDate: Date?
  internal var privateMaximumDate: Date?

  /// Date formatter for day labels
  private var dayFormatter = DateFormatter()

  /// Auto submit flag (derived from config)
  private var isAutoSubmit: Bool { return !self.config.controller.showSubmitButton }

  /// Date formatter for month keys (reusable)
  internal lazy var monthKeyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = self.config.calendar.timeZone
    return formatter
  }()

  /// Cached today date to avoid creating Date() repeatedly
  private lazy var todayDate: Date = {
    return self.config.calendar.startOfDay(for: Date())
  }()

  /// Timer to update today date at midnight
  private var todayUpdateTimer: Timer?

  /// Flag to track if cleanup has been performed
  internal var hasCleanedUp = false

  /// Flag to track if initial scroll to selected date is needed
  private var needsInitialScroll = true

  /// Currently selected value
  private var value: Value?

  /// The block to execute after "Done" button will be tapped
  public var doneHandler: ((Value?) -> Void)?

  /// The block to execute when "Cancel" button will be tapped
  public var cancelHandler: (() -> Void)?


  /// And initial value which will be selected by default
  public var initialValue: Value?

  /// Minimal selection date. Dates less then current will be marked as unavailable
  public var minimumDate: Date? {
    get {
      self.privateMinimumDate
    }
    set {
      self.privateMinimumDate = newValue?.startOfDay()
    }
  }

  /// Maximum selection date. Dates greater then current will be marked as unavailable
  public var maximumDate: Date? {
    get {
      self.privateMaximumDate
    }
    set {
      self.privateMaximumDate = newValue?.endOfDay()
    }
  }

  // MARK: - Lifecycle

  public init(config: PickerConfig = .default) {
    self.config = config
    self.dayFormatter.locale = config.calendar.locale
    self.dayFormatter.dateFormat = "d"
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    self.configureUI()
    self.configureSubviews()
    self.configureConstraints()
    self.configureInitialState()
    self.setupCalendarContentInsets()
    self.setupTodayUpdateTimer()
    // Prewarm lunar cache for upcoming months to reduce first-render cost
    self.prewarmLunarCache(monthsBefore: 0, monthsAfter: 2)
  }

  deinit {
    cleanup()
    cleanupTodayTimer()
  }

  // MARK: - Public Methods

  public func present(
    above viewController: UIViewController,
    animated flag: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    let navVc = UINavigationController(rootViewController: self)
    navVc.modalPresentationStyle = .formSheet
    if !self.config.controller.showSubmitButton {
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      appearance.backgroundColor = .clear
      appearance.shadowColor = .clear
      navVc.navigationBar.standardAppearance = appearance
      navVc.navigationBar.scrollEdgeAppearance = appearance
    }
    if viewController.preferredContentSize != .zero {
      navVc.preferredContentSize = viewController.preferredContentSize
    } else {
      navVc.preferredContentSize = Constants.UI.defaultPickerSize
    }

    viewController.present(navVc, animated: flag, completion: completion)
  }

  /// Cleanup method to cancel all pending month visibility callbacks
  /// Should be called when the controller is being destroyed to prevent memory leaks
  internal func cleanup() {
    // Prevent multiple cleanup calls
    guard !hasCleanedUp else { return }
    hasCleanedUp = true

    // Invalidate timers & observers early
    cleanupTodayTimer()

    // IMPORTANT: Only clear delegates in deinit after view is fully dismissed
    // Clearing them earlier causes JTAppleCalendar assertion failures
    // The library expects delegates to remain valid throughout the view lifecycle
    
    // Break delegate/dataSource links to avoid retain cycles
    self.calendarView.ibCalendarDelegate = nil
    self.calendarView.ibCalendarDataSource = nil


    // Break closure references
    self.doneHandler = nil
    self.cancelHandler = nil

    // Clear caches to prevent memory leaks
    lunarDateCache.removeAll()
  }

  // MARK: - Today Date Management

  /// Setup timer to update today date at midnight
  private func setupTodayUpdateTimer() {
    // Calculate seconds until next midnight
    let calendar = self.config.calendar
    let now = Date()

    guard
      let tomorrow = calendar.date(
        byAdding: .day,
        value: 1,
        to: calendar.startOfDay(for: now)
      )
    else {
      return
    }

    let timeUntilMidnight = tomorrow.timeIntervalSince(now)

    // Setup timer to fire at midnight and then every 24 hours
    todayUpdateTimer = Timer.scheduledTimer(
      withTimeInterval: timeUntilMidnight,
      repeats: false
    ) { [weak self] _ in
      self?.updateTodayDate()
      self?.setupDailyTimer()
    }

    // Add observer for app becoming active (when returning from background)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppBecameActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  /// Setup daily timer that repeats every 24 hours
  private func setupDailyTimer() {
    todayUpdateTimer = Timer.scheduledTimer(
      withTimeInterval: 24 * 60 * 60,
      repeats: true
    ) { [weak self] _ in
      self?.updateTodayDate()
    }
  }

  /// Update today date and refresh visible cells
  private func updateTodayDate() {
    let oldToday = todayDate
    todayDate = self.config.calendar.startOfDay(for: Date())

    // Only refresh if date actually changed
    if !self.config.calendar.isDate(oldToday, inSameDayAs: todayDate) {
      DispatchQueue.main.async { [weak self] in
        // No need to clear lunar date cache - only affects UI styling
        self?.calendarView.reloadData()
      }
    }
  }

  /// Cleanup today timer
  private func cleanupTodayTimer() {
    todayUpdateTimer?.invalidate()
    todayUpdateTimer = nil

    // Remove notification observer
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  /// Simple cache for lunar date calculations only
  private func getCachedLunarDate(for date: Date) -> (day: Int, month: Int)? {
    let key = lunarCacheKey(for: date)
    if let mem = lunarDateCache[key] {
      return mem
    }
    if let persisted = LunarPersistentCache.shared.get(key) {
      lunarDateCache[key] = persisted
      return persisted
    }
    return nil
  }

  private func setCachedLunarDate(
    _ lunarDate: (day: Int, month: Int),
    for date: Date
  ) {
    let key = lunarCacheKey(for: date)
    lunarDateCache[key] = lunarDate
    LunarPersistentCache.shared.set(lunarDate, for: key)

    // Simple size limit - remove oldest entries if cache gets too large
    if lunarDateCache.count > 1000 {
      let sortedKeys = lunarDateCache.keys.sorted()
      let keysToRemove = sortedKeys.prefix(200)  // Remove oldest 200 entries
      for key in keysToRemove {
        lunarDateCache.removeValue(forKey: key)
      }
    }
  }

  private func lunarCacheKey(for date: Date) -> String {
    let start = calendar.startOfDay(for: date)
    let ts = start.timeIntervalSince1970
    let tz = self.config.calendar.timeZone.secondsFromGMT(for: start)
    return String(format: "%.0f.tz.%d", ts, tz)
  }

  // MARK: - Private Methods

  private func configureUI() {
    self.view.backgroundColor = self.config.controller.backgroundColor
      .toUIColor()
    self.navigationItem.largeTitleDisplayMode = .never
    self.navigationItem.titleView = self.titleUI
    self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem
    if self.config.controller.showSubmitButton {
      self.navigationItem.rightBarButtonItem = self.confirmBarButtonItem
    }
  }

  private func configureSubviews() {
    self.calendarView.register(
      DayCell.self,
      forCellWithReuseIdentifier: self.dayCellReuseIdentifier
    )
    self.calendarView.register(
      MonthHeader.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: self.monthHeaderReuseIdentifier
    )

    self.view.addSubview(self.weekView)
    self.view.addSubview(self.calendarView)
  }

  private func configureConstraints() {
    NSLayoutConstraint.activate([
      self.weekView.topAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.topAnchor
      ),
      self.weekView.leftAnchor.constraint(
        equalTo: self.view.leftAnchor,
        constant: Constants.Layout.weekViewSidePadding
      ),
      self.weekView.rightAnchor.constraint(
        equalTo: self.view.rightAnchor,
        constant: -Constants.Layout.weekViewSidePadding
      ),

      self.calendarView.topAnchor.constraint(
        equalTo: self.weekView.bottomAnchor
      ),
      self.calendarView.leftAnchor.constraint(
        equalTo: self.view.leftAnchor,
        constant: Constants.Layout.calendarHorizontalPadding
      ),
      self.calendarView.rightAnchor.constraint(
        equalTo: self.view.rightAnchor,
        constant: -Constants.Layout.calendarHorizontalPadding
      ),
      self.calendarView.bottomAnchor.constraint(
        equalTo: self.view.bottomAnchor
      ),
    ])
  }

  private func setupCalendarContentInsets() {
    let bottomInset: CGFloat = self.config.controller.showSubmitButton ? 20 : self.view.safeAreaInsets.bottom
    self.calendarView.contentInset.bottom = bottomInset
    self.calendarView.verticalScrollIndicatorInsets.bottom = bottomInset
  }

  private func configureInitialState() {
    self.value = self.initialValue
    if let rangeValue = self.value as? PickerRange {
      self.selectRange(rangeValue, in: self.calendarView)
      // In single mode, enable confirm when from is selected even if to is nil
      if self.config.controller.isSingleMode {
        setConfirmButtonEnabled(true)
      } else {
        // Range mode: only enable when toDate exists
        setConfirmButtonEnabled(rangeValue.toDate != nil)
      }
    } else {
      setConfirmButtonEnabled(false)
    }
    // Set flag to perform scroll in viewDidLayoutSubviews when sizes are ready
    self.needsInitialScroll = true
  }

  internal func configureCell(
    _ cell: JTACDayCell,
    forItemAt date: Date,
    cellState: CellState,
    indexPath: IndexPath
  ) {
    guard let cell = cell as? DayCell else { return }

    cell.applyConfig(self.config)

    // Always create fresh config to avoid UI state cache issues
    // Only lunar date calculation is cached separately
    let newConfig = createCellConfig(for: cellState, date: date)
    cell.configure(for: newConfig)
  }

  /// Creates cell configuration with optimized price lookup
  private func createCellConfig(for cellState: CellState, date: Date)
    -> DayCell.ViewConfig
  {
    var config = DayCell.makeViewConfig(
      for: cellState,
      minimumDate: self.privateMinimumDate,
      maximumDate: self.privateMaximumDate,
      rangeValue: self.value as? PickerRange,
      calendar: self.config.calendar
    )

    // Only configure content for dates that belong to current month
    if cellState.dateBelongsTo == .thisMonth {
      // Configure date label
      if config.dateLabelText != nil {
        config.dateLabelText = self.dayFormatter.string(from: date)
      }

      // Check if this is today
      let isToday = self.config.calendar.isDate(date, inSameDayAs: todayDate)

      // Configure date label color and font weight - today gets today color and medium weight
      if isToday {
        config.dateLabelColor = self.config.dayCell.todayLabelColor
        config.dateLabelFontWeight = UIFont.Weight.medium
      } else {
        config.dateLabelColor =
          self.config.calendar.isDateInWeekend(date)
          ? self.config.dayCell.weekendLabelColor
          : self.config.dayCell.dateLabelColor
        config.dateLabelFontWeight = UIFont.Weight.regular
      }

      // Configure lunar date
      configureLunarDate(for: &config, date: date)

    }

    return config
  }

  /// Configures lunar date information for the cell with caching
  private func configureLunarDate(
    for config: inout DayCell.ViewConfig,
    date: Date
  ) {
    // Try to get from cache first
    let lunarDate: (day: Int, month: Int)
    if let cached = getCachedLunarDate(for: date) {
      lunarDate = cached
    } else {
      // Calculate and cache the result
      let calculated = getVietnameseLunarDate(
        date,
        self.config.calendar.timeZone
      )
      lunarDate = (day: calculated.day, month: calculated.month)
      setCachedLunarDate(lunarDate, for: date)
    }

    config.lunarDateLabelText =
      lunarDate.day == 1
      ? "\(lunarDate.day)/\(lunarDate.month)"
      : "\(lunarDate.day)"

    config.lunarDateLabelColor =
      lunarDate.day == 1
      ? self.config.dayCell.specialDateLabelColor
      : self.config.dayCell.lunarDateLabelColor
  }

  // MARK: - Actions

  @objc
  private func cancel() {
    // Notify cancel handler
    self.cancelHandler?()
    // Dismiss - cleanup will be handled automatically by deinit
    self.navigationController?.dismiss(animated: true, completion: nil)
  }

  @objc
  private func done() {
    self.doneHandler?(self.value)
    // Dismiss - cleanup will be handled automatically by deinit
    self.navigationController?.dismiss(animated: true, completion: nil)
  }

  @objc
  private func confirmTapped() {
    self.done()
  }

  private func selectValue(_ value: Value?, in calendar: JTACMonthView) {
    if let range = value as? PickerRange {
      self.selectRange(range, in: calendar)
    }
  }

  // MARK: - Range Selection Logic

  internal func handleDateTap(in calendar: JTACMonthView, date: Date) {
    // Auto-submit short-circuit
    if isAutoSubmit {
      if handleAutoSubmit(date: date, in: calendar) { return }
    }

    // Default behavior when submit button is shown
    if self.config.controller.isSingleMode {
      // Single mode: always set from to selected date, to = nil
      let from = date.startOfDay(in: self.config.calendar)
      let newRange = PickerRange(from: from, to: nil)
      self.value = newRange as? Value
      calendar.deselectAllDates(triggerSelectionDelegate: false)
      DispatchQueue.main.async { [weak self] in
        calendar.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          self?.selectValue(newRange as? Value, in: calendar)
        }
      }
      setConfirmButtonEnabled(true)
      return
    }
    let dateHelper = DateRangeHelper(calendar: self.config.calendar)
    let currentRange = self.value as? PickerRange
    let newRange = dateHelper.calculateNewRange(
      currentRange: currentRange,
      selectedDate: date,
      hasInitialValue: self.initialValue != nil
    )

    // Check if this is a new from date selection
    // This happens when:
    // 1. No current range (first selection)
    // 2. Current range exists but we're starting a new range (different from date)
    let isNewFromDateSelection: Bool = {
      if newRange.shouldComplete { return false }
      if let prevFrom = currentRange?.fromDate {
        return !newRange.range.fromDate.isInSameDay(
          in: self.config.calendar,
          date: prevFrom
        )
      }
      return true
    }()

    if newRange.shouldComplete {
      // Range is complete - update value and enable confirm
      self.value = newRange.range as? Value

      // THÊM DÒNG NÀY: Cập nhật UI để hiển thị range selection
      self.selectValue(newRange.range as? Value, in: calendar)

      setConfirmButtonEnabled(true)
    } else {
      // Range not complete - update UI for continued selection
      if isNewFromDateSelection {
        // Clear all selections first to avoid visual conflicts
        calendar.deselectAllDates(triggerSelectionDelegate: false)
        // No need to clear cache - UI state is not cached
        // Force reload and then update value + selection
        DispatchQueue.main.async { [weak self] in
          calendar.reloadData()
          // Update value after reload to ensure UI sync
          self?.value = newRange.range as? Value
          // Small delay to ensure reload completes before selection
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self?.selectValue(newRange.range as? Value, in: calendar)
          }
        }
      } else {
        // Normal case - update value immediately
        self.value = newRange.range as? Value
        self.selectValue(newRange.range as? Value, in: calendar)
      }
      setConfirmButtonEnabled(false)
    }
  }

  // MARK: - Auto Submit Helpers

  /// Handles auto-submit tap. Returns true if the tap was fully handled (including dismissal)
  private func handleAutoSubmit(date: Date, in calendar: JTACMonthView) -> Bool {
    if self.config.controller.isSingleMode {
      let from = date.startOfDay(in: self.config.calendar)
      let newRange = PickerRange(from: from, to: nil)
      self.value = newRange as? Value
      self.done()
      return true
    }

    guard let current = (self.value as? PickerRange) else {
      // Start new selection
      let from = date.startOfDay(in: self.config.calendar)
      let newRange = PickerRange(from: from, to: nil)
      self.value = newRange as? Value
      calendar.deselectAllDates(triggerSelectionDelegate: false)
      DispatchQueue.main.async { [weak self] in
        calendar.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          self?.selectValue(newRange as? Value, in: calendar)
        }
      }
      return true
    }

    if current.toDate != nil {
      // Start a new range from tapped date
      let from = date.startOfDay(in: self.config.calendar)
      let newRange = PickerRange(from: from, to: nil)
      self.value = newRange as? Value
      calendar.deselectAllDates(triggerSelectionDelegate: false)
      DispatchQueue.main.async { [weak self] in
        calendar.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          self?.selectValue(newRange as? Value, in: calendar)
        }
      }
      return true
    }

    let fromDate = current.fromDate
    if date < fromDate {
      // Reset from and continue
      let newFrom = date.startOfDay(in: self.config.calendar)
      let newRange = PickerRange(from: newFrom, to: nil)
      self.value = newRange as? Value
      calendar.deselectAllDates(triggerSelectionDelegate: false)
      DispatchQueue.main.async { [weak self] in
        calendar.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          self?.selectValue(newRange as? Value, in: calendar)
        }
      }
      return true
    } else {
      // Complete and close
      let completed = PickerRange(
        from: fromDate,
        to: date.endOfDay(in: self.config.calendar)
      )
      self.value = completed as? Value
      self.done()
      return true
    }
  }

  private func selectRange(_ range: PickerRange, in calendar: JTACMonthView) {
    calendar.deselectAllDates(triggerSelectionDelegate: false)
    calendar.selectDates(
      from: range.fromDate,
      to: range.toDate ?? range.fromDate,
      triggerSelectionDelegate: true,
      keepSelectionIfMultiSelectionAllowed: false
    )
    // Ensure layout happens before we compute round corners in cells
    calendar.layoutIfNeeded()
    // Remove reloadItems() call as it overrides the selection state set by selectDates()
    // The triggerSelectionDelegate: true above will properly configure the cells
  }

  // Note: UI state cache removed - only lunar date calculations are cached
  // This eliminates all cache-related UI bugs while maintaining performance for expensive lunar calculations

  @objc
  private func handleAppBecameActive() {
    updateTodayDate()
  }

  private func setConfirmButtonEnabled(_ enabled: Bool) {
    guard self.config.controller.showSubmitButton else { return }
    self.confirmBarButtonItem.isEnabled = enabled
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // Update bottom padding so the last content isn't obscured by the home indicator
    let desiredBottomInset: CGFloat = self.config.controller.showSubmitButton ? 20 : self.view.safeAreaInsets.bottom
    self.calendarView.contentInset.bottom = desiredBottomInset
    self.calendarView.verticalScrollIndicatorInsets.bottom = desiredBottomInset

    if needsInitialScroll {
      needsInitialScroll = false
      // Ensure layout is finished so contentSize is accurate for scrolling to the end
      self.calendarView.layoutIfNeeded()

      if let rangeValue = self.value as? PickerRange {
        let fromDate = rangeValue.fromDate
        self.calendarView.scrollToHeaderForDate(fromDate)
      } else {
        let nowDate = Date()
        let targetDate = self.privateMaximumDate ?? nowDate
        let scrollDate = targetDate < nowDate ? targetDate : nowDate
        self.calendarView.scrollToHeaderForDate(scrollDate)
      }
    }
  }

  // MARK: - Cache Prewarm

  /// Pre-calculate lunar dates for a range of months and persist them to the on-disk cache.
  /// This runs on a background queue and does not modify the in-memory cache to avoid contention.
  private func prewarmLunarCache(monthsBefore: Int, monthsAfter: Int) {
    let calendar = self.config.calendar
    let timeZone = calendar.timeZone
    let now = Date()

    DispatchQueue.global(qos: .utility).async { [weak self] in
      guard let self = self else { return }

      let startOffset = -abs(monthsBefore)
      let endOffset = abs(monthsAfter)

      if startOffset > endOffset { return }

      for offset in startOffset...endOffset {
        guard
          let monthDate = calendar.date(
            byAdding: .month,
            value: offset,
            to: now
          )
        else { continue }
        let startOfMonth = monthDate.startOfMonth(in: calendar)
        let endOfMonth = monthDate.endOfMonth(in: calendar)

        var cursor = startOfMonth
        while cursor <= endOfMonth {
          let key = self.lunarCacheKey(for: cursor)
          if LunarPersistentCache.shared.get(key) == nil {
            let ld = getVietnameseLunarDate(cursor, timeZone)
            LunarPersistentCache.shared.set((ld.day, ld.month), for: key)
          }
          guard let next = calendar.date(byAdding: .day, value: 1, to: cursor)
          else { break }
          cursor = next
        }
      }
    }
  }
}

// MARK: - Configuration Extension

extension PickerConfig {
  public struct PickerController {
    public var title = ""
    public var titleColor = ColorWrapper.customBlack
    public var backgroundColor = ColorWrapper.customWhite
    public var secondaryTextColor: ColorWrapper = ColorWrapper.customBlack
    public var isSingleMode: Bool = false
    public var showSubmitButton: Bool = true
    public var submitButtonColor = ColorWrapper.customBlack
  }
}

// MARK: - Helper Classes

/// Helper class to manage date range selection logic
private struct DateRangeHelper {
  let calendar: Calendar

  struct RangeResult {
    let range: PickerRange
    let shouldComplete: Bool
  }

  func calculateNewRange(
    currentRange: PickerRange?,
    selectedDate: Date,
    hasInitialValue: Bool
  ) -> RangeResult {

    guard let currentValue = currentRange else {
      return RangeResult(
        range: .from(
          selectedDate.startOfDay(in: calendar),
          to: nil
        ),
        shouldComplete: false
      )
    }

    // Range is complete if toDate is not nil
    let rangeSelected = currentValue.toDate != nil

    // Handle initial value case
    if !rangeSelected && hasInitialValue {
      return handleInitialValueCase(
        currentValue: currentValue,
        selectedDate: selectedDate
      )
    }

    // Handle range already selected case (including completed same-day range)
    if rangeSelected {
      // Begin a new selection from the newly selected date (incomplete)
      return RangeResult(
        range: .from(
          selectedDate.startOfDay(in: calendar),
          to: nil
        ),
        shouldComplete: false
      )
    }

    // Simple rule: if selectedDate < from -> swap (new from = selected, to = old from)
    if selectedDate < currentValue.fromDate {
      return RangeResult(
        range: .from(
          selectedDate.startOfDay(in: calendar),
          to: currentValue.fromDate.endOfDay(in: calendar)
        ),
        shouldComplete: true
      )
    }

    // Otherwise set toDate to selected (complete), even if same-day
    return RangeResult(
      range: .from(
        currentValue.fromDate,
        to: selectedDate.endOfDay(in: calendar)
      ),
      shouldComplete: true
    )
  }

  private func handleInitialValueCase(
    currentValue: PickerRange,
    selectedDate: Date
  ) -> RangeResult {
    if selectedDate < currentValue.fromDate {
      return RangeResult(
        range: .from(
          selectedDate.startOfDay(in: calendar),
          to: nil
        ),
        shouldComplete: false
      )
    } else {
      return RangeResult(
        range: .from(
          currentValue.fromDate,
          to: selectedDate.endOfDay(in: calendar)
        ),
        shouldComplete: true
      )
    }
  }


}
