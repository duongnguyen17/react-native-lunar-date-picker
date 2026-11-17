package com.margelo.nitro.lunardatepicker.ui.fragments

import org.junit.Assert.assertEquals
import org.junit.Test

class SafeAreaInsetsTest {
  @Test
  fun appliesOnlyBarsOverlappingExpandedSheet() {
    val padding = SafeAreaInsets.overlapPadding(
      frame = SafeAreaInsets.Frame(left = 0, top = 240, right = 1000, bottom = 1000),
      windowWidth = 1000,
      windowHeight = 1000,
      safe = SafeAreaInsets.Edges(left = 0, top = 32, right = 0, bottom = 28),
    )

    assertEquals(SafeAreaInsets.Edges(left = 0, top = 0, right = 0, bottom = 28), padding)
  }

  @Test
  fun doesNotPadFloatingDialogAlreadyInsideSafeArea() {
    val padding = SafeAreaInsets.overlapPadding(
      frame = SafeAreaInsets.Frame(left = 80, top = 70, right = 920, bottom = 930),
      windowWidth = 1000,
      windowHeight = 1000,
      safe = SafeAreaInsets.Edges(left = 24, top = 48, right = 24, bottom = 32),
    )

    assertEquals(SafeAreaInsets.Edges(0, 0, 0, 0), padding)
  }

  @Test
  fun accountsForLandscapeLeftCutoutAndBottomBar() {
    val frame = SafeAreaInsets.Frame(left = 0, top = 0, right = 1000, bottom = 600)
    val safe = SafeAreaInsets.Edges(left = 44, top = 0, right = 0, bottom = 24)
    val expected = SafeAreaInsets.Edges(left = 44, top = 0, right = 0, bottom = 24)

    assertEquals(expected, SafeAreaInsets.overlapPadding(frame, 1000, 600, safe))
    // The same window geometry always yields the same padding value.
    assertEquals(expected, SafeAreaInsets.overlapPadding(frame, 1000, 600, safe))
  }

  @Test
  fun accountsForRightCutoutAndTopStatusBarWhenContentReachesThoseEdges() {
    val frame = SafeAreaInsets.Frame(left = 700, top = 0, right = 1000, bottom = 600)
    val safe = SafeAreaInsets.Edges(left = 0, top = 38, right = 36, bottom = 0)

    assertEquals(
      SafeAreaInsets.Edges(left = 0, top = 38, right = 36, bottom = 0),
      SafeAreaInsets.overlapPadding(frame, 1000, 600, safe),
    )
  }

  @Test
  fun removedInsetsResetAllPaddingToZero() {
    val frame = SafeAreaInsets.Frame(left = 0, top = 0, right = 1000, bottom = 600)

    assertEquals(
      SafeAreaInsets.Edges(0, 0, 0, 0),
      SafeAreaInsets.overlapPadding(frame, 1000, 600, SafeAreaInsets.Edges(0, 0, 0, 0)),
    )
  }

  @Test
  fun partiallyInsetSheetGetsOnlyTheUncoveredBottomArea() {
    val padding = SafeAreaInsets.overlapPadding(
      frame = SafeAreaInsets.Frame(left = 0, top = 500, right = 1000, bottom = 990),
      windowWidth = 1000,
      windowHeight = 1000,
      safe = SafeAreaInsets.Edges(left = 0, top = 32, right = 0, bottom = 28),
    )

    assertEquals(SafeAreaInsets.Edges(0, 0, 0, 18), padding)
  }
}
