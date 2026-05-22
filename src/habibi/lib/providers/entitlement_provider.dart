import 'package:flutter/foundation.dart';

import '../data/billing_repository.dart';

/// Exposes the user's Pro status to the UI. Delegates storage to a
/// [BillingRepository] so the same provider works for the demo or real IAP.
class EntitlementProvider extends ChangeNotifier {
  EntitlementProvider(this._repo);

  final BillingRepository _repo;

  /// Free users may keep this many *personal* habits. Challenges are unlimited.
  static const int freeHabitLimit = 3;

  bool get isPro => _repo.isPro;
  ProPlan? get currentPlan => _repo.currentPlan;

  Future<bool> buy(ProPlan plan) async {
    final ok = await _repo.buy(plan);
    if (ok) notifyListeners();
    return ok;
  }

  Future<void> restore() async {
    await _repo.restore();
    notifyListeners();
  }

  Future<void> resetToFree() async {
    await _repo.resetToFree();
    notifyListeners();
  }
}
