import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/video_api_service.dart';

/// Shown when the user opens a shared video link.
/// Fetches video metadata from PocketBase then launches the player.
class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key, required this.videoId});
  final String videoId;

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final video = await VideoApiService.fetchVideo(widget.videoId);
      if (!mounted) return;
      context.pushReplacement('/player', extra: video);
    } on VideoApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: _error != null ? _ErrorView(error: _error!, onRetry: _load) : _LoadingView(),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: colors.accent),
        const SizedBox(height: 20),
        Text('Loading video…', style: context.text.bodyLarge),
        const SizedBox(height: 8),
        Text(
          'Connecting to server',
          style: context.text.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text('Could not load video', style: context.text.titleMedium),
          const SizedBox(height: 8),
          Text(
            error,
            style: context.text.bodyMedium?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => context.go('/library'),
                child: const Text('Go home'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: colors.accent),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
