import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/video_file.dart';
import '../../data/models/watch_entry.dart';
import '../../data/repositories/watch_history_repository.dart';
import '../../shared/widgets/video_thumb.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  bool _hasUrl = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() {
      final has = _urlController.text.trim().isNotEmpty;
      if (has != _hasUrl) setState(() => _hasUrl = has);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _playUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    final watchId = _extractWatchId(url);
    if (watchId != null) {
      context.push('/watch/$watchId');
    } else {
      context.push('/player', extra: VideoFile(
        id: 'url_${DateTime.now().millisecondsSinceEpoch}',
        title: url.split('/').last.split('?').first.isEmpty
            ? 'External video'
            : url.split('/').last.split('?').first,
        path: url,
        duration: Duration.zero,
        size: 0,
        dateAdded: DateTime.now(),
        mimeType: 'video/*',
      ));
    }
    _urlController.clear();
  }

  String? _extractWatchId(String url) {
    try {
      final parsed = Uri.parse(url);
      final segments = parsed.pathSegments;
      if (segments.length >= 2 && segments[segments.length - 2] == 'watch') {
        final id = segments.last;
        return id.isNotEmpty ? id : null;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final history = ref.watch(watchHistoryProvider);
    final recent = history.take(5).toList();

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero(colors)),
            SliverToBoxAdapter(child: _buildDivider(colors)),
            SliverToBoxAdapter(child: _buildSectionLabel('Quick access', colors)),
            SliverToBoxAdapter(child: _buildLibraryCard(colors)),
            SliverToBoxAdapter(child: _buildUrlCard(colors)),
            SliverToBoxAdapter(child: _buildDivider(colors)),
            if (recent.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildRecentHeader(colors)),
              SliverToBoxAdapter(child: _buildRecentRow(recent, colors)),
            ] else ...[
              SliverToBoxAdapter(child: _buildEmptyRecent(colors)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(AppColorExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.35),
                width: 1,
              ),
              color: colors.surfaceAlt,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Image.asset(
                'assets/icon/icon.png',
                fit: BoxFit.cover,
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          Text(
            'Welcome to',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              letterSpacing: 1.5,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

          const SizedBox(height: 6),

          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Nova',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Plex',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: colors.accent,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms, curve: Curves.easeOut)
              .fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 10),

          Text(
            'Your own video player that feels like a cinema',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildDivider(AppColorExtension colors) {
    return Divider(color: colors.border, height: 1, thickness: 1,
        indent: 20, endIndent: 20);
  }

  Widget _buildSectionLabel(String label, AppColorExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLibraryCard(AppColorExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/library'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.accentSubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.video_library_rounded,
                    color: colors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Play from your library',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse and play videos from your storage',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: colors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildUrlCard(AppColorExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.accent.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stream a Video',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paste a NovaPlex link and play instantly',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Input field — full width
            Container(
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hasUrl
                      ? colors.accent.withValues(alpha: 0.5)
                      : colors.border,
                ),
              ),
              child: TextField(
                controller: _urlController,
                style: TextStyle(fontSize: 12, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Paste your NovaPlex link here...',
                  hintStyle: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  prefixIcon: Icon(Icons.link_rounded,
                      size: 18, color: colors.textSecondary),
                  suffixIcon: _hasUrl
                      ? GestureDetector(
                          onTap: () => _urlController.clear(),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: colors.textSecondary),
                        )
                      : GestureDetector(
                          onTap: () async {
                            final data = await Clipboard.getData(
                                Clipboard.kTextPlain);
                            if (data?.text != null) {
                              _urlController.text = data!.text!;
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.content_paste_rounded,
                                    size: 15, color: colors.accent),
                                const SizedBox(width: 3),
                                Text('Paste',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: colors.accent,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                ),
                onSubmitted: (_) => _playUrl(),
                keyboardType: TextInputType.url,
              ),
            ),

            const SizedBox(height: 12),

            // Play button — full width
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _hasUrl ? _playUrl : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Play Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      colors.surfaceAlt,
                  disabledForegroundColor:
                      colors.textSecondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmptyRecent(AppColorExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENTLY WATCHED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.play_circle_outline_rounded,
                    size: 36, color: colors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 10),
                Text(
                  'Nothing watched yet',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your recently watched videos will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildRecentHeader(AppColorExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            'RECENTLY WATCHED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/library'),
            child: Text(
              'See all',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRow(List<WatchEntry> entries, AppColorExtension colors) {
    return SizedBox(
      height: 118,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          return _RecentChip(entry: entry, colors: colors, index: i);
        },
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.entry, required this.colors, required this.index});
  final WatchEntry entry;
  final AppColorExtension colors;
  final int index;

  @override
  Widget build(BuildContext context) {
    final video = VideoFile(
      id: entry.videoId,
      title: entry.videoTitle,
      path: entry.videoPath,
      duration: Duration(milliseconds: entry.durationMs),
      size: 0,
      dateAdded: entry.lastWatched,
      mimeType: 'video/*',
    );

    return GestureDetector(
      onTap: () => context.push('/player', extra: video),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumb(video: video),
                    // Progress bar at bottom
                    if (entry.watchPercent > 0 && !entry.isFinished)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: entry.watchPercent,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation(colors.accent),
                          minHeight: 2,
                        ),
                      ),
                    // Play icon overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Text(
                entry.videoTitle.replaceAll(RegExp(r'\.[^.]+$'), ''),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (300 + 60 * index).ms, duration: 250.ms)
        .slideX(begin: 0.05, end: 0);
  }
}
