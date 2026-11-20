import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_shell_screen.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('cs_CZ', null);
  final appState = AppState();
  await appState.init();

  runApp(ParagrafApp(appState: appState));
}

class ParagrafApp extends StatefulWidget {
  final AppState appState;

  const ParagrafApp({super.key, required this.appState});

  @override
  State<ParagrafApp> createState() => _ParagrafAppState();
}

class _ParagrafAppState extends State<ParagrafApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {
      _syncTheme();
    });
  }

  void _syncTheme() {
    final sysDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final isDark = widget.appState.themeMode == ThemeMode.dark ||
        (widget.appState.themeMode == ThemeMode.system && sysDark);
    AppColors.isDark = isDark;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        _syncTheme();

        return MaterialApp(
          title: 'Paragraf v kapse',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: widget.appState.themeMode,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            AppColors.isDark = isDark;
            return child!;
          },
          home: HomeShellScreen(appState: widget.appState),
        );
      },
    );
  }
}
