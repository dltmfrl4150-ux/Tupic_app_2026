import 'package:flutter/material.dart';

class HorizontalRail extends StatelessWidget {
  const HorizontalRail({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.separatorWidth = 12,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;
  final double separatorWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(width: separatorWidth),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
