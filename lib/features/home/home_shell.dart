import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/ads/ad_manager.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _exitWarningShown = false;
  Timer? _exitTimer;

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/folders')) return 2;
    if (location.startsWith('/playlists')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onBack(BuildContext context) {
    final idx = _selectedIndex(context);
    if (idx != 0) {
      // Not on Home — go back to home
      context.go('/home');
      return;
    }

    // Already on Home — require a second back to exit
    if (_exitWarningShown) {
      _exitTimer?.cancel();
      SystemNavigator.pop();
      return;
    }

    _exitWarningShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Press back again to exit'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    _exitTimer = Timer(const Duration(seconds: 2), () {
      _exitWarningShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _onBack(context),
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border, width: 1)),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex(context),
            onDestinationSelected: (i) {
              final changingTab = i != _selectedIndex(context);
              switch (i) {
                case 0:
                  context.go('/home');
                case 1:
                  context.go('/library');
                case 2:
                  context.go('/folders');
                case 3:
                  context.go('/playlists');
                case 4:
                  context.go('/settings');
              }
              // Interstitial cadence: skip 1 switch, show on the next, repeat.
              if (changingTab) AdManager.instance.onTabSwitched();
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.video_library_outlined),
                selectedIcon: Icon(Icons.video_library),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: 'Folders',
              ),
              NavigationDestination(
                icon: Icon(Icons.playlist_play_outlined),
                selectedIcon: Icon(Icons.playlist_play),
                label: 'Playlists',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
