import 'dart:math';

import 'package:candlestick_chart/src/x_axis_offset_details.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

import 'candle_data.dart';
import 'chart_painter.dart';
import 'chart_style.dart';
import 'painter_params.dart';

class CandlestickChart extends StatefulWidget {
  /// The full list of [CandleData] to be used for this chart.
  ///
  /// It needs to have at least 3 data points. If data is sufficiently large,
  /// the chart will default to display the most recent 90 data points when
  /// first opened (configurable with [initialVisibleCandleCount] parameter),
  /// and allow users to freely zoom and pan however they like.
  final List<CandleData> candles;

  /// The default number of data points to be displayed when the chart is first
  /// opened. The default value is 90. If [CandleData] does not have enough data
  /// points, the chart will display all of them.
  final int initialVisibleCandleCount;

  /// If non-null, the style to use for this chart.
  final ChartStyle style;

  /// How the date/time label at the bottom are displayed.
  ///
  /// If null, it defaults to use yyyy-mm format if more than 20 data points
  /// are visible in the current chart window, otherwise it uses mm-dd format.
  final TimeLabelGetter? timeLabel;

  /// How the price labels on the right are displayed.
  ///
  /// If null, it defaults to show 2 digits after the decimal point.
  final PriceLabelGetter? priceLabel;

  /// How the overlay info are displayed, when user touches the chart.
  ///
  /// If null, it defaults to display `date`, `open`, `high`, `low`, `close`
  /// and `volume` fields when user selects a data point in the chart.
  ///
  /// To customize it, pass in a function that returns a Map<String,String>:
  /// ```dart
  /// return {
  ///   "Date": "Customized date string goes here",
  ///   "Open": candle.open?.toStringAsFixed(2) ?? "-",
  ///   "Close": candle.close?.toStringAsFixed(2) ?? "-",
  /// };
  /// ```
  final OverlayInfoGetter? overlayInfo;

  /// An optional event, fired when the user clicks on a candlestick.
  final ValueChanged<CandleData>? onTap;

  /// An optional event, fired when user zooms in/out.
  ///
  /// This provides the width of a candlestick at the current zoom level.
  final ValueChanged<double>? onCandleResize;

  /// Optional event fired when the user moves the chart along the X axis.
  ///
  /// Provides X-axis offset details.
  final ValueChanged<XAxisOffsetDetails>? onXOffsetChanged;

  /// The current price to be displayed on the right side of the chart.
  final double? currentPrice;

  /// Whether to display grid lines in the background.
  final bool enableGridLines;

  /// The positions in percentage where price labels are displayed.
  final List<double>? priceLabelPositions;

  /// The positions in percentage where volume labels are displayed.
  final List<double>? volumeLabelPositions;

  /// The distance between candles, as a percentage of the candle width.
  final double distanceBetweenCandle;

  /// How the volume labels on the right are displayed.
  ///
  /// If null, it defaults to show 2 digits after the decimal point.
  final VolumeLabelGetter? volumeLabel;

  /// The current volume to be displayed on the right side of the chart.
  final double? currentVolume;

  /// The minimum number of visible candles in the chart.
  final int minVisibleCandleCount;

  /// The maximum number of visible candles in the chart.
  final int maxVisibleCandleCount;

  /// The duration of the animation when the chart is updated.
  final Duration animationDuration;

  /// Whether to disable user interaction with the chart.
  /// If true, the chart will not respond to user gestures.
  /// Defaults to false.
  final bool disableInteraction;

  const CandlestickChart({
    Key? key,
    required this.candles,
    this.initialVisibleCandleCount = 90,
    ChartStyle? style,
    this.timeLabel,
    this.priceLabel,
    this.overlayInfo,
    this.onTap,
    this.onCandleResize,
    this.onXOffsetChanged,
    this.currentPrice,
    this.enableGridLines = true,
    this.priceLabelPositions,
    this.distanceBetweenCandle = 0.5,
    this.volumeLabelPositions,
    this.volumeLabel,
    this.currentVolume,
    this.minVisibleCandleCount = 45,
    this.maxVisibleCandleCount = 180,
    this.disableInteraction = false,
    this.animationDuration = const Duration(milliseconds: 300),
  })  : this.style = style ?? const ChartStyle(),
        assert(
            initialVisibleCandleCount >= minVisibleCandleCount &&
                initialVisibleCandleCount <= maxVisibleCandleCount,
            'The initialVisibleCandleCount must be between minVisibleCandleCount and maxVisibleCandleCount'),
        assert(candles.length >= 0,
            "InteractiveChart requires 1 or more CandleData"),
        assert(initialVisibleCandleCount >= 3,
            "initialVisibleCandleCount must be more 3 or more"),
        super(key: key);

