import 'package:flutter/material.dart';

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
