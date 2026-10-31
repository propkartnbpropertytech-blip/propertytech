import 'dart:async';

/// Debounces list search and drops a response that belongs to an older keystroke.
class SearchRequestGate {
  SearchRequestGate({this.delay = const Duration(milliseconds: 250)});

  final Duration delay;
  Timer? _timer;
  int _generation = 0;

  int get generation => _generation;

  void schedule(void Function(int generation) onFire) {
    _timer?.cancel();
    final generation = ++_generation;
    _timer = Timer(delay, () => onFire(generation));
  }

  void cancel() {
    _timer?.cancel();
    _generation++;
  }

  bool isCurrent(int generation) => generation == _generation;

  void dispose() {
    _timer?.cancel();
  }
}
