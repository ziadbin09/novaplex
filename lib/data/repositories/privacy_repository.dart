import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_repository.dart';

const _kPinKey = 'private_pin_v1';
const _kHiddenFoldersKey = 'hidden_folders_v1';

/// Folder names the user has hidden behind the PIN.
final hiddenFoldersProvider =
    NotifierProvider<HiddenFoldersNotifier, Set<String>>(
        HiddenFoldersNotifier.new);

/// Session-only unlock state — resets every app launch.
final privateUnlockedProvider =
    NotifierProvider<PrivateUnlockedNotifier, bool>(
        PrivateUnlockedNotifier.new);

class HiddenFoldersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.read(sharedPrefsProvider);
    return (prefs.getStringList(_kHiddenFoldersKey) ?? []).toSet();
  }

  void hide(String folder) {
    state = {...state, folder};
    _persist();
  }

  void unhide(String folder) {
    state = {...state}..remove(folder);
    _persist();
  }

  void _persist() {
    ref.read(sharedPrefsProvider).setStringList(
          _kHiddenFoldersKey,
          state.toList(),
        );
  }
}

class PrivateUnlockedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;
  void lock() => state = false;
}

/// PIN helpers — stored in SharedPreferences.
class PrivacyPin {
  PrivacyPin(this.ref);
  final Ref ref;

  bool get isSet =>
      ref.read(sharedPrefsProvider).getString(_kPinKey) != null;

  bool verify(String pin) =>
      ref.read(sharedPrefsProvider).getString(_kPinKey) == pin;

  void setPin(String pin) =>
      ref.read(sharedPrefsProvider).setString(_kPinKey, pin);
}

final privacyPinProvider = Provider<PrivacyPin>((ref) => PrivacyPin(ref));
