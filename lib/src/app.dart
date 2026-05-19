import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

class KokoShotsApp extends StatelessWidget {
  const KokoShotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KokoShots',
      debugShowCheckedModeBanner: false,
      theme: buildKokoTheme(),
      home: const AppShell(),
    );
  }
}
