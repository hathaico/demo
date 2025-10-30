import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer placeholders used for lists/grids and product cards.
class ShimmerProductCard extends StatelessWidget {
  final double borderRadius;
  const ShimmerProductCard({super.key, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return Shimmer.fromColors(
      // shorten the shimmer cycle so the animation appears faster
      period: const Duration(milliseconds: 600),
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image skeleton
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(borderRadius),
                  ),
                ),
              ),
            ),
            // info skeleton
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: double.infinity, color: base),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 80, color: base),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(child: Container(height: 12, color: base)),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 40, color: base),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns a sliver grid of shimmer product cards. Useful in `Sliver` contexts (Home screen).
Widget shimmerSliverGrid({
  required int count,
  required int crossAxisCount,
  double childAspectRatio = 0.7,
}) {
  return SliverGrid(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    delegate: SliverChildBuilderDelegate(
      (context, index) => const ShimmerProductCard(),
      childCount: count,
    ),
  );
}

/// A GridView of shimmer cards for non-sliver contexts (Products screen main loader).
class ShimmerGridView extends StatelessWidget {
  final int count;
  final int crossAxisCount;
  final double childAspectRatio;

  const ShimmerGridView({
    super.key,
    this.count = 8,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (context, index) => const ShimmerProductCard(),
    );
  }
}
