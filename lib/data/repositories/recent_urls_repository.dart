import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_repository.dart';

const _kRecentUrlsKey = 'recent_urls_v1';
const _kMaxRecentUrls = 10;

final recentUrlsProvider =
    NotifierProvider<RecentUrlsNotifier, List<String>>(
        RecentUrlsNotifier.new);

class RecentUrlsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final prefs = ref.read(sharedPrefsProvider);
    return prefs.getStringList(_kRecentUrlsKey) ?? [];
  }

  void add(String url) {
    final next = [url, ...state.where((u) => u != url)];
    state = next.take(_kMaxRecentUrls).toList();
    _persist();
  }

  void remove(String url) {
    state = state.where((u) => u != url).toList();
    _persist();
  }

  void _persist() {
    ref.read(sharedPrefsProvider).setStringList(_kRecentUrlsKey, state);
  }
}
