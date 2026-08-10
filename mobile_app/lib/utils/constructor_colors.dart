import 'package:flutter/material.dart';

const Map<String, Color> _constructorColors = {
  'red_bull': Color(0xFF3671C6),
  'ferrari': Color(0xFFE8002D),
  'mercedes': Color(0xFF27F4D2),
  'mclaren': Color(0xFFFF8000),
  'aston_martin': Color(0xFF229971),
  'alpine': Color(0xFFFF87BC),
  'williams': Color(0xFF64C4FF),
  'rb': Color(0xFF6692FF),
  'sauber': Color(0xFF52E252),
  'haas': Color(0xFFB6BABD),
};

Color constructorColor(String constructorRef) =>
    _constructorColors[constructorRef] ?? Colors.grey;
