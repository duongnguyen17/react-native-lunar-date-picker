package com.margelo.nitro.lunardatepicker.ui.fragments

import android.annotation.SuppressLint
import android.app.Dialog
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.view.doOnLayout
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.kizitonwose.calendar.core.CalendarDay
import com.kizitonwose.calendar.core.CalendarMonth
import com.kizitonwose.calendar.view.CalendarView
import com.kizitonwose.calendar.view.MarginValues
import com.kizitonwose.calendar.view.MonthDayBinder
import com.kizitonwose.calendar.view.MonthHeaderFooterBinder
import com.margelo.nitro.lunardatepicker.LDP_PriceData
import com.margelo.nitro.lunardatepicker.LDP_Range
import com.margelo.nitro.lunardatepicker.R
import com.margelo.nitro.lunardatepicker.constants.DataConstants
import com.margelo.nitro.lunardatepicker.constants.LayoutConstants
import com.margelo.nitro.lunardatepicker.models.DateSelection
import com.margelo.nitro.lunardatepicker.models.PickerConfig
import com.margelo.nitro.lunardatepicker.models.SerializableRange
import com.margelo.nitro.lunardatepicker.ui.builders.UIBuilder
import com.margelo.nitro.lunardatepicker.ui.viewholders.DayViewHolder
import com.margelo.nitro.lunardatepicker.ui.viewholders.MonthViewHolder
import com.margelo.nitro.lunardatepicker.utils.DateConverter
import com.margelo.nitro.lunardatepicker.utils.DimensionUtils.dpToPx
import com.margelo.nitro.lunardatepicker.utils.ScaleUtils
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

class LunarDatePickerFragment : BottomSheetDialogFragment() {

    companion object {
        private const val TAG = DataConstants.LogTags.FRAGMENT
        private const val ARG_CONFIG = DataConstants.BundleKeys.ARG_CONFIG
        private const val ARG_MIN_DATE = DataConstants.BundleKeys.ARG_MIN_DATE
        private const val ARG_MAX_DATE = DataConstants.BundleKeys.ARG_MAX_DATE
        private const val ARG_INITIAL_VALUE = DataConstants.BundleKeys.ARG_INITIAL_VALUE
        private const val ARG_NOTICE = DataConstants.BundleKeys.ARG_NOTICE

        fun newInstance(
            config: PickerConfig,
            minimumDate: LocalDate? = null,
            maximumDate: LocalDate? = null,
            initialValue: LDP_Range? = null,
            prices: Map<String, LDP_PriceData>? = null,
            notice: String? = null,
            onMounted: ((String, String) -> Unit)? = null,
            onSelectFromDate: ((String, String) -> Unit)? = null,
            onResult: (LDP_Range) -> Unit
        ): LunarDatePickerFragment {
            val fragment = LunarDatePickerFragment()
            fragment.setupCallbacks(onResult, onMounted, onSelectFromDate)
            fragment.pricesMap = prices
            fragment.arguments = createArguments(config, minimumDate, maximumDate, initialValue, notice)
            return fragment
        }

        private fun createArguments(
            config: PickerConfig,
            minimumDate: LocalDate?,
            maximumDate: LocalDate?,
            initialValue: LDP_Range?,
            notice: String?
        ): Bundle {
            return Bundle().apply {
                putSerializable(ARG_CONFIG, config)
                minimumDate?.let { putString(ARG_MIN_DATE, it.toString()) }
                maximumDate?.let { putString(ARG_MAX_DATE, it.toString()) }
                initialValue?.let { putSerializable(ARG_INITIAL_VALUE, SerializableRange.fromRange(it)) }
                notice?.let { putString(ARG_NOTICE, it) }
            }
        }
    }

    // Dependencies
    private lateinit var config: PickerConfig
    private lateinit var dateConverter: DateConverter
    private lateinit var uiBuilder: UIBuilder
    private lateinit var calendarView: CalendarView

