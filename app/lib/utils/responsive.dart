import 'package:flutter/material.dart';

/// Responsive layout and typography helpers for consistent, fast UI.
class Responsive {
  Responsive._();

  static double _screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) =>
      _screenWidth(context) < 360;

  static bool isMedium(BuildContext context) {
    final w = _screenWidth(context);
    return w >= 360 && w < 600;
  }

  static bool isExpanded(BuildContext context) =>
      _screenWidth(context) >= 600;

  /// Horizontal padding that scales with screen size (capped).
  static double horizontalPadding(BuildContext context) {
    final w = _screenWidth(context);
    if (w < 360) return 16;
    if (w < 600) return 20;
    return 24;
  }

  /// Standard vertical spacing between sections.
  static double sectionSpacing(BuildContext context) =>
      isCompact(context) ? 20 : 28;

  /// Scale factor for large elements (icons, logos).
  static double scale(BuildContext context) {
    final w = _screenWidth(context);
    if (w < 360) return 0.85;
    if (w > 500) return 1.1;
    return 1.0;
  }
}

extension ResponsivePadding on BuildContext {
  EdgeInsets get paddingHorizontal => EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(this),
      );
  EdgeInsets get paddingAll => EdgeInsets.all(Responsive.horizontalPadding(this));
}
