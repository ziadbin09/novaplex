import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_shell.dart';
import '../../features/library/library_screen.dart';
import '../../features/library/folder_screen.dart';
import '../../features/library/folder_detail_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/playlists/playlists_screen.dart';
import '../../features/playlists/playlist_detail_screen.dart';
import '../../data/models/video_file.dart';
import '../../features/watch/watch_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  onException: (_, state, router) => router.go('/home'),
  routes: [
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/splash',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SplashScreen(),
      ),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/folders',
          builder: (context, state) => const FolderScreen(),
        ),
        GoRoute(
          path: '/playlists',
          builder: (context, state) => const PlaylistsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/player',
      pageBuilder: (context, state) {
        final video = state.extra as VideoFile;
        return CustomTransitionPage(
          child: PlayerScreen(video: video),
          transitionsBuilder: (ctx, animation, _, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 250),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/folders/detail',
      pageBuilder: (context, state) {
        final name = state.extra as String? ?? '';
        return CustomTransitionPage(
          child: FolderDetailScreen(folderName: name),
          transitionsBuilder: (ctx, animation, _, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    // Shared video links: https://yourdomain.pages.dev/watch/VIDEO_ID
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/watch/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomTransitionPage(
          child: WatchScreen(videoId: id),
          transitionsBuilder: (ctx, animation, _, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 250),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/playlists/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        final name = state.extra as String? ?? 'Playlist';
        return CustomTransitionPage(
          child: PlaylistDetailScreen(playlistId: id, playlistName: name),
          transitionsBuilder: (ctx, animation, _, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
  ],
);
