import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ChartStyle {
  /// The percentage height of volume.
  ///
  /// Defaults to 0.2, which means volume bars will be 20% of total height,
  /// thus leaving price bars to be 80% of the total height.
  final double volumeHeightFactor;

  /// The padding on the right-side of the chart.
  final double priceLabelWidth;

  /// The padding on the bottom-side of the chart.
  ///
  /// Defaults to 24.0, date/time labels is drawn vertically bottom-aligned,
  /// thus adjusting this value would also control the padding between
  /// the chart and the date/time labels.
  final double timeLabelHeight;

  /// The style of date/time labels (on the bottom of the chart).
  final TextStyle timeLabelStyle;

  /// The style of price labels (on the right of the chart).
  final TextStyle priceLabelStyle;

  /// The style of overlay texts. These texts are drawn on top of the
  /// background color specified in [overlayBackgroundColor].
  ///
  /// This appears when user clicks on the chart.
  final TextStyle overlayTextStyle;

  /// The color to use when the `close` price is higher than `open` price.
  final Color priceGainColor;

  /// The color to use when the `close` price is lower than `open` price.
  final Color priceLossColor;

  /// The color of the `volume` bars to use when the `close` price is higher than `open` price.
  final Color volumeGainColor;

  /// The color of the `volume` bars to use when the `close` price is lower than `open` price.
  final Color volumeLossColor;

  /// The style of trend lines. If there are multiple lines, their styles will
  /// be chosen in the order of appearance in this list. If this list is shorter
  /// than the number of trend lines, a default blue paint will be applied.
  final List<Paint> trendLineStyles;

  /// The color of the price grid line.
  final Color priceGridLineColor;

  /// The highlight color. This appears when user clicks on the chart.
  final Color selectionHighlightColor;

  /// The background color of the overlay.
  ///
  /// This appears when user clicks on the chart.
  final Color overlayBackgroundColor;

  /// The style of current price labels (on the right of the chart).
  final CurrentPriceStyle currentPriceStyle;

  /// The color of the grid lines for the volume bars.
  final Color volumeGridLineColor;

  /// The style of volume labels (on the right of the chart).
  final TextStyle volumeLabelStyle;

  /// The style of current volume labels.
  final CurrentVolumeStyle currentVolumeStyle;

  final Logo? logo;

  const ChartStyle({
    this.volumeHeightFactor = 0.2,
    this.priceLabelWidth = 48.0,
    this.timeLabelHeight = 24.0,
    this.timeLabelStyle = const TextStyle(
      fontSize: 16,
      color: Colors.grey,
    ),
    this.priceLabelStyle = const TextStyle(
      fontSize: 12,
      color: Colors.grey,
    ),
    this.overlayTextStyle = const TextStyle(
      fontSize: 16,
      color: Colors.white,
    ),
    this.currentPriceStyle = const CurrentPriceStyle(
      labelStyle: TextStyle(
        fontSize: 12,
        color: Colors.white,
      ),
      rectPadding: 4.0,
      rectRadius: 2.0,
      rectColor: Colors.red,
      lineColor: Colors.red,
    ),
    this.volumeLabelStyle = const TextStyle(
      fontSize: 12,
      color: Colors.grey,
    ),
    this.priceGainColor = Colors.green,
    this.priceLossColor = Colors.red,
    this.volumeGainColor = Colors.grey,
    this.volumeLossColor = Colors.grey,
    this.trendLineStyles = const [],
    this.priceGridLineColor = Colors.grey,
    this.volumeGridLineColor = Colors.grey,
    this.selectionHighlightColor = const Color(0x33757575),
    this.overlayBackgroundColor = const Color(0xEE757575),
    this.currentVolumeStyle = const CurrentVolumeStyle(
      labelStyle: TextStyle(
        fontSize: 12,
        color: Colors.white,
      ),
      rectPadding: 4.0,
      rectRadius: 2.0,
      rectColor: Colors.red,
      offset: Offset(8, 8),
    ),
    this.logo,
  });
}

class CurrentPriceStyle {
  const CurrentPriceStyle({
    required this.labelStyle,
    required this.rectPadding,
    required this.rectRadius,
    required this.rectColor,
    required this.lineColor,
  });

  /// The style of current price labels (on the right of the chart).
  final TextStyle labelStyle;

  /// The padding around the current price rect.
  final double rectPadding;

  /// The radius of the current price rect.
  final double rectRadius;

  /// The color of the current price rect.
  final Color rectColor;

  final Color lineColor;
}

class CurrentVolumeStyle {
  const CurrentVolumeStyle({
    required this.labelStyle,
    required this.rectPadding,
    required this.rectRadius,
    required this.rectColor,
    required this.offset,
  });

  /// The style of current volume labels (on the right of the chart).
  final TextStyle labelStyle;

  /// The padding around the current volume rect.
  final double rectPadding;

  /// The radius of the current volume rect.
  final double rectRadius;

  /// The color of the current volume rect.
  final Color rectColor;

  /// The offset of the current volume rect.
  final Offset offset;
}

class Logo {
  const Logo({
    required this.image,
    required this.percentageOffset,
    this.size,
    this.opacity = 1,
  }) : assert(opacity >= 0 && opacity <= 1);

  final ui.Image image;

  final ui.Size? size;

  final double opacity;

  final Offset percentageOffset;
}
