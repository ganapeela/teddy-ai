import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/candle.dart';
import '../../core/models/market_snapshot.dart';
import '../../core/models/teddy_signal.dart';

class InteractiveCandleChart extends StatefulWidget {
  final List<Candle> candles;
  final MarketSnapshot snapshot;
  final TeddySignal? signal;

  const InteractiveCandleChart({
    Key? key,
    required this.candles,
    required this.snapshot,
    this.signal,
  }) : super(key: key);

  @override
  State<InteractiveCandleChart> createState() => _InteractiveCandleChartState();
}

class _InteractiveCandleChartState extends State<InteractiveCandleChart> {
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _panOffset = 0.0;
  double _basePanOffset = 0.0;
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for candle stream...',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = _scale;
        _basePanOffset = _panOffset;
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_baseScale * details.scale).clamp(0.5, 3.0);
          _panOffset = _basePanOffset + (details.focalPointDelta.dx * 0.8);
          _tapPosition = details.localPoint;
        });
      },
      onScaleEnd: (_) {
        setState(() {
          _tapPosition = null;
        });
      },
      onTapDown: (details) {
        setState(() {
          _tapPosition = details.localPosition;
        });
      },
      onTapUp: (_) {
        setState(() {
          _tapPosition = null;
        });
      },
      child: ClipRect(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CandleChartPainter(
            candles: widget.candles,
            snapshot: widget.snapshot,
            signal: widget.signal,
            scale: _scale,
            panOffset: _panOffset,
            crosshairPos: _tapPosition,
          ),
        ),
      ),
    );
  }
}

class _CandleChartPainter extends CustomPainter {
  final List<Candle> candles;
  final MarketSnapshot snapshot;
  final TeddySignal? signal;
  final double scale;
  final double panOffset;
  final Offset? crosshairPos;

  _CandleChartPainter({
    required this.candles,
    required this.snapshot,
    this.signal,
    required this.scale,
    required this.panOffset,
    this.crosshairPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double rightAxisWidth = 62.0;
    final double bottomAxisHeight = 24.0;
    final Rect chartRect = Rect.fromLTWH(0, 0, size.width - rightAxisWidth, size.height - bottomAxisHeight);

    // Compute price bounds
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;

    for (final c in candles) {
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
    }

    // Include indicators in vertical bounds
    final tech = snapshot.technicals;
    minPrice = min(minPrice, min(tech.vwap, tech.ema20));
    maxPrice = max(maxPrice, max(tech.vwap, tech.ema9));

    // Include Teddy signal levels in bounds if trade active
    if (signal != null && signal!.decision != 'NO_TRADE') {
      if (signal!.stopLossSpot != null) {
        minPrice = min(minPrice, signal!.stopLossSpot!);
        maxPrice = max(maxPrice, signal!.stopLossSpot!);
      }
      if (signal!.spotTrigger != null) {
        maxPrice = max(maxPrice, signal!.spotTrigger!);
      }
    }

    // Include 5% padding
    final double range = (maxPrice - minPrice).abs() == 0 ? 10.0 : (maxPrice - minPrice);
    minPrice -= range * 0.08;
    maxPrice += range * 0.08;
    final double priceSpan = maxPrice - minPrice;

    double priceToY(double price) {
      return chartRect.bottom - ((price - minPrice) / priceSpan * chartRect.height);
    }

    double yToPrice(double y) {
      return minPrice + ((chartRect.bottom - y) / chartRect.height * priceSpan);
    }

    // Background Gridlines
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.5)
      ..strokeWidth = 0.8;

    final textStyle = const TextStyle(color: AppColors.textSecondary, fontSize: 10);
    const int numGridLines = 6;
    for (int i = 0; i <= numGridLines; i++) {
      final y = chartRect.top + (chartRect.height / numGridLines) * i;
      canvas.drawLine(Offset(0, y), Offset(chartRect.right, y), gridPaint);

      // Y-Axis price labels
      final p = yToPrice(y);
      final textSpan = TextSpan(text: p.toStringAsFixed(1), style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(chartRect.right + 6, y - (textPainter.height / 2)));
    }

    // Draw Candlesticks
    final int count = candles.length;
    final double candleWidth = (chartRect.width / max(1, count)) * scale;
    final double spacing = candleWidth * 0.22;
    final double bodyWidth = candleWidth - spacing;

    final bullPaint = Paint()..color = AppColors.green;
    final bearPaint = Paint()..color = AppColors.red;
    final wickPaint = Paint()..strokeWidth = 1.2;

    final List<Offset> vwapPoints = [];
    final List<Offset> ema9Points = [];
    final List<Offset> ema20Points = [];

    for (int i = 0; i < count; i++) {
      final c = candles[i];
      final double x = chartRect.left + (i * candleWidth) + panOffset + (candleWidth / 2);

      if (x < chartRect.left - 20 || x > chartRect.right + 20) continue;

      final double openY = priceToY(c.open);
      final double closeY = priceToY(c.close);
      final double highY = priceToY(c.high);
      final double lowY = priceToY(c.low);

      final isBull = c.close >= c.open;
      final paint = isBull ? bullPaint : bearPaint;

      // Wick
      wickPaint.color = isBull ? AppColors.green : AppColors.red;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // Body
      final top = min(openY, closeY);
      final bottom = max(openY, closeY);
      final rect = Rect.fromLTWH(x - (bodyWidth / 2), top, bodyWidth, max(1.5, bottom - top));
      canvas.drawRect(rect, paint);
    }

    // Indicators: VWAP line (Amber), 9 EMA (Cyan), 20 EMA (Purple)
    _drawHorizontalIndicator(
      canvas, chartRect, priceToY(tech.vwap),
      AppColors.vwapColor, 'VWAP ${tech.vwap.toStringAsFixed(1)}',
    );
    _drawHorizontalIndicator(
      canvas, chartRect, priceToY(tech.ema9),
      AppColors.ema9Color, '9 EMA',
    );
    _drawHorizontalIndicator(
      canvas, chartRect, priceToY(tech.ema20),
      AppColors.ema20Color, '20 EMA',
    );

    // Max Call OI (Resistance) & Max Put OI (Support) lines
    final opt = snapshot.optionAnalytics;
    if (opt.maxCallOiStrike >= minPrice && opt.maxCallOiStrike <= maxPrice) {
      _drawDashedHorizontal(
        canvas, chartRect, priceToY(opt.maxCallOiStrike),
        AppColors.callWallColor, 'Max Call OI ${opt.maxCallOiStrike.toInt()}',
      );
    }
    if (opt.maxPutOiStrike >= minPrice && opt.maxPutOiStrike <= maxPrice) {
      _drawDashedHorizontal(
        canvas, chartRect, priceToY(opt.maxPutOiStrike),
        AppColors.putWallColor, 'Max Put OI ${opt.maxPutOiStrike.toInt()}',
      );
    }

    // Auto-drawn Teddy AI Trade Zones (Entry, SL, Targets)
    if (signal != null && signal!.decision != 'NO_TRADE') {
      _drawTeddyTradeOverlays(canvas, chartRect, priceToY);
    }

    // Crosshair inspection
    if (crosshairPos != null && chartRect.contains(crosshairPos!)) {
      _drawCrosshair(canvas, chartRect, crosshairPos!, yToPrice(crosshairPos!.dy));
    }
  }

