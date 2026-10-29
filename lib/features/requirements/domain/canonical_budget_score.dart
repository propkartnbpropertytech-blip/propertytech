/// Canonical budget score. The boundaries match
/// `src/modules/matching/canonicalBudgetScore.js` on the API.
class CanonicalBudgetScore {
  final int score;
  final String band;
  final bool disqualified;

  const CanonicalBudgetScore({
    required this.score,
    required this.band,
    this.disqualified = false,
  });

  static CanonicalBudgetScore evaluate({
    required num price,
    required num minBudget,
    required num maxBudget,
    String mode = 'balanced',
  }) {
    final amount = price.toDouble();
    final minB = minBudget.toDouble();
    final maxB = maxBudget.toDouble();
    final strict = mode == 'strict';

    if (!(maxB > 0)) {
      return const CanonicalBudgetScore(score: 0, band: 'missing');
    }
    if (strict && amount > maxB * 1.10) {
      return const CanonicalBudgetScore(score: 0, band: 'disqualified', disqualified: true);
    }
    if (amount >= minB && amount <= maxB) {
      return const CanonicalBudgetScore(score: 30, band: 'exact');
    }
    if (amount >= minB * 0.85 && amount <= maxB * 1.15) {
      return const CanonicalBudgetScore(score: 20, band: 'near');
    }
    if (!strict && amount >= minB * 0.75 && amount <= maxB * 1.25) {
      return const CanonicalBudgetScore(score: 10, band: 'flexible');
    }
    return const CanonicalBudgetScore(score: 0, band: 'outside');
  }
}
