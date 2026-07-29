import 'package:flutter/material.dart';

/// Driver headshot, resolved in priority order:
///   1. A bundled override at `assets/drivers/{driver_ref}.png`, if present
///      (lets you pin a specific image for a driver).
///   2. `photoUrl` - a network image (Wikipedia headshot resolved by the
///      backend, see Driver.resolvedPhotoUrl).
///   3. A generic person icon.
///
/// No driver photos ship with this project; the asset override just exists
/// so you *can* drop one in named by `driver_ref` (e.g.
/// `max_verstappen.png`) and have it win over the network photo.
class DriverAvatar extends StatelessWidget {
  const DriverAvatar({
    super.key,
    required this.driverRef,
    this.photoUrl,
    this.radius = 20,
  });

  final String driverRef;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: Image.asset(
          'assets/drivers/$driverRef.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _networkOrIcon(context),
        ),
      ),
    );
  }

  Widget _networkOrIcon(BuildContext context) {
    final url = photoUrl;
    if (url == null || url.isEmpty) return _icon(context);

    return Image.network(
      url,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      // Top-align: headshots are portrait, so cover-cropping to a circle
      // otherwise cuts off faces at the forehead.
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) => _icon(context),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _icon(context),
    );
  }

  Widget _icon(BuildContext context) => Icon(
    Icons.person,
    size: radius,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
