import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/clock.dart';

/// Rebuilds its [builder] once per second with a fresh "now", so live counters
/// (savings, calories) tick up smoothly.
///
/// Lifecycle-aware like the streak ticker: the timer only runs in the
/// foreground, so nothing ticks in the background. Reads time from the injected
/// [clock], keeping it deterministic under a `FakeClock` in tests.
class LiveNow extends StatefulWidget {
  const LiveNow({required this.clock, required this.builder, super.key});

  final Clock clock;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<LiveNow> createState() => _LiveNowState();
}

class _LiveNowState extends State<LiveNow> with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = widget.clock.now();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = widget.clock.now());
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