  @override
  _CandlestickChartState createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  // The width of an individual bar in the chart.
  late double _candleWidth;

  // The x offset (in px) of current visible chart window,
  // measured against the beginning of the chart.
  // i.e. a value of 0.0 means we are displaying data for the very first day,
  // and a value of 20 * _candleWidth would be skipping the first 20 days.
  late double _startOffset;

  // The position that user is currently tapping, null if user let go.
  Offset? _tapPosition;

  double? _prevChartWidth; // used by _handleResize
  late double _prevCandleWidth;
  late double _prevStartOffset;
  late Offset _initialFocalPoint;
  PainterParams? _prevParams; // used in onTapUp event

  bool _isScalingInProgress = false;

  bool get _canScale => !widget.disableInteraction;

  bool get _canHorizontalDrag =>
      !widget.disableInteraction && !_isScalingInProgress;

  bool get _canTap => !widget.disableInteraction;

  @override
  void didUpdateWidget(covariant CandlestickChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles.length > widget.candles.length) {
      // Reset to initial state if the new widget has fewer candles
      final count = min(
        widget.candles.length,
        widget.initialVisibleCandleCount,
      );

      _candleWidth =
          _prevChartWidth! / max(count, widget.minVisibleCandleCount);
      _startOffset = (widget.candles.length - count) * _candleWidth;
    } else if (oldWidget.candles.length < widget.candles.length) {
      // Increase offset to keep the current position when new candles are added
      final newCandlesCount = widget.candles.length - oldWidget.candles.length;
      _startOffset += newCandlesCount * _candleWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final size = constraints.biggest;
        final w = size.width - widget.style.priceLabelWidth;
        _handleResize(w);

        // Find the visible data range
        final int start = (_startOffset / _candleWidth).floor();
        final int count = (w / _candleWidth).ceil();
        final int end = min((start + count), widget.candles.length);

        final validStart = max(0, min(start, widget.candles.length - 1));
        final validEnd = min(max(end, validStart + 1), widget.candles.length);
        final candlesInRange =
            widget.candles.getRange(validStart, validEnd).toList();

        if (end < widget.candles.length) {
          // Put in an extra item, since it can become visible when scrolling
          final nextItem = widget.candles[end];
          candlesInRange.add(nextItem);
        }

        // If possible, find neighbouring trend line data,
        // so the chart could draw better-connected lines
        final leadingTrends = widget.candles.at(start - 1)?.trends;
        final trailingTrends = widget.candles.at(end + 1)?.trends;

        // Find the horizontal shift needed when drawing the candles.
        // First, always shift the chart by half a candle, because when we
        // draw a line using a thick paint, it spreads to both sides.
        // Then, we find out how much "fraction" of a candle is visible, since
        // when users scroll, they don't always stop at exact intervals.
        final halfCandle = _candleWidth / 2;
        final fractionCandle = _startOffset - start * _candleWidth;
        final xShift = halfCandle - fractionCandle;

        // Calculate min and max among the visible data
        double? highest(CandleData c) {
          if (c.high != null) return c.high;
          if (c.open != null && c.close != null) return max(c.open!, c.close!);
          return c.open ?? c.close;
        }

        double? lowest(CandleData c) {
          if (c.low != null) return c.low;
          if (c.open != null && c.close != null) return min(c.open!, c.close!);
          return c.open ?? c.close;
        }

        final maxPrice =
            candlesInRange.map(highest).whereType<double>().reduce(max);
        final minPrice =
            candlesInRange.map(lowest).whereType<double>().reduce(min);
        final maxVol = candlesInRange
            .map((c) => c.volume)
            .whereType<double>()
            .fold(double.negativeInfinity, max);
        final minVol = candlesInRange
            .map((c) => c.volume)
            .whereType<double>()
            .fold(double.infinity, min);

        final params = PainterParams(
          candles: candlesInRange,
          style: widget.style,
          size: size,
          candleWidth: _candleWidth,
          startOffset: _startOffset,
          maxPrice: maxPrice,
          minPrice: minPrice,
          maxVol: maxVol,
          minVol: minVol,
          xShift: xShift,
          tapPosition: _tapPosition,
          leadingTrends: leadingTrends,
          trailingTrends: trailingTrends,
          currentPrice: widget.currentPrice,
          currentVolume: widget.currentVolume,
          enableGridLines: widget.enableGridLines,
          priceLabelPositions:
              widget.priceLabelPositions ?? const [0.1, 0.3, 0.5, 0.7, 0.9],
          volumeLabelPositions:
              widget.volumeLabelPositions ?? const [0.3, 0.6, 0.9],
          distanceBetweenCandle: widget.distanceBetweenCandle,
        );
        final child = TweenAnimationBuilder(
          tween: PainterParamsTween(
            begin: _prevParams,
            end: params,
          ),
          duration: widget.animationDuration,
          curve: Curves.easeOut,
          builder: (_, PainterParams params, __) {
            _prevParams = params;
            return RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: ChartPainter(
                  params: params,
                  getTimeLabel: widget.timeLabel ?? defaultTimeLabel,
                  getPriceLabel: widget.priceLabel ?? defaultPriceLabel,
                  getOverlayInfo: widget.overlayInfo ?? defaultOverlayInfo,
                  getVolumeLabel: widget.volumeLabel ?? defaultVolumeLabel,
                ),
              ),
            );
          },
        );

        return Listener(
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent) {
              final dy = signal.scrollDelta.dy;
              if (dy.abs() > 0) {
                _onScaleStart(signal.position);
                _onScaleUpdate(
                  dy > 0 ? 0.9 : 1.1,
                  signal.position,
                  w,
                );
              }
            }
          },
          child: GestureDetector(
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            // Tap and hold to view candle details
            onTapDown: (details) {
              if (!_canTap) {
                return;
              }
              setState(() {
                _tapPosition = details.localPosition;
              });
            },
            onTapCancel: () => setState(() => _tapPosition = null),
            onTapUp: (_) {
              if (!_canTap) {
                return;
              }
              // Fire callback event and reset _tapPosition
              if (widget.onTap != null) _fireOnTapEvent();
              setState(() => _tapPosition = null);
            },
            // Pan and zoom
            onScaleStart: (details) => _onScaleStart(details.localFocalPoint),
            onScaleUpdate: (details) {
              _onScaleUpdate(details.scale, details.localFocalPoint, w);
            },
            onScaleEnd: _onScaleEnd,
            child: child,
          ),
        );
      },
    );
  }

  _onScaleStart(Offset focalPoint) {
    if (!_canScale) {
      return;
    }
    _isScalingInProgress = true;
    _prevCandleWidth = _candleWidth;
    _prevStartOffset = _startOffset;
    _initialFocalPoint = focalPoint;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isScalingInProgress = false;
  }

  _onScaleUpdate(double scale, Offset focalPoint, double w) {
    if (!_canScale) {
      return;
    }
    // Handle zoom
    var candleWidth = _prevCandleWidth * scale;

    // Check if the current zoom level is within the allowed range
    final visibleCandles = w / candleWidth;
    if (visibleCandles < widget.minVisibleCandleCount) {
      candleWidth = w / widget.minVisibleCandleCount;
    } else if (visibleCandles > widget.maxVisibleCandleCount) {
      candleWidth = w / widget.maxVisibleCandleCount;
    }
    final clampedScale = candleWidth / _prevCandleWidth;
    var startOffset = _prevStartOffset * clampedScale;
    // Handle pan
    final dx = (focalPoint - _initialFocalPoint).dx * -1;
    startOffset += dx;
    // Adjust pan when zooming
    final double prevCount = w / _prevCandleWidth;
    final double currCount = w / candleWidth;
    final zoomAdjustment = (currCount - prevCount) * candleWidth;
    final focalPointFactor = focalPoint.dx / w;
    startOffset -= zoomAdjustment * focalPointFactor;
    final maxStartOffset = _getMaxStartOffset(w, candleWidth);
    startOffset = startOffset.clamp(0, maxStartOffset);
    // Fire candle width resize event
    if (candleWidth != _candleWidth) {
      widget.onCandleResize?.call(candleWidth);
    }
    // Apply changes
    setState(() {
      widget.onXOffsetChanged?.call(XAxisOffsetDetails(
        offset: startOffset,
        maxOffset: maxStartOffset,
        prevOffset: _prevStartOffset,
      ));
      _candleWidth = candleWidth;
      _startOffset = startOffset;
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!_canHorizontalDrag) {
      return;
    }
    _prevStartOffset = _startOffset;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_canHorizontalDrag) {
      return;
    }
    final dx = details.delta.dx;
    final w = _prevChartWidth!;

    var startOffset = _startOffset - dx;
    final maxStartOffset = _getMaxStartOffset(w, _candleWidth);
    startOffset = startOffset.clamp(0, maxStartOffset);

    setState(() {
      widget.onXOffsetChanged?.call(XAxisOffsetDetails(
        offset: startOffset,
        maxOffset: maxStartOffset,
        prevOffset: _prevStartOffset,
      ));
      _startOffset = startOffset;
      _prevStartOffset = startOffset;
    });
  }

  _handleResize(double w) {
    if (w == _prevChartWidth) return;
    if (_prevChartWidth != null) {
      // Re-clamp when size changes (e.g. screen rotation)
      _candleWidth = _candleWidth.clamp(
        _getMinCandleWidth(w),
        _getMaxCandleWidth(w),
      );
      _startOffset = _startOffset.clamp(
        0,
        _getMaxStartOffset(w, _candleWidth),
      );
    } else {
      // Default zoom level. Defaults to a 90 day chart, but configurable.
      // If data is shorter, we use the whole range.
      final count = min(
        widget.candles.length,
        widget.initialVisibleCandleCount,
      );

      _candleWidth = w / max(count, widget.minVisibleCandleCount);
      // Default show the latest available data, e.g. the most recent 90 days.
      _startOffset = (widget.candles.length - count) * _candleWidth;
    }
    _prevChartWidth = w;
  }

  // The narrowest candle width, i.e. when drawing all available data points.
  double _getMinCandleWidth(double w) => w / widget.candles.length;

  // The widest candle width, e.g. when drawing 14 day chart
  double _getMaxCandleWidth(double w) => w / min(14, widget.candles.length);

  // Max start offset: how far can we scroll towards the end of the chart
  double _getMaxStartOffset(double w, double candleWidth) {
    final count = w / candleWidth; // visible candles in the window
    final start = widget.candles.length - count;
    return max(0, candleWidth * start);
  }

  String defaultTimeLabel(int timestamp, int visibleDataCount) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp)
        .toIso8601String()
        .split("T")
        .first
        .split("-");

    if (visibleDataCount > 20) {
      // If more than 20 data points are visible, we should show year and month.
      return "${date[0]}-${date[1]}"; // yyyy-mm
    } else {
      // Otherwise, we should show month and date.
      return "${date[1]}-${date[2]}"; // mm-dd
    }
  }

  String defaultPriceLabel(double price) => price.toStringAsFixed(2);

  String defaultVolumeLabel(double volume) => volume.toStringAsFixed(2);

  Map<String, String> defaultOverlayInfo(CandleData candle) {
    final date = intl.DateFormat.yMMMd()
        .format(DateTime.fromMillisecondsSinceEpoch(candle.timestamp));
    return {
      "Date": date,
      "Open": candle.open?.toStringAsFixed(2) ?? "-",
      "High": candle.high?.toStringAsFixed(2) ?? "-",
      "Low": candle.low?.toStringAsFixed(2) ?? "-",
      "Close": candle.close?.toStringAsFixed(2) ?? "-",
      "Volume": candle.volume?.asAbbreviated() ?? "-",
    };
  }

  void _fireOnTapEvent() {
    if (_prevParams == null || _tapPosition == null) return;
    final params = _prevParams!;
    final dx = _tapPosition!.dx;
    final selected = params.getCandleIndexFromOffset(dx);
    final candle = params.candles[selected];
    widget.onTap?.call(candle);
  }
}

extension Formatting on double {
  String asPercent() {
    final format = this < 100 ? "##0.00" : "#,###";
    final v = intl.NumberFormat(format, "en_US").format(this);
    return "${this >= 0 ? '+' : ''}$v%";
  }

  String asAbbreviated() {
    if (this < 1000) return this.toStringAsFixed(3);
    if (this >= 1e18) return this.toStringAsExponential(3);
    final s = intl.NumberFormat("#,###", "en_US").format(this).split(",");
    const suffixes = ["K", "M", "B", "T", "Q"];
    return "${s[0]}.${s[1]}${suffixes[s.length - 2]}";
  }
}
