import 'dart:async';

/// Waits for a pause before an AI search, and drops a response from an older query.
class AiSearchSession {
  AiSearchSession({this.delay = const Duration(milliseconds: 700)});

  final Duration delay;
  Timer? _timer;
  int generation = 0;

  void schedule(String text, void Function(int generation, String text) onFire) {
    _timer?.cancel();
    final current = ++generation;
    _timer = Timer(delay, () => onFire(current, text));
  }

  void submit(String text, void Function(int generation, String text) onFire) {
    _timer?.cancel();
    final current = ++generation;
    onFire(current, text);
  }

  bool isCurrent(int id) => id == generation;

  void dismiss() {
    _timer?.cancel();
    generation++;
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Keeps the last successful grouped search when a later request fails.
class AiSearchMemory {
  Map<String, dynamic>? last;
  bool stale = false;

  void remember(Map<String, dynamic> data) {
    last = data;
    stale = false;
  }

  Map<String, dynamic>? fail() {
    if (last == null) return null;
    stale = true;
    return last;
  }
}
