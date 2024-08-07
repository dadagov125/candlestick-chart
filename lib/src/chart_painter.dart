import 'dart:math';

import 'package:flutter/material.dart';

import 'candle_data.dart';
import 'painter_params.dart';

typedef TimeLabelGetter = String Function(int timestamp, int visibleDataCount);
typedef PriceLabelGetter = String Function(double price);
typedef OverlayInfoGetter = Map<String, String> Function(CandleData candle);
typedef VolumeLabelGetter = String Function(double volume);

class ChartPainter extends CustomPainter {
  final PainterParams params;
  final TimeLabelGetter getTimeLabel;
  final PriceLabelGetter getPriceLabel;
  final OverlayInfoGetter getOverlayInfo;
  final VolumeLabelGetter getVolumeLabel;

  ChartPainter({
    required this.params,
    required this.getTimeLabel,
    required this.getPriceLabel,
    required this.getOverlayInfo,
    required this.getVolumeLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw time labels (dates) & price labels
    _drawTimeLabels(canvas, params);
    _drawPriceGridAndLabels(canvas, params);
    _drawVolumeGridAndLabels(canvas, params);
    _drawCurrentPriceLabel(canvas, params);
    _drawCurrentPriceLine(canvas, params);
    _drawCurrentVolumeLabel(canvas, params);

    // Draw prices, volumes & trend line
    canvas.save();
    canvas.clipRect(Offset.zero & Size(params.chartWidth, params.chartHeight));
    // canvas.drawRect(
    //   // apply yellow tint to clipped area (for debugging)
    //   Offset.zero & Size(params.chartWidth, params.chartHeight),
    //   Paint()..color = Colors.yellow[100]!,
    // );
    canvas.translate(params.xShift, 0);
    for (int i = 0; i < params.candles.length; i++) {
      _drawSingleDay(canvas, params, i);
    }
    canvas.restore();

    _drawLogo(canvas, params);
    // Draw tap highlight & overlay
    if (params.tapPosition != null) {
      if (params.tapPosition!.dx < params.chartWidth) {
        _drawTapHighlightAndOverlay(canvas, params);
      }
    }
  }

  void _drawTimeLabels(canvas, PainterParams params) {
    // We draw one time label per 90 pixels of screen width
    final lineCount = params.chartWidth ~/ 90;
    final gap = 1 / (lineCount + 1);
    for (int i = 1; i <= lineCount; i++) {
      double x = i * gap * params.chartWidth;
      final index = params.getCandleIndexFromOffset(x);
      if (index < params.candles.length) {
        final candle = params.candles[index];
        final visibleDataCount = params.candles.length;
        final timeTp = TextPainter(
          text: TextSpan(
            text: getTimeLabel(candle.timestamp, visibleDataCount),
            style: params.style.timeLabelStyle,
          ),
        )
          ..textDirection = TextDirection.ltr
          ..layout();

        // Align texts towards vertical bottom
        final topPadding = params.style.timeLabelHeight - timeTp.height;
        timeTp.paint(
          canvas,
          Offset(x - timeTp.width / 2, params.chartHeight + topPadding),
        );
      }
    }
  }

  void _drawPriceGridAndLabels(canvas, PainterParams params) {
    for (final v in params.priceLabelPositions) {
      final y = (params.maxPrice - params.minPrice) * v + params.minPrice;

      if (params.enableGridLines) {
        canvas.drawLine(
          Offset(0, params.fitPrice(y)),
          Offset(params.chartWidth, params.fitPrice(y)),
          Paint()
            ..strokeWidth = 0.5
            ..color = params.style.priceGridLineColor,
        );
      }
      final priceTp = TextPainter(
        text: TextSpan(
          text: getPriceLabel(y),
          style: params.style.priceLabelStyle,
        ),
      )
        ..textDirection = TextDirection.ltr
        ..layout();
      priceTp.paint(
          canvas,
          Offset(
            params.chartWidth + 4,
            params.fitPrice(y) - priceTp.height / 2,
          ));
    }
  }

  void _drawVolumeGridAndLabels(canvas, PainterParams params) {
    for (final v in params.volumeLabelPositions) {
      final y = (params.maxVol - params.minVol) * v + params.minVol;

      if (params.enableGridLines) {
        canvas.drawLine(
          Offset(0, params.fitVolume(y)),
          Offset(params.chartWidth, params.fitVolume(y)),
          Paint()
            ..strokeWidth = 0.5
            ..color = params.style.volumeGridLineColor,
        );
      }
      final volumeTp = TextPainter(
        text: TextSpan(
          text: getVolumeLabel(y),
          style: params.style.volumeLabelStyle,
        ),
      )
        ..textDirection = TextDirection.ltr
        ..layout();
      volumeTp.paint(
          canvas,
          Offset(
            params.chartWidth + 4,
            params.fitVolume(y) - volumeTp.height / 2,
          ));
    }
  }

  void _drawCurrentPriceLabel(Canvas canvas, PainterParams params) {
    final currentPrice = params.currentPrice;
    if (currentPrice == null) {
      return;
    }
    final priceTp = TextPainter(
      text: TextSpan(
        text: getPriceLabel(currentPrice),
        style: params.style.currentPriceStyle.labelStyle,
      ),
    )
      ..textDirection = TextDirection.ltr
      ..layout();

    final dx = params.chartWidth + 4;
    final dy =
        params.fitPrice(currentPrice).clamp(0, params.priceHeight).toDouble() -
            priceTp.height / 2;

    final padding = params.style.currentPriceStyle.rectPadding;
    final radius = params.style.currentPriceStyle.rectRadius;
    final rectColor = params.style.currentPriceStyle.rectColor;

    final rect = Rect.fromLTWH(
        dx, dy, priceTp.width + 2 * padding, priceTp.height + 2 * padding);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = rectColor);

    priceTp.paint(canvas, Offset(dx + padding, dy + padding));
  }