  void _drawHorizontalIndicator(Canvas canvas, Rect bounds, double y, Color color, String label) {
    if (y < bounds.top || y > bounds.bottom) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), paint);

    final span = TextSpan(
      text: label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(bounds.left + 6, y - tp.height - 2));
  }

  void _drawDashedHorizontal(Canvas canvas, Rect bounds, double y, Color color, String label) {
    if (y < bounds.top || y > bounds.bottom) return;
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 1.0;

    double x = bounds.left;
    while (x < bounds.right) {
      canvas.drawLine(Offset(x, y), Offset(min(x + 5, bounds.right), y), paint);
      x += 9;
    }

    final span = TextSpan(
      text: label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(bounds.right - tp.width - 6, y - tp.height - 2));
  }

  void _drawTeddyTradeOverlays(Canvas canvas, Rect bounds, double Function(double) priceToY) {
    final spotTrigger = signal!.spotTrigger;
    final spotSl = signal!.stopLossSpot;

    // Spot Trigger Line (Cyan)
    if (spotTrigger != null) {
      final y = priceToY(spotTrigger);
      _drawDashedHorizontal(canvas, bounds, y, AppColors.cyan, 'TRIGGER: ₹${spotTrigger.toStringAsFixed(1)}');
    }

    // Spot SL Line (Crimson Red)
    if (spotSl != null) {
      final y = priceToY(spotSl);
      _drawDashedHorizontal(canvas, bounds, y, AppColors.red, 'SL (SPOT): ₹${spotSl.toStringAsFixed(1)}');
    }

    // Shaded Entry / Target Zone highlight
    if (spotTrigger != null && spotSl != null) {
      final yTop = min(priceToY(spotTrigger), priceToY(spotSl));
      final yBottom = max(priceToY(spotTrigger), priceToY(spotSl));
      final zonePaint = Paint()
        ..color = (signal!.decision == 'BUY_CE' ? AppColors.green : AppColors.red).withOpacity(0.08);
      canvas.drawRect(Rect.fromLTRB(bounds.left, yTop, bounds.right, yBottom), zonePaint);
    }
  }

  void _drawCrosshair(Canvas canvas, Rect bounds, Offset pos, double price) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.7)
      ..strokeWidth = 0.8;

    // Vertical line
    canvas.drawLine(Offset(pos.dx, bounds.top), Offset(pos.dx, bounds.bottom), paint);
    // Horizontal line
    canvas.drawLine(Offset(bounds.left, pos.dy), Offset(bounds.right, pos.dy), paint);

    // Price badge on right axis
    final badgePaint = Paint()..color = AppColors.surfaceLight;
    final badgeRect = Rect.fromLTWH(bounds.right + 2, pos.dy - 10, 58, 20);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)), badgePaint);

    final span = TextSpan(
      text: price.toStringAsFixed(1),
      style: const TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.bold),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(bounds.right + 6, pos.dy - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _CandleChartPainter oldDelegate) {
    return true;
  }
}
