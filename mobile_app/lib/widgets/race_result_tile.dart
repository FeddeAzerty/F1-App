import 'package:flutter/material.dart';

import '../models/race_result.dart';
import '../utils/constructor_colors.dart';
import '../utils/theme_ext.dart';
import 'driver_avatar.dart';

class RaceResultTile extends StatelessWidget {
  const RaceResultTile({super.key, required this.result, this.onTap});

  final RaceResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPodium = result.position != null && result.position! <= 3;
    final secondaryLine = result.finishTime ?? result.status;
    final teamColor = constructorColor(result.constructor.constructorRef);

    return ListTile(
      onTap: onTap,

      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 4, height: 40, color: teamColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 22,
            child: Text(
              result.positionText ?? '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPodium ? Colors.amber.shade600 : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          DriverAvatar(
            driverRef: result.driver.driverRef,
            photoUrl: result.driver.resolvedPhotoUrl,
            radius: 18,
          ),
        ],
      ),
      title: Text(result.driver.fullName),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              result.constructor.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (result.setFastestLap) ...[
            const SizedBox(width: 8),
            Icon(Icons.bolt, size: 14, color: Colors.purple.shade300),
            const SizedBox(width: 2),
            Text(
              result.fastestLapTime ?? 'Fastest lap',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade300,
              ),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${result.points.toStringAsFixed(0)} pts'),
          if (secondaryLine != null)
            Text(
              secondaryLine,
              style: TextStyle(fontSize: 11, color: context.mutedColor),
            ),
        ],
      ),
    );
  }
}
