import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AerostarEdgeApp());
}

class AerostarEdgeApp extends StatefulWidget {
  const AerostarEdgeApp({super.key});

  @override
  State<AerostarEdgeApp> createState() => _AerostarEdgeAppState();
}

class _AerostarEdgeAppState extends State<AerostarEdgeApp> {
  late final AppState _appState;
  late final GoRouter _router;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _appState = AppState()..bootstrap();
    _router = buildRouter(_appState, _scaffoldMessengerKey);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appState,
      child: MaterialApp.router(
        title: 'Aerostar Edge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        routerConfig: _router,
        // GlobalCupertinoLocalizations isn't included by MaterialApp's own
        // defaults — needed for CupertinoDatePicker (the wheel-style date
        // picker), which throws on build without it.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
