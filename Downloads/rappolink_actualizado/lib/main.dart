import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const RappoLinkApp(),
    ),
  );
}

class RappoLinkApp extends StatelessWidget {
  const RappoLinkApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'RappoLink',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      );
}
