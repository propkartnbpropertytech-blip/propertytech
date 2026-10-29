import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/requirements/domain/canonical_budget_score.dart';

void main() {
  final vectors = <Map<String, Object?>>[
    {'name': 'exact', 'price': 5000000, 'min': 4000000, 'max': 6000000, 'score': 30, 'band': 'exact'},
    {'name': 'below range inside 15 percent', 'price': 3400000, 'min': 4000000, 'max': 6000000, 'score': 20, 'band': 'near'},
    {'name': 'above range inside 15 percent', 'price': 6500000, 'min': 4000000, 'max': 6000000, 'score': 20, 'band': 'near'},
    {'name': 'lower 15 percent boundary', 'price': 4000000 * 0.85, 'min': 4000000, 'max': 6000000, 'score': 20, 'band': 'near'},
    {'name': 'upper 15 percent boundary', 'price': 6000000 * 1.15, 'min': 4000000, 'max': 6000000, 'score': 20, 'band': 'near'},
    {'name': 'inside 25 percent', 'price': 4000000 * 0.76, 'min': 4000000, 'max': 6000000, 'score': 10, 'band': 'flexible'},
    {'name': '25 percent upper boundary', 'price': 6000000 * 1.25, 'min': 4000000, 'max': 6000000, 'score': 10, 'band': 'flexible'},
    {'name': 'outside 25 percent', 'price': 6000000 * 1.26, 'min': 4000000, 'max': 6000000, 'score': 0, 'band': 'outside'},
    {'name': 'missing maximum', 'price': 100, 'min': 0, 'max': 0, 'score': 0, 'band': 'missing'},
    {'name': 'decimal inside range', 'price': 10.5, 'min': 10.25, 'max': 10.75, 'score': 30, 'band': 'exact'},
  ];

  for (final vector in vectors) {
    test(vector['name'] as String, () {
      final result = CanonicalBudgetScore.evaluate(
        price: vector['price'] as num,
        minBudget: vector['min'] as num,
        maxBudget: vector['max'] as num,
      );
      expect(result.score, vector['score']);
      expect(result.band, vector['band']);
    });
  }

  test('strict mode disqualifies a price more than 10 percent above the maximum', () {
    final result = CanonicalBudgetScore.evaluate(
      price: 6000000 * 1.11,
      minBudget: 4000000,
      maxBudget: 6000000,
      mode: 'strict',
    );
    expect(result.disqualified, isTrue);
    expect(result.score, 0);
  });
}
