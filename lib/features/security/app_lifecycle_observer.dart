import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that tracks whether the app went to background and needs re-auth.
///
/// - `false` = no re-auth needed (initial state, or after reset).
/// - `true`  = app was paused and needs re-authentication on resume.
final appLifecycleProvider = NotifierProvider<AppLifecycleNotifier, bool>(
  () => AppLifecycleNotifier(),
);

class AppLifecycleNotifier extends Notifier<bool> {
  bool _wasInBackground = false;

  @override
  bool build() => true;

  void onPaused() {
    _wasInBackground = true;
  }

  void onResumed() {
    if (_wasInBackground) {
      state = true;
      _wasInBackground = false;
    }
  }

  void resetAuth() {
    state = false;
  }
}

/// Observes [AppLifecycleState] changes via [WidgetsBindingObserver],
/// updates [appLifecycleProvider], and triggers a re-lock on resume.
///
/// Place this above [MaterialApp.router] so it receives lifecycle events.
class AppLifecycleObserver extends ConsumerStatefulWidget {
  const AppLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(appLifecycleProvider.notifier);
    if (state == AppLifecycleState.paused) {
      notifier.onPaused();
    } else if (state == AppLifecycleState.resumed) {
      notifier.onResumed();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
