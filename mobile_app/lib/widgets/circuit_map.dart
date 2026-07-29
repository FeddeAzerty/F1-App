import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/circuit.dart';

/// Live map pinned at the circuit's coordinates. Jolpica doesn't provide
/// track layout images, so this is the "visual" for a circuit - real,
/// pannable/zoomable, and legally clean (OpenStreetMap tiles) instead of a
/// static/borrowed image.
class CircuitMap extends StatelessWidget {
  const CircuitMap({super.key, required this.circuit});

  final Circuit circuit;

  @override
  Widget build(BuildContext context) {
    if (circuit.latitude == null || circuit.longitude == null) {
      return const SizedBox.shrink();
    }

    final point = LatLng(circuit.latitude!, circuit.longitude!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 13.5),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.f1portfolio.mobile_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.flag,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
