import 'package:flutter/material.dart';

/// Placeholder body for screens whose backend integration hasn't been
/// built out yet - keeps them navigable while flagging what they'll show.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
        ),
      ),
    );
  }
}