    // State
    private var minimumDate: LocalDate? = null
    private var maximumDate: LocalDate? = null
    private var initialValue: LDP_Range? = null
    private var selection = DateSelection()
    private val timeZone: ZoneId by lazy { config.calendar.timeZone.toZoneId() }
    
    // Price data: key = "DD/MM/YYYY"
    var pricesMap: Map<String, LDP_PriceData>? = null
    private var noticeText: String? = null

    // Callbacks
    private var onResultCallback: ((LDP_Range) -> Unit)? = null
    private var onMountedCallback: ((String, String) -> Unit)? = null
    private var onSelectFromDateCallback: ((String, String) -> Unit)? = null

    // UI Elements
    private var submitIcon: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initializeFromArguments()
        initializeDependencies()
        setupInitialSelection()
        prewarmLunarCache()
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        val bottomSheetDialog = BottomSheetDialog(requireContext())
        val view = createBottomSheetView()
        bottomSheetDialog.setContentView(view)
        setupBottomSheetBehavior(bottomSheetDialog)
        return bottomSheetDialog
    }

    override fun onDestroyView() {
        super.onDestroyView()
        // Clear binders to prevent potential memory leaks
        calendarView.dayBinder = null
        calendarView.monthHeaderBinder = null
    }

    override fun onDestroy() {
        super.onDestroy()
        cleanup()
    }

    private fun initializeFromArguments() {
        arguments?.let { args ->
            config = args.getSerializable(ARG_CONFIG) as PickerConfig
            minimumDate = args.getString(ARG_MIN_DATE)?.let { LocalDate.parse(it) }
            maximumDate = args.getString(ARG_MAX_DATE)?.let { LocalDate.parse(it) }
            val serializableRange = args.getSerializable(ARG_INITIAL_VALUE) as? SerializableRange
            initialValue = serializableRange?.toRange()
            noticeText = args.getString(ARG_NOTICE)
        }
    }

    private fun initializeDependencies() {
        dateConverter = DateConverter()
        uiBuilder = UIBuilder(requireContext(), config)
    }

    private fun setupCallbacks(
        onResult: (LDP_Range) -> Unit,
        onMounted: ((String, String) -> Unit)? = null,
        onSelectFromDate: ((String, String) -> Unit)? = null
    ) {
        onResultCallback = onResult
        onMountedCallback = onMounted
        onSelectFromDateCallback = onSelectFromDate
    }

    private fun createBottomSheetView(): View {
        val rootView = LinearLayout(requireContext()).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(config.controller.backgroundColor)
        }

        // Always add header bar (contains title, close button and submit button)
        rootView.addView(createHeaderBar())
        
        noticeText?.takeIf { it.isNotEmpty() }?.let { text ->
            rootView.addView(createNoticeView(text))
        }
        
        rootView.addView(uiBuilder.createWeekView())
        rootView.addView(createCalendarContainer())

        return rootView
    }
    
    private fun createNoticeView(text: String): View {
        val context = requireContext()
        val noticeContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(config.controller.noticeBackgroundColor)
            setPadding(
                dpToPx(ScaleUtils.scaleDp(16)),
                dpToPx(ScaleUtils.scaleDp(8)),
                dpToPx(ScaleUtils.scaleDp(16)),
                dpToPx(ScaleUtils.scaleDp(8))
            )
        }
        
        val noticeLabel = android.widget.TextView(context).apply {
            this.text = text
            setTextColor(config.controller.noticeLabelColor)
            textSize = ScaleUtils.scale(12f)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        
        noticeContainer.addView(noticeLabel)
        return noticeContainer
    }

    /**
     * Creates the header bar with close icon, centered title and optional submit icon
     */
    private fun createHeaderBar(): View {
        val context = requireContext()
        
        val headerBar = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(config.controller.backgroundColor)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            setPadding(
                dpToPx(ScaleUtils.scaleDp(16)),
                dpToPx(ScaleUtils.scaleDp(15)),
                dpToPx(ScaleUtils.scaleDp(16)),
                dpToPx(ScaleUtils.scaleDp(15))
            )
            gravity = Gravity.CENTER_VERTICAL
        }

        val closeIcon = TextView(context).apply {
            text = "✕"
            textSize = 18f
            setTextColor(config.controller.titleColor)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 0)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setOnClickListener { dismiss() }
        }

        val titleCenterLabel = TextView(context).apply {
            text = config.controller.title
            setTextColor(config.controller.titleColor)
            textSize = LayoutConstants.TextSize.TITLE
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }

        // Right submit icon
        submitIcon = TextView(context).apply {
            text = "✔️"
            textSize = 16f
            setTextColor(config.controller.submitButtonColor)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 0)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            
            visibility = if (config.controller.showSubmitButton) View.VISIBLE else View.GONE
            
            // For range selection, it might be disabled initially
            isEnabled = true 
            alpha = 1.0f

            setOnClickListener {
                handleSubmit()
            }
        }

        headerBar.addView(closeIcon)
        headerBar.addView(titleCenterLabel)
        headerBar.addView(submitIcon)

        return headerBar
    }

    private fun createCalendarContainer(): FrameLayout {
        val calendarContainer = FrameLayout(requireContext()).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
            )
        }

        calendarView = CalendarView(requireContext()).apply {
            dayViewResource = R.layout.kiz_day_cell
            monthMargins = MarginValues(LayoutConstants.Padding.MONTH_VIEW_HORIZONTAL, 0)
            monthHeaderResource = R.layout.kiz_month_header
            orientation = RecyclerView.VERTICAL
            clipToPadding = false
        }

        setupCalendarView()
        calendarContainer.addView(
            calendarView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        return calendarContainer
    }


    private fun setupCalendarView() {
        setupCalendarBinders()
        setupCalendarRange()
        // No additional listeners required currently
    }

    private fun setupCalendarBinders() {
        calendarView.dayBinder = object : MonthDayBinder<DayViewHolder> {
            override fun create(view: View): DayViewHolder {
                return DayViewHolder(
                    view = view,
                    config = config,
                    dateConverter = dateConverter,
                    timeZone = timeZone,
                    isDateEnabled = ::isDateEnabled,
                    onDateClick = ::handleDateSelection,
                    priceMap = pricesMap
                )
            }

            override fun bind(container: DayViewHolder, data: CalendarDay) {
                container.apply {
                    selectedFromDate = selection.startDate
                    selectedToDate = selection.endDate
                    // Sync latest price map (may be updated after fragment creation)
                    updatePriceMap(pricesMap)
                    bind(data)
                }
            }
        }

        calendarView.monthHeaderBinder = object : MonthHeaderFooterBinder<MonthViewHolder> {
            override fun create(view: View) = MonthViewHolder(view, config)
            override fun bind(container: MonthViewHolder, data: CalendarMonth) = container.bind(data)
        }
    }

    private fun setupCalendarRange() {
        val currentDate = LocalDate.now()
        val startMonth = minimumDate?.let { YearMonth.from(it) }
            ?: YearMonth.from(currentDate.minusYears(config.yearRangeOffset.toLong()))
        val endMonth = maximumDate?.let { YearMonth.from(it) }
            ?: YearMonth.from(currentDate.plusYears(config.yearRangeOffset.toLong()))

        calendarView.setup(startMonth, endMonth, DayOfWeek.MONDAY)
        calendarView.scrollToMonth(YearMonth.from(currentDate))
    }

    // Removed unused scroll listeners

    private fun setupBottomSheetBehavior(bottomSheetDialog: BottomSheetDialog) {
        bottomSheetDialog.setOnShowListener { dialog ->
            val d = dialog as BottomSheetDialog
            val bottomSheet = d.findViewById<View>(com.google.android.material.R.id.design_bottom_sheet)
            bottomSheet?.let {
                val behavior = BottomSheetBehavior.from(it)
                behavior.state = BottomSheetBehavior.STATE_EXPANDED
                behavior.skipCollapsed = true
                behavior.isDraggable = true
            }
            scrollToCurrentDateIfNeeded()
            if (config.controller.showSubmitButton) {
                setConfirmButtonEnabled(
                    if (config.controller.isSingleMode) selection.startDate != null else (selection.startDate != null && selection.endDate != null)
                )
            }
            // Fire onMounted after dialog is fully shown & stable
            fireOnMounted()
        }
    }

    private fun handleDateSelection(date: LocalDate) {
        if (!config.controller.showSubmitButton) {
            if (handleAutoSubmit(date)) return
        }

        if (config.controller.isSingleMode) {
            handleSingleSelection(date)
            return
        }

        val shouldComplete = processRangeSelection(date, initialValue != null)

        if (config.controller.showSubmitButton) {
            if (shouldComplete) {
                setConfirmButtonEnabled(true)
            } else {
                setConfirmButtonEnabled(false)
            }
        }

        // Fire onSelectFromDate khi user chọn from date mới (range chưa hoàn chỉnh)
        if (!shouldComplete) {
            fireOnSelectFromDate(date)
        }

        calendarView.notifyCalendarChanged()
    }

    // region Helpers

    private fun handleSingleSelection(date: LocalDate) {
        selection = DateSelection(startDate = date, endDate = null)
        if (config.controller.showSubmitButton) setConfirmButtonEnabled(true)
        calendarView.notifyCalendarChanged()
    }

    private fun handleAutoSubmit(date: LocalDate): Boolean {
        if (config.controller.isSingleMode) {
            selection = DateSelection(startDate = date, endDate = null)
            onResultCallback?.invoke(LDP_Range(from = dateConverter.stringFromDate(date, timeZone), to = null))
            dismiss()
            return true
        }

        val currentFrom = selection.startDate
        val currentTo = selection.endDate
        return when {
            currentFrom == null || currentTo != null -> {
                selection = DateSelection(startDate = date, endDate = null)
                calendarView.notifyCalendarChanged()
                true
            }
            date.isBefore(currentFrom) -> {
                selection = DateSelection(startDate = date, endDate = null)
                calendarView.notifyCalendarChanged()
                true
            }
            else -> {
                selection = DateSelection(startDate = currentFrom, endDate = date)
                calendarView.notifyCalendarChanged()
                onResultCallback?.invoke(LDP_Range(from = dateConverter.stringFromDate(currentFrom, timeZone), to = dateConverter.stringFromDate(date, timeZone)))
                dismiss()
                true
            }
        }
    }

    // endregion

    private fun processRangeSelection(date: LocalDate, hasInitialValue: Boolean): Boolean {
        var shouldComplete = false

        val currentFromDate = selection.startDate
        val currentToDate = selection.endDate

        when {
            currentFromDate == null -> {
                // Case 1 (iOS): No current selection, start a new range
                selection = DateSelection(startDate = date, endDate = null)
            }
            currentToDate != null -> {
                // Case 2 (iOS): Range is already complete, start a new selection
                selection = DateSelection(startDate = date, endDate = null)
            }
            else -> { // Case 3 (iOS): Only start date is selected, now selecting end date
                val startDate = currentFromDate!!
                if (date.isBefore(startDate)) {
                    // If selected date is before start date, swap and complete the range
                    selection = DateSelection(startDate = date, endDate = startDate)
                } else {
                    // Otherwise, set as end date
                    selection = DateSelection(startDate = startDate, endDate = date)
                }
                shouldComplete = true
            }
        }

        // Handle initial value case (iOS specific logic)
        // This applies if the picker opened with a pre-selected range and user is making first tap
        // After first tap, hasInitialValue is effectively false for subsequent taps
        if (!shouldComplete && hasInitialValue && currentFromDate != null && currentToDate == null) {
            if (date.isBefore(currentFromDate)) {
                // If selected date is before initial fromDate, start new range from selectedDate
                selection = DateSelection(startDate = date, endDate = null)
                shouldComplete = false // Not complete yet
            } else {
                // If selected date is after initial fromDate, complete the range
                selection = DateSelection(startDate = currentFromDate, endDate = date)
                shouldComplete = true // Complete
            }
        }

        return shouldComplete
    }

    private fun setupInitialSelection() {
        initialValue?.let { value ->
            val fromDate = dateConverter.dateFromString(value.from, timeZone)
            fromDate?.let {
                selection = selection.copy(startDate = it)
            }

            value.to?.let { toValue ->
                val toDate = dateConverter.dateFromString(toValue, timeZone)
                toDate?.let {
                    selection = selection.copy(endDate = it)
                }
            }
        }
        // Defer UI updates until views are created (handled in onShow)
    }

    private fun scrollToCurrentDateIfNeeded() {
        val targetDate = initialValue?.let { dateConverter.dateFromString(it.from, timeZone) }
            ?: LocalDate.now().let { current ->
                maximumDate?.let { max -> if (max.isBefore(current)) max else current } ?: current
            }

        calendarView.doOnLayout {
            calendarView.scrollToMonth(YearMonth.from(targetDate))
        }
    }

    private fun isDateEnabled(date: LocalDate): Boolean {
        minimumDate?.let { if (date.isBefore(it)) return false }
        maximumDate?.let { if (date.isAfter(it)) return false }

        return true
    }

    private fun cleanup() {
        onResultCallback = null
        onMountedCallback = null
        onSelectFromDateCallback = null
    }

    private fun prewarmLunarCache() {
        lifecycleScope.launch(Dispatchers.IO) {
            val startDate = LocalDate.now()
            val endDate = startDate.plusMonths(3)
            dateConverter.preloadLunarDateCache(startDate, endDate, timeZone)
        }
    }

    private fun handleSubmit() {
        if (config.controller.isSingleMode) {
            selection.startDate?.let { from ->
                onResultCallback?.invoke(
                    LDP_Range(
                        from = dateConverter.stringFromDate(from, timeZone),
                        to = null
                    )
                )
                dismiss()
            }
        } else {
            if (selection.startDate != null && selection.endDate != null) {
                onResultCallback?.invoke(
                    LDP_Range(
                        from = dateConverter.stringFromDate(selection.startDate!!, timeZone),
                        to = dateConverter.stringFromDate(selection.endDate!!, timeZone)
                    )
                )
                dismiss()
            }
        }
    }

    private fun setConfirmButtonEnabled(enabled: Boolean) {
        submitIcon?.let {
            it.isEnabled = enabled
            it.alpha = if (enabled) 1.0f else 0.5f // Visual feedback
        }
    }

    /**
     * Cập nhật price map và notify calendar rebind.
     * Có thể gọi khi calendar đang hiển thị.
     */
    fun updatePrices(newPrices: Map<String, LDP_PriceData>) {
        val merged = (pricesMap ?: emptyMap()).toMutableMap()
        merged.putAll(newPrices)
        pricesMap = merged
        calendarView.notifyCalendarChanged()
    }

    /**
     * Fire onMounted sau khi dialog fully shown.
     * startDate = minimumDate hoặc năm hiện tại - yearRangeOffset
     * endDate = maximumDate hoặc năm hiện tại + yearRangeOffset
     */
    private fun fireOnMounted() {
        val callback = onMountedCallback ?: return
        val now = LocalDate.now(timeZone)
        val start = minimumDate ?: now.minusYears(config.yearRangeOffset.toLong())
        val end = maximumDate ?: now.plusYears(config.yearRangeOffset.toLong())
        val startStr = dateConverter.stringFromDate(start, timeZone)
        val endStr = dateConverter.stringFromDate(end, timeZone)
        callback(startStr, endStr)
    }

    /**
     * Fire onSelectFromDate với startDate = ngày user chọn, endDate = calendar end
     */
    private fun fireOnSelectFromDate(selectedDate: LocalDate) {
        val callback = onSelectFromDateCallback ?: return
        val now = LocalDate.now(timeZone)
        val end = maximumDate ?: now.plusYears(config.yearRangeOffset.toLong())
        val startStr = dateConverter.stringFromDate(selectedDate, timeZone)
        val endStr = dateConverter.stringFromDate(end, timeZone)
        callback(startStr, endStr)
    }
}
