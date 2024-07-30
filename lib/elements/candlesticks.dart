import 'dart:math';
import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:flutter/material.dart';
import 'chart.dart';

/// CustomButton widget definition
class CustomButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? color;
  final double? width;

  const CustomButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 40,
      margin: const EdgeInsets.all(2.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.blue, // Background color
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

/// StatefulWidget that holds Chart's State (index of
/// current position and candles width).
class CandlesticksGraph extends StatefulWidget {
  final List<Candle> candles;

  /// Callback called when the user changes the interval
  final Future<void> Function(String) onIntervalChange;

  final String interval;

  final List<String>? intervals;

  const CandlesticksGraph({
    super.key,
    required this.candles,
    required this.onIntervalChange,
    required this.interval,
    this.intervals,
  });

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

/// [Candlesticks] state
class _CandlesticksState extends State<CandlesticksGraph> {
  /// Index of the newest candle to be displayed
  /// Changes when the user scrolls along the chart
  int index = -10;
  ScrollController scrollController = ScrollController();

  double hoverX = 0.0;
  double hoverY = 0.0;
  bool showInfo = false;

  double lastX = 0;
  int lastIndex = -10;

  void _incrementEnter(PointerEvent details) {
    setState(() {
      showInfo = true;
    });
  }

  void _incrementExit(PointerEvent details) {
    setState(() {
      showInfo = false;
    });
  }

  void _updateLocation(PointerEvent details) {
    setState(() {
      hoverX = details.localPosition.dx;
      hoverY = details.localPosition.dy;
    });
  }

  /// CandleWidth controls the width of the single candles.
  /// Range: [2...10]
  double candleWidth = 0.0;

  bool showIntervals = false;

  @override
  Widget build(BuildContext context) {
    candleWidth = 220 / widget.candles.length;
    if (widget.candles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Default intervals
    List<String> defaultIntervals = ["1m", "5m", "15m", "1h", "4h", "1d", "1w"];
    
    Color rangeButtonBackground =
        widget.candles[0].close - widget.candles[widget.candles.length - 1].close > 0
            ? DarkColorPalette.secondaryGreen
            : DarkColorPalette.secondaryRed;
    Color rangeButtonForeground = Colors.white;
    return Column(
      children: [
        Container(
          color: const Color.fromARGB(255, 47, 98, 23),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              children: [
                CustomButton(
                  onPressed: () {
                    setState(() {
                      candleWidth -= 2;
                      candleWidth = max(candleWidth, 2);
                    });
                  },
                  child: const Icon(
                    Icons.remove,
                    color: DarkColorPalette.grayColor,
                  ),
                ),
                CustomButton(
                  onPressed: () {
                    setState(() {
                      candleWidth += 2;
                      candleWidth = min(candleWidth, 10);
                    });
                  },
                  child: const Icon(
                    Icons.add,
                    color: DarkColorPalette.grayColor,
                  ),
                ),
                CustomButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Center(
                          child: Container(
                            width: 200,
                            color: LightColorPalette.dialogColor,
                            child: Wrap(
                              children: (widget.intervals ?? defaultIntervals)
                                  .map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CustomButton(
                                        width: 50,
                                        color: rangeButtonBackground,
                                        child: Text(
                                          e,
                                          style: TextStyle(
                                            color: rangeButtonForeground,
                                          ),
                                        ),
                                        onPressed: () {
                                          widget.onIntervalChange(e);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    widget.interval,
                    style: const TextStyle(
                      color: DarkColorPalette.grayColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TweenAnimationBuilder(
            tween: Tween(begin: 6.toDouble(), end: candleWidth),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCirc,
            builder: (_, width, __) {
              return Chart(
                onScaleUpdate: (double scale) {
                  setState(() {
                    candleWidth *= scale;
                    candleWidth = min(candleWidth, 10);
                    candleWidth = max(candleWidth, 2);
                  });
                },
                onPanEnd: () {
                  lastIndex = index;
                },
                hoverX: hoverX + (index - lastIndex) * candleWidth,
                hoverY: hoverY,
                onEnter: _incrementEnter,
                onHover: _updateLocation,
                onExit: _incrementExit,
                scrollController: scrollController,
                onHorizontalDragUpdate: (double x) {
                  setState(() {
                    x = x - lastX;
                    index = lastIndex + x ~/ candleWidth;
                    index = max(index, -10);
                    index = min(index, widget.candles.length - 1);
                  });
                  if (index == lastIndex) return;
                  scrollController.jumpTo((index + 10) * candleWidth);
                },
                onPanDown: (double value) {
                  lastX = value;
                  lastIndex = index;
                },
                candleWidth: width as double,
                candles: widget.candles,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}
