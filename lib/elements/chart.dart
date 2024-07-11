import 'dart:math';
import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/time_row.dart';
import 'package:candlesticks/src/widgets/dash_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:candlesticks/src/constant/scales.dart';
import 'package:swipe/elements/price_column.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class Chart extends StatelessWidget {
  /// onScaleUpdate callback
  /// called when user scales chart using buttons or scale gesture
  final Function onScaleUpdate;

  /// scrollController controlls the horizontal time row
  final ScrollController scrollController;

  /// onHorizontalDragUpdate
  /// callback calls when user scrolls horizontally along the chart
  final Function onHorizontalDragUpdate;

  /// candleWidth controls the width of the single candles.
  /// range: [2...10]
  final double candleWidth;

  /// list of all candles to display in chart
  final List<Candle> candles;

  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  final int index;

  final void Function(PointerEvent) onEnter;

  final void Function(PointerEvent) onHover;

  final void Function(PointerEvent) onExit;

  final double hoverX;
  final double hoverY;

  final void Function(double) onPanDown;
  final void Function() onPanEnd;

  const Chart({super.key, 
    required this.onScaleUpdate,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
    required this.scrollController,
    required this.onEnter,
    required this.onExit,
    required this.onHover,
    required this.hoverX,
    required this.onPanDown,
    required this.onPanEnd,
    required this.hoverY,
  });

  double log10(num x) => log(x) / ln10;

  double getRoof(double number) {
    int log = log10(number).floor();
    return (number ~/ pow(10, log) + 1) * pow(10, log).toDouble();
  }

  String priceToString(double price) {
    int log = log10(price).floor();
    if (log > 9) {
      return "${price ~/ 1000000000}B";
    } else if (log > 6)
      return "${price ~/ 1000000}M";
    else if (log > 3)
      return "${price ~/ 1000}K";
    else
      return price.toStringAsFixed(2);
  }

  String numberFormat(int value) {
    return "${value < 10 ? 0 : ""}$value";
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double high = 0;
        double low = double.infinity;
        for (int i = 0;
        (i + 1) * candleWidth < constraints.maxWidth - 50;
        i++) {
          if (i + index >= candles.length || i + index < 0) continue;
          low = min(candles[i + index].low, low);
          high = max(candles[i + index].high, high);
        }
        double tileHeight = 0;
        int scaleIndex = 0;
        final maxHeight = constraints.maxHeight - 20;
        double chartHeight = maxHeight  - 40;
        for (int i = 0; i < kAllGalleryTextScaleValues.length; i++) {
          double? currentScale = kAllGalleryTextScaleValues[i].scale;
          if (currentScale != null) {
          double newHigh = ((high ~/ currentScale + 1) * currentScale).toDouble();
          double newLow = ((low ~/ currentScale) * currentScale).toDouble();
          double range = newHigh - newLow;
          if (chartHeight / (range / currentScale) > 30) {
            tileHeight = chartHeight / (range / currentScale);
            scaleIndex = i;
            break;
          }
        }
        if (currentScale != null) {
        high =
            ((high ~/ currentScale + 1) * currentScale).toDouble();
        low = ((low ~/ currentScale) * currentScale).toDouble();

        double volumeHigh = 0;
        for (int i = 0;
        (i + 1) * candleWidth < constraints.maxWidth - 50;
        i++) {
          if (i + index >= candles.length || i + index < 0) continue;
          volumeHigh = max(candles[i + index].volume, volumeHigh);
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: low, end: high),
          duration: const Duration(milliseconds: 200),
          builder: (context, high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: low, end: low),
              duration: const Duration(milliseconds: 200),
              builder: (context, low, _) {
                int i = min(
                  max((constraints.maxWidth - 50 - hoverX) ~/ candleWidth + index, 0),
                  candles.length - 2
                );
                return Container(
                  color: const Color(0xff0f0f0f),
                  child: Stack(
                    children: [
                      TimeRow(
                        indicatorX: hoverX,
                        candles: candles,
                        ScrollController: scrollController,
                        candleWidth: candleWidth,
                        indicatorTime: candles[i].date, 
                        index: index,
                      ),
                      Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                PriceColumn(
                                  tileHeight: tileHeight,
                                  high: high as double,
                                  scaleIndex: scaleIndex,
                                  width: constraints.maxWidth,
                                  height: maxHeight,
                                ),
                                AnimatedPositioned(
                                  duration: const Duration(microseconds: 300),
                                  right: 0,
                                  top: maxHeight -
                                      30 -
                                      ((candles[index >= 0 ? index : 0].close -
                                          (low as double)) /
                                          (high - low)) *
                                          (maxHeight - 40),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: constraints.maxWidth - 50,
                                        height: 0.3,
                                        color: DarkColorPalette.grayColor,
                                      ),
                                      Container(
                                        color: candles[index >= 0 ? index : 0]
                                            .close <=
                                            candles[index >= 0 ? index : 0]
                                                .open
                                            ? DarkColorPalette.secondaryRed
                                            : DarkColorPalette.secondaryGreen,
                                        width: 50,
                                        height: 20,
                                        child: Center(
                                          child: Text(
                                            candles[index >= 0 ? index : 0]
                                                .close.toStringAsFixed(2),
                                            style: TextStyle(
                                              color: DarkColorPalette.grayColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.symmetric(
                                            vertical: BorderSide(
                                              color: LightColorPalette.grayColor,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          child: CandleStickWidget(
                                            candles: candles,
                                            candleWidth: candleWidth,
                                            index: index,
                                            high: high,
                                            low: low, 
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 50,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                      Positioned(
                        top: hoverY - 10,
                        child: Row(
                          children: [
                            DashLine(
                              length: constraints.maxWidth - 50,
                              color: LightColorPalette.grayColor,
                              direction: Axis.horizontal,
                              thickness: 1.5,
                            ),
                            Container(
                              color: DarkColorPalette.dialogColor,
                              width: 50,
                              height: 20,
                              child: Center(
                                child: Text(
                                  hoverY < maxHeight
                                      ? (high -
                                      (hoverY - 20) /
                                          (maxHeight * 0.75 - 40) *
                                          (high - low))
                                      .toStringAsFixed(2)
                                      : priceToString(getRoof(volumeHigh) *
                                      (1 -
                                          (hoverY - maxHeight * 0.75 - 10) /
                                              (maxHeight * 0.25 - 10))),
                                  style: TextStyle(
                                    color: LightColorPalette.grayColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: hoverX,
                        child: Column(
                          children: [
                            DashLine(
                              length: constraints.maxHeight - 20,
                              color: LightColorPalette.grayColor,
                              direction: Axis.vertical,
                              thickness: 1.5,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 50, bottom: 20),
                        child: MouseRegion(
                          onEnter: onEnter,
                          onHover: onHover,
                          onExit: onExit,
                          child: GestureDetector(
                            onPanUpdate: (update) {
                              onHorizontalDragUpdate(update.localPosition.dx);
                            },
                            onPanEnd: (update) {
                              onPanEnd();
                            },
                            onPanDown: (update) {
                              onPanDown(update.localPosition.dx);
                            },
                            child: Container(
                              color: const Color.fromARGB(1, 255, 255, 255),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      }
    }
  });
}}