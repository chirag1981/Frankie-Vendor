import 'package:flutter/material.dart';
import 'main_nav_screen.dart';
import 'theme/app_theme.dart';

class FrankieVendorApp extends StatelessWidget {
  const FrankieVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Vendor Invoice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavScreen(),
    );
  }
}
