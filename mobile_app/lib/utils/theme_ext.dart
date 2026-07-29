import 'package:flutter/material.dart';

extension MutedColor on BuildContext {
  /// A muted foreground colour for secondary text (dates, captions,
  /// subtitles) that keeps a legible contrast on both themes - unlike a
  /// hardcoded mid-grey, which is too faint on the light cream background.
  Color get mutedColor => Theme.of(this).brightness == Brightness.dark
      ? Colors.grey.shade400
      : Colors.grey.shade700;
}
