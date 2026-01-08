import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A standardized shimmer effect for the Playcado app.
class PlaycadoShimmer extends StatelessWidget {
  const PlaycadoShimmer({required this.child, super.key, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final theme = Theme.of(context);

    // Consistent color mapping for the Organic Black theme
    final baseColor = theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.3,
    );
    final highlightColor = theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.1,
    );

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}
