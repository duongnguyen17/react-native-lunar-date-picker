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
final class PickerController<Value: PickerValue>: UIViewController, UIAdaptivePresentationControllerDelegate {

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

  /// Notice Banner (Optional)
  private lazy var noticeContainer: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = self.config.controller.noticeBackgroundColor.toUIColor()
    return view
  }()

  private lazy var noticeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = self.config.controller.noticeLabelColor.toUIColor()
    label.font = UIFont.systemFont(ofSize: Scale.value(12))
    label.numberOfLines = 0
    return label
  }()

  // MARK: - Properties

  /// Configuration for the picker
  internal let config: PickerConfig

  /// Reuse identifiers for collection view cells
  internal let dayCellReuseIdentifier = "DayCellReuseIdentifier"
  internal let monthHeaderReuseIdentifier = "MonthHeaderReuseIdentifier"

  /// Reusable calendar instance for better performance
  private var calendar: Calendar {
    return self.config.calendar
  }

  /// Date constraints
  internal var privateMinimumDate: Date?
  internal var privateMaximumDate: Date?

  /// Date formatter for day labels
  private var dayFormatter = DateFormatter()

  /// Reused for every visible price label; creating one per cell bind is costly.
  private lazy var priceFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = "."
    formatter.usesGroupingSeparator = true
    return formatter
  }()

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
  
  /// Track previous bounds size to invalidate layout on FormSheet resize
  private var previousBoundsSize: CGSize = .zero
  private var hasConfiguredCalendarLayout = false
  private var isCalendarReloadInProgress = false
  private var hasPendingCalendarReload = false
  private var pendingCalendarScrollDate: Date?
  private var activeCalendarScrollDate: Date?
  private var initialCalendarScrollRequested = false
  private var isHandlingSizeTransition = false

  /// Currently selected value
  private var value: Value?

  /// Price data: key = "DD/MM/YYYY"
  internal var priceMap: [String: LDP_PriceData] = [:]

  /// Whether prices were passed in (even if empty) — controls priceLabel visibility
  internal var hasPrices: Bool = false

  /// Callback khi calendar fully mounted
  public var onMounted: ((String, String) -> Void)?

  /// Callback khi user chọn from date (range mode)
  /// - startDate: ngày vừa chọn (DD/MM/YYYY)
  /// Callback khi user chọn from date (range mode)
  public var onSelectFromDate: ((String, String) -> Void)?

  /// Optional notice text to display below navigation bar
  public var noticeText: String?

  /// Date formatter dùng cho price key (DD/MM/YYYY)
  private lazy var priceDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "dd/MM/yyyy"
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = self.config.calendar.timeZone
    return f
  }()

  /// Date formatter dùng cho onMounted / onSelectFromDate (DD/MM/YYYY)
  private lazy var resultDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "dd/MM/yyyy"
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = self.config.calendar.timeZone
    return f
  }()

  /// The block to execute after "Done" button will be tapped
  public var doneHandler: ((Value?) -> Void)?

  /// The block to execute when "Cancel" button will be tapped
  public var cancelHandler: (() -> Void)?

  /// Called after an interactive sheet dismissal has completed.
  internal var dismissedHandler: (() -> Void)?


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
    self.updateCalendarLayoutInsets(reloadIfChanged: false)
    self.updateCalendarContentInsets()
    self.hasConfiguredCalendarLayout = true
    self.setupTodayUpdateTimer()
    // Prewarm lunar cache for upcoming months to reduce first-render cost
    self.prewarmLunarCache(monthsBefore: 0, monthsAfter: 2)
  }

  override public func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.navigationController?.presentationController?.delegate = self
    // Fire onMounted after calendar is fully visible & stable
    fireOnMounted()
  }

  override public func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    guard self.hasConfiguredCalendarLayout, !self.hasCleanedUp else { return }

    self.updateCalendarLayoutInsets()
    self.updateCalendarContentInsets()
  }

  override public func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    guard !self.hasCleanedUp else { return }

    // The first layout has its own explicit selected-date restoration. A month
    // captured before that scroll would override the initial selected target.
    let restoreDate = self.needsInitialScroll
      ? nil
      : self.calendarView.visibleDates().monthDates.first?.date
        ?? (self.value as? PickerRange)?.fromDate
        ?? self.todayDate
    self.isHandlingSizeTransition = true

    coordinator.animate(alongsideTransition: nil) { [weak self] _ in
      guard let self = self else { return }
      guard !self.hasCleanedUp else { return }
      self.isHandlingSizeTransition = false
      self.previousBoundsSize = self.calendarView.bounds.size
      self.requestCalendarReload(scrollTo: restoreDate)
    }
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    dismissedHandler?()
    cleanup()
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // Dừng calendar đang cuộn (nếu có) trước khi controller bị dismiss/deinit
    // để tránh việc JTAppleCalendar tiếp tục gọi delegate sinh ra assertion failure
    self.calendarView.setContentOffset(self.calendarView.contentOffset, animated: false)
    self.calendarView.panGestureRecognizer.isEnabled = false
    self.calendarView.panGestureRecognizer.isEnabled = true
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
    }

    viewController.present(navVc, animated: flag, completion: completion)
  }

  /// Cleanup method to cancel all pending month visibility callbacks
  /// Should be called when the controller is being destroyed to prevent memory leaks
  internal func cleanup() {
    // Prevent multiple cleanup calls
    guard !hasCleanedUp else { return }
    hasCleanedUp = true
    isCalendarReloadInProgress = false
    hasPendingCalendarReload = false
    pendingCalendarScrollDate = nil
    activeCalendarScrollDate = nil
    initialCalendarScrollRequested = false

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
    self.dismissedHandler = nil
    self.onMounted = nil
    self.onSelectFromDate = nil
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
        self?.requestCalendarReload()
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

  /// Serialize JTAppleCalendar reloads and preserve the latest scroll target.
  private func requestCalendarReload(scrollTo date: Date? = nil) {
    guard !hasCleanedUp else { return }

    hasPendingCalendarReload = true
    if let date = date {
      pendingCalendarScrollDate = clampedCalendarScrollDate(date)
    }
    guard !isCalendarReloadInProgress else { return }

    startCalendarReload()
  }

  private func startCalendarReload() {
    guard !hasCleanedUp else { return }
    guard calendarView.bounds.width > 0, calendarView.bounds.height > 0 else {
      isCalendarReloadInProgress = false
      hasPendingCalendarReload = true
      return
    }

    if let pendingCalendarScrollDate = pendingCalendarScrollDate {
      activeCalendarScrollDate = pendingCalendarScrollDate
      self.pendingCalendarScrollDate = nil
    }
    isCalendarReloadInProgress = true
    hasPendingCalendarReload = false
    // JTAppleCalendar's reload anchor uses the section header's x coordinate
    // without subtracting sectionInset.left. Reload anchorless, then restore
    // through its header-scroll API after layout has settled.
    calendarView.reloadData(withAnchor: nil) { [weak self] in
      guard let self else { return }
      guard !self.hasCleanedUp else {
        self.isCalendarReloadInProgress = false
        self.hasPendingCalendarReload = false
        self.pendingCalendarScrollDate = nil
        self.activeCalendarScrollDate = nil
        return
      }
      if self.hasPendingCalendarReload {
        self.startCalendarReload()
        return
      }

      guard let scrollDate = self.activeCalendarScrollDate else {
        self.finishCalendarReload()
        return
      }
      guard self.calendarView.cellStatus(for: scrollDate) != nil else {
        self.finishCalendarReload()
        return
      }
      self.calendarView.scrollToHeaderForDate(
        scrollDate,
        triggerScrollToDateDelegate: false,
        withAnimation: false
      ) { [weak self] in
        self?.finishCalendarReload()
      }
    }
  }

  private func finishCalendarReload() {
    guard !hasCleanedUp else { return }
    if hasPendingCalendarReload {
      startCalendarReload()
      return
    }

    activeCalendarScrollDate = nil
    isCalendarReloadInProgress = false
    if initialCalendarScrollRequested {
      initialCalendarScrollRequested = false
      needsInitialScroll = false
    }
  }

  private func clampedCalendarScrollDate(_ date: Date) -> Date {
    var scrollDate = date
    if let minimumDate = privateMinimumDate, scrollDate < minimumDate {
      scrollDate = minimumDate
    }
    if let maximumDate = privateMaximumDate, scrollDate > maximumDate {
      scrollDate = maximumDate
    }
    return scrollDate
  }

  /// Simple cache for lunar date calculations only
  private func getCachedLunarDate(for date: Date) -> (day: Int, month: Int)? {
    let key = Self.lunarCacheKey(for: date, calendar: self.calendar)
    return LunarPersistentCache.shared.get(key)
  }

  private func setCachedLunarDate(
    _ lunarDate: (day: Int, month: Int),
    for date: Date
  ) {
    let key = Self.lunarCacheKey(for: date, calendar: self.calendar)
    LunarPersistentCache.shared.set(lunarDate, for: key)
  }

  private static func lunarCacheKey(for date: Date, calendar: Calendar) -> String {
    let start = calendar.startOfDay(for: date)
    let ts = start.timeIntervalSince1970
    let tz = calendar.timeZone.secondsFromGMT(for: start)
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

    if let notice = noticeText, !notice.isEmpty {
      self.noticeLabel.text = notice
      self.noticeContainer.addSubview(self.noticeLabel)
      self.view.addSubview(self.noticeContainer)
    }

    self.view.addSubview(self.weekView)
    self.view.addSubview(self.calendarView)
  }

  private func configureConstraints() {
    var constraints: [NSLayoutConstraint] = []

    if let notice = noticeText, !notice.isEmpty {
      constraints.append(contentsOf: [
        self.noticeContainer.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
        self.noticeContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
        self.noticeContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        
        self.noticeLabel.topAnchor.constraint(equalTo: self.noticeContainer.topAnchor, constant: Scale.value(8)),
        self.noticeLabel.bottomAnchor.constraint(equalTo: self.noticeContainer.bottomAnchor, constant: -Scale.value(8)),
        self.noticeLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: Scale.value(16)),
        self.noticeLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -Scale.value(16)),
        
        self.weekView.topAnchor.constraint(equalTo: self.noticeContainer.bottomAnchor)
      ])
    } else {
      constraints.append(
        self.weekView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
      )
    }

    constraints.append(contentsOf: [
      self.weekView.leftAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.leftAnchor,
        constant: Constants.Layout.weekViewSidePadding
      ),
      self.weekView.rightAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.rightAnchor,
        constant: -Constants.Layout.weekViewSidePadding
      ),

      self.calendarView.topAnchor.constraint(
        equalTo: self.weekView.bottomAnchor
      ),
      self.calendarView.leftAnchor.constraint(
        equalTo: self.view.leftAnchor
      ),
      self.calendarView.rightAnchor.constraint(
        equalTo: self.view.rightAnchor
      ),
      self.calendarView.bottomAnchor.constraint(
        equalTo: self.view.bottomAnchor
      ),
    ])
    
    NSLayoutConstraint.activate(constraints)
  }

  private func updateCalendarContentInsets() {
    // The collection view fills the viewport to the screen edge, so keep its
    // terminal content clear of the home indicator inside the scroll content.
    let bottomInset = self.view.safeAreaInsets.bottom
      + (self.config.controller.showSubmitButton ? 20 : 0)
    var contentInset = self.calendarView.contentInset
    contentInset.top = 0
    contentInset.left = 0
    contentInset.right = 0
    contentInset.bottom = bottomInset
    guard self.calendarView.contentInset != contentInset else { return }
    self.calendarView.contentInset = contentInset

    var indicatorInsets = self.calendarView.verticalScrollIndicatorInsets
    indicatorInsets.top = 0
    indicatorInsets.left = 0
    indicatorInsets.right = 0
    indicatorInsets.bottom = bottomInset
    self.calendarView.verticalScrollIndicatorInsets = indicatorInsets
  }

  private func updateCalendarLayoutInsets(reloadIfChanged: Bool = true) {
    // Match the weekday strip's safe-area + 6pt content margins while letting
    // the collection view itself extend edge-to-edge.
    let horizontalInset = self.view.safeAreaInsets.left
      + Constants.Layout.calendarHorizontalPadding
    let sectionInset = UIEdgeInsets(
      top: 0,
      left: horizontalInset,
      bottom: 0,
      right: self.view.safeAreaInsets.right + Constants.Layout.calendarHorizontalPadding
    )
    guard self.calendarView.sectionInset != sectionInset else { return }

    let restoreDate = self.needsInitialScroll
      ? nil
      : self.calendarView.visibleDates().monthDates.first?.date
    self.calendarView.sectionInset = sectionInset
    if reloadIfChanged {
      self.requestCalendarReload(scrollTo: restoreDate)
    }
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
    // Defer the initial date restoration until the calendar has laid out.
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

      // Configure price
      if hasPrices {
        config.showPriceArea = true
        let key = priceDateFormatter.string(from: date)
        if let priceData = priceMap[key] {
          config.priceText = formatPrice(priceData.price)
          config.isCheapest = priceData.isCheapest ?? false
        }
      }
    }

    return config
  }

  /// Configures lunar date information for the cell with caching
  private func configureLunarDate(
    for config: inout DayCell.ViewConfig,
    date: Date
  ) {
    if !self.config.dayCell.showLunarDate {
      config.lunarDateLabelText = ""
      return
    }

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
        self?.requestCalendarReload()
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
          self?.requestCalendarReload()
          // Update value after reload to ensure UI sync
          self?.value = newRange.range as? Value
          // Small delay to ensure reload completes before selection
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self?.selectValue(newRange.range as? Value, in: calendar)
          }
        }
        // Fire callback với from date vừa chọn
        fireOnSelectFromDate(selectedDate: newRange.range.fromDate)
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
        self?.requestCalendarReload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          self?.selectValue(newRange as? Value, in: calendar)
        }
      }
      // Fire callback with selected from date
      fireOnSelectFromDate(selectedDate: from)
      return true
    }

    if current.toDate != nil {
      // Start a new range from tapped date
      let from = date.startOfDay(in: self.config.calendar)
      let newRange = PickerRange(from: from, to: nil)
      self.value = newRange as? Value
      calendar.deselectAllDates(triggerSelectionDelegate: false)
      DispatchQueue.main.async { [weak self] in
        self?.requestCalendarReload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          self?.selectValue(newRange as? Value, in: calendar)
        }
      }
      // Fire callback with selected from date
      fireOnSelectFromDate(selectedDate: from)
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
        self?.requestCalendarReload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          self?.selectValue(newRange as? Value, in: calendar)
        }
      }
      // Fire callback with selected from date
      fireOnSelectFromDate(selectedDate: newFrom)
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

  // MARK: - Price Helpers

  /// Cập nhật price map với dữ liệu mới cho 1 tháng, reload lại calendar
  internal func updatePrices(_ newPrices: [LDP_PriceData]) {
    priceMap.removeAll()
    for price in newPrices {
      priceMap[price.date] = price
    }
    DispatchQueue.main.async { [weak self] in
      self?.requestCalendarReload()
    }
  }

  /// Cập nhật maximumDate mới và reload lại calendar UI
  internal func updateMaximumDate(_ newMaxDate: Date) {
    self.maximumDate = newMaxDate
    DispatchQueue.main.async { [weak self] in
      self?.requestCalendarReload()
    }
  }


  private func formatPrice(_ price: Double) -> String {
    let thousands = NSNumber(value: Int(round(price / 1000.0)))
    if let formatted = self.priceFormatter.string(from: thousands) {
      return "\(formatted)K"
    }
    return "\(thousands)K"
  }


  /// Fire onSelectFromDate với startDate = ngày user chọn, endDate = calendar end
  private func fireOnSelectFromDate(selectedDate: Date) {
    guard let onSelectFromDate = self.onSelectFromDate else { return }

    let startStr = resultDateFormatter.string(from: selectedDate)
    let endDate = self.privateMaximumDate
      ?? self.config.calendar.date(byAdding: .year, value: self.config.yearRangeOffset, to: Date())
      ?? Date()
    let endStr = resultDateFormatter.string(from: endDate)

    DispatchQueue.main.async {
      onSelectFromDate(startStr, endStr)
    }
  }

  /// Fire onMounted callback sau khi calendar fully appeared
  private func fireOnMounted() {
    guard let onMounted = self.onMounted else { return }

    let timeZone = self.config.calendar.timeZone
    let formatter = resultDateFormatter

    let startDate = self.privateMinimumDate
      ?? self.config.calendar.date(byAdding: .year, value: -self.config.yearRangeOffset, to: Date())
      ?? Date()
    let endDate = self.privateMaximumDate
      ?? self.config.calendar.date(byAdding: .year, value: self.config.yearRangeOffset, to: Date())
      ?? Date()

    _ = timeZone // used by formatter
    let startStr = formatter.string(from: startDate)
    let endStr = formatter.string(from: endDate)

    DispatchQueue.main.async {
      onMounted(startStr, endStr)
    }
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // Detect bounds change to force layout recalculation
    // This is critical for iPad FormSheet where initial bounds are full screen
    // causing JTAppleCalendar to cache overly wide columns
    if self.calendarView.bounds.size != self.previousBoundsSize {
      self.previousBoundsSize = self.calendarView.bounds.size
      // During rotation, wait until UIKit applies the final bounds. The final
      // reload then restores the visible month through the header-scroll API.
      let initialScrollWillStart =
        self.needsInitialScroll && !self.initialCalendarScrollRequested
      if !self.isHandlingSizeTransition && !initialScrollWillStart {
        let restoreDate = self.needsInitialScroll
          ? nil
          : self.calendarView.visibleDates().monthDates.first?.date
        DispatchQueue.main.async { [weak self] in
          self?.requestCalendarReload(scrollTo: restoreDate)
        }
      }
    }

    // Update bottom padding so the last content isn't obscured by the home indicator
    updateCalendarContentInsets()

    if needsInitialScroll && !initialCalendarScrollRequested {
      initialCalendarScrollRequested = true
      if let rangeValue = self.value as? PickerRange {
        self.requestCalendarReload(scrollTo: rangeValue.fromDate)
      } else {
        let nowDate = Date()
        let targetDate = self.privateMaximumDate ?? nowDate
        let scrollDate = targetDate < nowDate ? targetDate : nowDate
        self.requestCalendarReload(scrollTo: scrollDate)
      }
    }
  }

  // MARK: - Cache Prewarm

  /// Pre-calculate lunar dates for a range of months and persist them to the on-disk cache.
  /// This runs on a background queue so the first visible month is not delayed.
  private func prewarmLunarCache(monthsBefore: Int, monthsAfter: Int) {
    guard self.config.dayCell.showLunarDate else { return }

    let calendar = self.config.calendar
    let timeZone = calendar.timeZone
    let now = Date()

    DispatchQueue.global(qos: .utility).async {
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
          let key = Self.lunarCacheKey(for: cursor, calendar: calendar)
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
    public var noticeLabelColor = ColorWrapper.customBlack
    public var noticeBackgroundColor = ColorWrapper(fromHex: "#D3D3D3") // Default LTGRAY
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
