import 'package:flutter/material.dart';

extension MutedColor on BuildContext {

  Color get mutedColor => Theme.of(this).brightness == Brightness.dark
      ? Colors.grey.shade400
      : Colors.grey.shade700;
}
