import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'ui/screens/app_bootstrap_screen.dart';

class WriteThatDownApp extends StatelessWidget {
  const WriteThatDownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Write That Down',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppBootstrapScreen(),
    );
  }
}