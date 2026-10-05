import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/controller.dart';
import 'data/repository.dart';
import 'screens/child_shell.dart';
import 'screens/onboarding.dart';
import 'services/audio.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE');
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final controller = AppController(SqliteRepository());
  await controller.init();
  runApp(FluffsApp(controller: controller));
}

class FluffsApp extends StatefulWidget {
  const FluffsApp({super.key, required this.controller});
  final AppController controller;
  @override
  State<FluffsApp> createState() => _FluffsAppState();
}

class _FluffsAppState extends State<FluffsApp> with WidgetsBindingObserver {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => widget.controller.refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refresh();
    } else {
      FluffAudio.instance.stop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fluffs Sternenwelt',
    debugShowCheckedModeBanner: false,
    theme: fluffTheme(),
    locale: const Locale('de', 'DE'),
    supportedLocales: const [Locale('de', 'DE')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        FluffAudio.instance.enabled = widget.controller.data.sound;
        if (widget.controller.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (widget.controller.error != null &&
            widget.controller.data.children.isEmpty) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.controller.error!),
                    const SizedBox(height: 16),
                    GlossyButton(
                      'Erneut versuchen',
                      onPressed: widget.controller.init,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return widget.controller.data.children.isEmpty
            ? Onboarding(controller: widget.controller)
            : ChildShell(controller: widget.controller);
      },
    ),
  );
}
