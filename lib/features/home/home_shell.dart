import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/library')) return 0;
    if (location.startsWith('/folders')) return 1;
    if (location.startsWith('/playlists')) return 2;
    if (location.startsWith('/downloads')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex(context),
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go('/library');
              case 1:
                context.go('/folders');
              case 2:
                context.go('/playlists');
              case 3:
                context.go('/downloads');
              case 4:
                context.go('/settings');
            }
          },
          destinations: const [
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
              icon: Icon(Icons.download_outlined),
              selectedIcon: Icon(Icons.download),
              label: 'Downloads',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
