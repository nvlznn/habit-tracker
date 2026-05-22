import 'package:hive/hive.dart';

/// The three ways to buy Habibi Pro. Stored by its [name] (e.g. "annual").
enum ProPlan { monthly, annual, lifetime }

extension ProPlanInfo on ProPlan {
  String get label => switch (this) {
        ProPlan.monthly => 'Monthly',
        ProPlan.annual => 'Annual',
        ProPlan.lifetime => 'Lifetime',
      };

  /// Price shown on the paywall. NT\$ is the New Taiwan Dollar.
  String get priceLabel => switch (this) {
        ProPlan.monthly => 'NT\$30 / month',
        ProPlan.annual => 'NT\$300 / year',
        ProPlan.lifetime => 'NT\$690 once',
      };

  /// Small selling line under each plan, or null for none.
  String? get badge => switch (this) {
        ProPlan.monthly => null,
        ProPlan.annual => 'Save 17% · best value',
        ProPlan.lifetime => 'Pay once, yours forever',
      };
}

/// Owns "is the user Pro, and on which plan". Swap [LocalBillingRepository] for a
/// `StoreBillingRepository` (same methods, backed by Apple/Google IAP or
/// RevenueCat) to charge real money — nothing else in the app changes.
abstract class BillingRepository {
  /// The active plan, or null when the user is on the free plan.
  ProPlan? get currentPlan;
  bool get isPro;

  /// Returns true when the purchase succeeds.
  Future<bool> buy(ProPlan plan);

  /// Re-checks past purchases (the App Store requires a "Restore" action).
  Future<void> restore();

  /// Demo-only: drop back to the free plan so we can test the downgrade flow.
  Future<void> resetToFree();
}

/// Demo billing: no real money. Persists the chosen plan in the settings box
/// (the same box the theme already uses), so Pro state survives app restarts.
class LocalBillingRepository implements BillingRepository {
  LocalBillingRepository(this._box);

  final Box _box;
  static const _planKey = 'pro_plan';

  @override
  ProPlan? get currentPlan {
    final name = _box.get(_planKey) as String?;
    if (name == null) return null;
    return ProPlan.values.firstWhere(
      (p) => p.name == name,
      orElse: () => ProPlan.monthly,
    );
  }

  @override
  bool get isPro => currentPlan != null;

  @override
  Future<bool> buy(ProPlan plan) async {
    // Pretend to talk to the store for a moment, then unlock.
    await Future.delayed(const Duration(milliseconds: 500));
    await _box.put(_planKey, plan.name);
    return true;
  }

  @override
  Future<void> restore() async {
    // Nothing to restore in the mock — the real version asks Apple/Google here.
  }

  @override
  Future<void> resetToFree() async {
    await _box.delete(_planKey);
  }
}
