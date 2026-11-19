import 'package:flutter/material.dart';
import 'screens/home_shell_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init();

  runApp(ParagrafApp(appState: appState));
}

class ParagrafApp extends StatelessWidget {
  final AppState appState;

  const ParagrafApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paragraf v kapse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: HomeShellScreen(appState: appState),
    );
  }
}