  void _drawCurrentPriceLine(Canvas canvas, PainterParams params) {
    final currentPrice = params.currentPrice;
    if (currentPrice == null) {
      return;
    }
    final paint = Paint()
      ..color = params.style.currentPriceStyle.lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dashWidth = 2.0;
    final dashSpace = 2.0;
    double startX = 0;
    final clampedPrice =
    params.fitPrice(currentPrice).clamp(0, params.priceHeight).toDouble();
    while (startX < params.chartWidth) {
      canvas.drawLine(
        Offset(startX, clampedPrice),
        Offset(startX + dashWidth, clampedPrice),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  void _drawCurrentVolumeLabel(Canvas canvas, PainterParams params) {
    final currentVolume = params.currentVolume;

    if (currentVolume == null) {
      return;
    }

    final volumeTp = TextPainter(
      text: TextSpan(
        text: getVolumeLabel(currentVolume),
        style: params.style.currentVolumeStyle.labelStyle,
      ),
    )
      ..textDirection = TextDirection.ltr
      ..layout();

    final volumeHeight = params.volumeHeight;
    final chartHeight = params.chartHeight;

    final dx = params.style.currentVolumeStyle.offset.dx;
    final dy = params.style.currentVolumeStyle.offset.dy +
        (chartHeight - volumeHeight);

    final padding = params.style.currentVolumeStyle.rectPadding;
    final radius = params.style.currentVolumeStyle.rectRadius;
    final rectColor = params.style.currentVolumeStyle.rectColor;

    final rect = Rect.fromLTWH(
        dx, dy, volumeTp.width + 2 * padding, volumeTp.height + 2 * padding);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = rectColor);

    volumeTp.paint(canvas, Offset(dx + padding, dy + padding));
  }

  void _drawSingleDay(canvas, PainterParams params, int i) {
    final candle = params.candles[i];
    final candleWidth = params.candleWidth;
    final distanceBetweenCandle = params.distanceBetweenCandle;
    final thickWidth =
        max(candleWidth * distanceBetweenCandle, distanceBetweenCandle);
    final thinWidth = max(thickWidth * 0.2, 0.2);
    final x = i * candleWidth;

    // Draw price bar
    final open = candle.open;
    final close = candle.close;
    final high = candle.high;
    final low = candle.low;
    if (open != null && close != null) {
      final color = open > close
          ? params.style.priceLossColor
          : params.style.priceGainColor;
      canvas.drawLine(
        Offset(x, params.fitPrice(open)),
        Offset(x, params.fitPrice(close)),
        Paint()
          ..strokeWidth = thickWidth
          ..color = color,
      );
      if (high != null && low != null) {
        canvas.drawLine(
          Offset(x, params.fitPrice(high)),
          Offset(x, params.fitPrice(low)),
          Paint()
            ..strokeWidth = thinWidth
            ..color = color,
        );
      }
    }
    // Draw volume bar
    final volume = candle.volume;
    if (volume != null) {
      final color = open != null && close != null && open > close
          ? params.style.volumeLossColor
          : params.style.volumeGainColor;
      canvas.drawLine(
        Offset(x, params.chartHeight),
        Offset(x, params.fitVolume(volume)),
        Paint()
          ..strokeWidth = thickWidth
          ..color = color,
      );
    }
    // Draw trend line
    for (int j = 0; j < candle.trends.length; j++) {
      final trendLinePaint = params.style.trendLineStyles.at(j) ??
          (Paint()
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round
            ..color = Colors.blue);

      final pt = candle.trends.at(j); // current data point
      final prevPt = params.candles.at(i - 1)?.trends.at(j);
      if (pt != null && prevPt != null) {
        canvas.drawLine(
          Offset(x - candleWidth, params.fitPrice(prevPt)),
          Offset(x, params.fitPrice(pt)),
          trendLinePaint,
        );
      }
      if (i == 0) {
        // In the front, draw an extra line connecting to out-of-window data
        if (pt != null && params.leadingTrends?.at(j) != null) {
          canvas.drawLine(
            Offset(
                x - candleWidth, params.fitPrice(params.leadingTrends!.at(j)!)),
            Offset(x, params.fitPrice(pt)),
            trendLinePaint,
          );
        }
      } else if (i == params.candles.length - 1) {
        // At the end, draw an extra line connecting to out-of-window data
        if (pt != null && params.trailingTrends?.at(j) != null) {
          canvas.drawLine(
            Offset(x, params.fitPrice(pt)),
            Offset(
              x + candleWidth,
              params.fitPrice(params.trailingTrends!.at(j)!),
            ),
            trendLinePaint,
          );
        }
      }
    }
  }

  void _drawTapHighlightAndOverlay(canvas, PainterParams params) {
    final pos = params.tapPosition!;
    final i = params.getCandleIndexFromOffset(pos.dx);
    final candle = params.candles[i];
    canvas.save();
    canvas.translate(params.xShift, 0.0);
    // Draw highlight bar (selection box)
    canvas.drawLine(
        Offset(i * params.candleWidth, 0.0),
        Offset(i * params.candleWidth, params.chartHeight),
        Paint()
          ..strokeWidth = max(params.candleWidth * 0.88, 1.0)
          ..color = params.style.selectionHighlightColor);
    canvas.restore();
    // Draw info pane
    _drawTapInfoOverlay(canvas, params, candle);
  }

  void _drawTapInfoOverlay(canvas, PainterParams params, CandleData candle) {
    final xGap = 8.0;
    final yGap = 4.0;

    TextPainter makeTP(String text) => TextPainter(
          text: TextSpan(
            text: text,
            style: params.style.overlayTextStyle,
          ),
        )
          ..textDirection = TextDirection.ltr
          ..layout();

    final info = getOverlayInfo(candle);
    if (info.isEmpty) return;
    final labels = info.keys.map((text) => makeTP(text)).toList();
    final values = info.values.map((text) => makeTP(text)).toList();

    final labelsMaxWidth = labels.map((tp) => tp.width).reduce(max);
    final valuesMaxWidth = values.map((tp) => tp.width).reduce(max);
    final panelWidth = labelsMaxWidth + valuesMaxWidth + xGap * 3;
    final panelHeight = max(
          labels.map((tp) => tp.height).reduce((a, b) => a + b),
          values.map((tp) => tp.height).reduce((a, b) => a + b),
        ) +
        yGap * (values.length + 1);

    // Shift the canvas, so the overlay panel can appear near touch position.
    canvas.save();
    final pos = params.tapPosition!;
    final fingerSize = 32.0; // leave some margin around user's finger
    double dx, dy;
    assert(params.size.width >= panelWidth, "Overlay panel is too wide.");
    if (pos.dx <= params.size.width / 2) {
      // If user touches the left-half of the screen,
      // we show the overlay panel near finger touch position, on the right.
      dx = pos.dx + fingerSize;
    } else {
      // Otherwise we show panel on the left of the finger touch position.
      dx = pos.dx - panelWidth - fingerSize;
    }
    dx = dx.clamp(0, params.size.width - panelWidth);
    dy = pos.dy - panelHeight - fingerSize;
    if (dy < 0) dy = 0.0;
    canvas.translate(dx, dy);

    // Draw the background for overlay panel
    canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & Size(panelWidth, panelHeight),
          Radius.circular(8),
        ),
        Paint()..color = params.style.overlayBackgroundColor);

    // Draw texts
    var y = 0.0;
    for (int i = 0; i < labels.length; i++) {
      y += yGap;
      final rowHeight = max(labels[i].height, values[i].height);
      // Draw labels (left align, vertical center)
      final labelY = y + (rowHeight - labels[i].height) / 2; // vertical center
      labels[i].paint(canvas, Offset(xGap, labelY));

      // Draw values (right align, vertical center)
      final leading = valuesMaxWidth - values[i].width; // right align
      final valueY = y + (rowHeight - values[i].height) / 2; // vertical center
      values[i].paint(
        canvas,
        Offset(labelsMaxWidth + xGap * 2 + leading, valueY),
      );
      y += rowHeight;
    }

    canvas.restore();
  }

  void _drawLogo(Canvas canvas, PainterParams params) {
    final logo = params.style.logo;

    if (logo == null) {
      return;
    }

    final position = logo.percentageOffset;
    final left = params.chartWidth * position.dx;
    final top = params.chartHeight * position.dy;
    final image = logo.image;
    final width = (logo.size?.width ?? image.width).toDouble();
    final height = (logo.size?.height ?? image.height).toDouble();
    final sourceRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final paint = Paint();
    paint.color = Color.fromRGBO(255, 255, 255, logo.opacity);
    final destinationRect = Rect.fromLTWH(left, top, width, height);
    canvas.drawImageRect(image, sourceRect, destinationRect, paint);
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) =>
      params.shouldRepaint(oldDelegate.params);
}

extension ElementAtOrNull<E> on List<E> {
  E? at(int index) {
    if (index < 0 || index >= length) return null;
    return elementAt(index);
  }
}
