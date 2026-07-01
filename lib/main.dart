import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/models/video_file.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/intent_channel.dart';
import 'data/services/device_channel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();

  // Smart default for hardware decode: ON for real devices (better
  // performance/battery), OFF on emulators like BlueStacks (which render a
  // frozen frame with hardware decode). Only applied when the user hasn't
  // explicitly chosen — a manual Settings toggle is always respected.
  if (!prefs.containsKey(AppConstants.keyHardwareDecode)) {
    final emulator = await DeviceChannel.isLikelyEmulator();
    await prefs.setBool(AppConstants.keyHardwareDecode, !emulator);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const Manzar(),
    ),
  );

  _wireOpenWithIntents();
}

/// Route "Open with Manzar" and shared video links into the right screen.
void _wireOpenWithIntents() {
  VideoFile videoFromUri(String uri) {
    final decoded = Uri.decodeComponent(uri);
    final name = decoded.split(RegExp(r'[/:]')).last;
    return VideoFile(
      id: 'intent_${DateTime.now().millisecondsSinceEpoch}',
      title: name.isEmpty ? 'External video' : name,
      path: uri,
      duration: Duration.zero,
      size: 0,
      dateAdded: DateTime.now(),
      mimeType: 'video/*',
    );
  }

  void handleUri(String uri) {
    final watchId = _extractWatchId(uri);
    if (watchId != null) {
      appRouter.push('/watch/$watchId');
    } else {
      appRouter.push('/player', extra: videoFromUri(uri));
    }
  }

  IntentChannel.installHandler();
  IntentChannel.onNewUri = handleUri;

  // Cold start: wait for the first frame so the router is mounted
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final uri = await IntentChannel.getInitialUri();
    if (uri != null) handleUri(uri);
  });
}

/// Extracts the video ID from a shared link like:
/// https://manzar-links.pages.dev/watch/abc123
String? _extractWatchId(String uri) {
  try {
    final parsed = Uri.parse(uri);
    final segments = parsed.pathSegments;
    if (segments.length >= 2 && segments[segments.length - 2] == 'watch') {
      final id = segments.last;
      return id.isNotEmpty ? id : null;
    }
  } catch (_) {}
  return null;
}

class Manzar extends ConsumerWidget {
  const Manzar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final accent = settings.accentColor;

    final lightTheme = AppTheme.light(accent);
    final darkTheme = AppTheme.dark(accent);
    final amoledTheme = AppTheme.amoled(accent);

    ThemeMode themeMode;
    switch (settings.themeMode) {
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
      default:
        themeMode = ThemeMode.dark;
    }

    return MaterialApp.router(
      title: 'Manzar',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: settings.themeMode == AppThemeMode.amoled
          ? amoledTheme
          : darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
