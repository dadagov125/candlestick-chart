## 0.4.1

* **Fixes:**
  * Reset to initial state if the new widget has fewer candles.
  * Increase offset to keep the current position when new candles are added.

* **New Features:**
  * Added `animationDuration` parameter to control the duration of animations.

## 0.4.0

* **Breaking Changes:**
    * `volumeColor` has been separated into `volumeGainColor` and `volumeLossColor`.

* **New Features:**
    * Added `enableGridLines` parameter to allow users to toggle the grid lines.
    * Added `lineColor` to `currentPriceStyle` to customize the color of the current price line.
    * Added `logo` params to ChartStyle  to allow users to add a logo to the chart.
    * Added `minVisibleCandleCount` and `maxVisibleCandleCount` to control the number of visible candles in the chart.
    * Added `volumeLabel` for better volume data representation.
    * Added `currentVolumeLabel` for real-time volume data representation.
    * Added `priceLabelPositions` to `CandlestickChart` for better customization.
    * Added `distanceBetweenCandle` to `CandlestickChart` for better customization.
  
* **Changes:**
    * Changed min candles length to 1.

## 0.3.7

* expose currentPrice to InteractiveChart.

## 0.3.6

* Added the ability to track changes in horizontal scrolling of the chart.
* Added the ability to display the current price on the right side of the chart.
* Now the chart is updated when the size of the list of candles changes.

## 0.3.5

* Update dependency: intl to ^0.19.0.

## 0.3.4

* Fix a potential crash if volume numbers are null.

## 0.3.3

* Fix an issue where `onTap` event was not
  firing. [(Issue #8)](https://github.com/fluttercandies/flutter-interactive-chart/issues/8)

## 0.3.2

* Add `initialVisibleCandleCount` parameter for setting a default zoom
  level. [(Issue #6)](https://github.com/fluttercandies/flutter-interactive-chart/issues/6)

## 0.3.1

* Allow web and desktop users to zoom the chart with mouse scroll
  wheel. [(Issue #4)](https://github.com/fluttercandies/flutter-interactive-chart/issues/4)

## 0.3.0

* BREAKING: Add support for multiple trend
  lines. [(Issue #2)](https://github.com/fluttercandies/flutter-interactive-chart/issues/2)
* The old `trend` property is changed to `trends`, to support multiple data points per `CandleData`.
* The old `trendLineColor` property is changed to `trendLineStyles`.
* The `CandleData.computeMA` helper function no longer modifies data in-place. To migrate,
  change `CandleData.computeMA(data)` to the following two lines:
  `final ma = CandleData.computeMA(data); ` and
  `for (int i = 0; i < data.length; i++) { data[i].trends = [ma[i]]; }`.
* Update example project to reflect above changes.

## 0.2.1

* Add `onTap` event and `onCandleResize` event.
* Allow `overlayInfo` to return an empty object.
* Update example project.

## 0.2.0

* BREAKING: Organize folder structures, now you only need to
  import `package:interactive_chart/interactive_chart.dart`.
* BREAKING: Change CandleData `timestamp` to milliseconds, you might need to multiply your data by
  1000 when creating CandleData objects.
* Fix an issue where zooming was occasionally not smooth.
* Fix an issue where overlay panel was occasionally clipped.

## 0.1.1

* Improve performance.
* Allow `high` and `low` prices to be optional.
* Align date/time labels towards vertical bottom.

## 0.1.0

* Initial Open Source release.
