package com.margelo.nitro.lunardatepicker.ui.fragments

import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

/** Applies only the part of a window's safe insets that overlaps this view. */
internal object SafeAreaInsets {
  data class Frame(val left: Int, val top: Int, val right: Int, val bottom: Int)
  data class Edges(val left: Int, val top: Int, val right: Int, val bottom: Int)

  fun overlapPadding(frame: Frame, windowWidth: Int, windowHeight: Int, safe: Edges): Edges = Edges(
    left = overlap(frame.left, frame.right, 0, safe.left),
    top = overlap(frame.top, frame.bottom, 0, safe.top),
    right = overlap(frame.left, frame.right, windowWidth - safe.right, windowWidth),
    bottom = overlap(frame.top, frame.bottom, windowHeight - safe.bottom, windowHeight),
  )

  fun install(content: View, windowDecor: View): () -> Unit {
    val initialLeft = content.paddingLeft
    val initialTop = content.paddingTop
    val initialRight = content.paddingRight
    val initialBottom = content.paddingBottom
    val contentLocation = IntArray(2)
    val decorLocation = IntArray(2)
    var latestInsets: WindowInsetsCompat? = null

    val updatePadding = {
      val rootInsets = ViewCompat.getRootWindowInsets(windowDecor) ?: latestInsets
      if (rootInsets != null && windowDecor.width > 0 && windowDecor.height > 0) {
        val safeInsets = rootInsets.getInsets(
          WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
        )
        content.getLocationOnScreen(contentLocation)
        windowDecor.getLocationOnScreen(decorLocation)
        val frame = Frame(
          left = contentLocation[0] - decorLocation[0],
          top = contentLocation[1] - decorLocation[1],
          right = contentLocation[0] - decorLocation[0] + content.width,
          bottom = contentLocation[1] - decorLocation[1] + content.height,
        )
        val padding = overlapPadding(
          frame = frame,
          windowWidth = windowDecor.width,
          windowHeight = windowDecor.height,
          safe = Edges(safeInsets.left, safeInsets.top, safeInsets.right, safeInsets.bottom),
        )
        val left = initialLeft + padding.left
        val top = initialTop + padding.top
        val right = initialRight + padding.right
        val bottom = initialBottom + padding.bottom
        if (content.paddingLeft != left || content.paddingTop != top ||
          content.paddingRight != right || content.paddingBottom != bottom
        ) {
          content.setPadding(left, top, right, bottom)
        }
      }
    }

    ViewCompat.setOnApplyWindowInsetsListener(content) { _, insets ->
      latestInsets = insets
      updatePadding()
      // This view has accounted for safe areas; descendants must not add them again.
      WindowInsetsCompat.CONSUMED
    }
    val contentLayoutListener = View.OnLayoutChangeListener { _, _, _, _, _, _, _, _, _ -> updatePadding() }
    val decorLayoutListener = View.OnLayoutChangeListener { _, _, _, _, _, _, _, _, _ -> updatePadding() }
    content.addOnLayoutChangeListener(contentLayoutListener)
    windowDecor.addOnLayoutChangeListener(decorLayoutListener)
    ViewCompat.requestApplyInsets(content)
    return {
      ViewCompat.setOnApplyWindowInsetsListener(content, null)
      content.removeOnLayoutChangeListener(contentLayoutListener)
      windowDecor.removeOnLayoutChangeListener(decorLayoutListener)
    }
  }

  private fun overlap(start: Int, end: Int, safeStart: Int, safeEnd: Int): Int =
    (minOf(end, safeEnd) - maxOf(start, safeStart)).coerceAtLeast(0)
}
