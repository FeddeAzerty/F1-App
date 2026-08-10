import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/circuit_track_maps.dart';

class CircuitTrackDiagram extends StatelessWidget {
  const CircuitTrackDiagram({super.key, required this.circuitRef});

  final String circuitRef;

  static bool hasDiagram(String circuitRef) =>
      trackMapAssetFor(circuitRef) != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = trackMapAssetFor(circuitRef, dark: isDark);
    if (asset == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : const Color(0xFFF5F1EC),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: SvgPicture.asset(asset, fit: BoxFit.contain),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Track data © f1db, CC BY 4.0',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
