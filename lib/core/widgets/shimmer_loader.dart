import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A simple block shimmer used as a loading placeholder across list/detail
/// screens (Riverpod's `AsyncValue.when(loading: ...)`).
class ShimmerLoader extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;

  const ShimmerLoader({
    super.key,
    this.height = double.infinity,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE5E7EB),
        highlightColor: const Color(0xFFF3F4F6),
        child: Column(
          children: List.generate(
            4,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
