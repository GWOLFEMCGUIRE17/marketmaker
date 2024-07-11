import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/theme/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/src/constant/scales.dart';

class PriceColumn extends StatelessWidget {
  const PriceColumn({
    super.key,
    required this.tileHeight,
    required this.high,
    required this.scaleIndex,
    required this.width,
    required this.height,
  });

  final double tileHeight;
  final double high;
  final int scaleIndex;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      top: 20 - tileHeight / 2,
      child: SizedBox(
        height: height,
        width: width,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 100,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: tileHeight,
              child: Center(
                child: Row(
                  children: [
                    Container(
                      width: width - 50,
                      height: 0.3,
                      color: DarkColorPalette.grayColor,
                    ),
                    Text(
                      "-${(high - kAllGalleryTextScaleValues[scaleIndex].scale! * index).toStringAsFixed(2)}",
                      style: TextStyle(
                        color: DarkColorPalette.grayColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
