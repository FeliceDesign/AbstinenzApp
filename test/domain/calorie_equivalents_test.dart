import 'package:clean_tracker/features/savings/domain/calorie_equivalents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int amountOf(List<CalorieEquivalent> list, EquivalentKind kind) =>
      list.firstWhere((CalorieEquivalent e) => e.kind == kind).amount;

  test('no equivalents for zero or negative calories', () {
    expect(calorieEquivalents(0), isEmpty);
    expect(calorieEquivalents(-50), isEmpty);
  });

  test('rounds each equivalent from its divisor', () {
    final List<CalorieEquivalent> e = calorieEquivalents(1800);
    expect(amountOf(e, EquivalentKind.pizza), 2); // 1800 / 850
    expect(amountOf(e, EquivalentKind.running), 30); // 1800 / 60
    expect(amountOf(e, EquivalentKind.chocolate), 8); // 1800 / 230
  });

  test('drops equivalents that round below one', () {
    final List<CalorieEquivalent> e = calorieEquivalents(100);
    // 100 kcal ≈ 1.7 km running only; pizza/chocolate round to 0.
    expect(e.map((CalorieEquivalent x) => x.kind), <EquivalentKind>[
      EquivalentKind.running,
    ]);
    expect(amountOf(e, EquivalentKind.running), 2);
  });
}
