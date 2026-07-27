/// A source of the current time.
///
/// Rationale: the spec forbids calling `DateTime.now()` directly inside
/// business logic so that streak/savings/milestone maths is deterministic in
/// tests. Every pure function that needs "now" takes a [Clock] (or a plain
/// `DateTime now`) instead. Alternative considered: the `clock` package — but a
/// one-method interface has zero dependencies and is trivial to fake.
abstract interface class Clock {
  DateTime now();
}

/// Production clock backed by the system wall clock.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Test clock returning a fixed instant (or one advanced manually).
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
  void set(DateTime to) => _now = to;
}
