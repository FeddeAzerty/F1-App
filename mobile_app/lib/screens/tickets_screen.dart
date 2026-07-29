import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/theme_ext.dart';
import '../widgets/theme_toggle_button.dart';

/// Static outbound links to official F1 ticket vendors. No data integration
/// by design - just curated links, opened in the system browser.
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  static const _vendors = <({String name, String description, String url})>[
    (
      name: 'Formula 1 — Official Tickets',
      description: 'Grandstand and general admission tickets direct from F1.',
      url: 'https://tickets.formula1.com/',
    ),
    (
      name: 'F1 Experiences',
      description: 'Official hospitality, paddock club and travel packages.',
      url: 'https://f1experiences.com/',
    ),
    (
      name: 'Silverstone (British GP)',
      description: 'Book directly with the circuit for the British Grand Prix.',
      url: 'https://www.silverstone.co.uk/events/formula-1',
    ),
    (
      name: 'Circuit de Monaco',
      description: 'Official ticketing for the Monaco Grand Prix.',
      url: 'https://www.formula1monaco.com/',
    ),
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Official vendors',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Links open in your browser. Prices and availability are handled '
            'entirely by each vendor.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.mutedColor),
          ),
          const SizedBox(height: 12),
          for (final v in _vendors)
            Card(
              child: ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: Text(v.name),
                subtitle: Text(v.description),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(v.url),
              ),
            ),
        ],
      ),
    );
  }
}
