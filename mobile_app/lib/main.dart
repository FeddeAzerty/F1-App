import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'providers/favorites_provider.dart';
import 'providers/race_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/adaptive_nav_scaffold.dart';

void main() {
  runApp(const F1PortfolioApp());
}

class F1PortfolioApp extends StatelessWidget {
  const F1PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RaceProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'F1 Portfolio',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.mode,
          home: const AdaptiveNavScaffold(),
        ),
      ),
    );
  }
}
