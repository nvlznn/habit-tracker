import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/billing_repository.dart';
import '../providers/entitlement_provider.dart';

/// The paywall shown when a free user hits the 3-habit limit, or from Settings.
/// Pops `true` if the user becomes Pro, `false`/null otherwise.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  ProPlan _selected = ProPlan.annual;
  bool _busy = false;

  static const _features = [
    'Unlimited habits',
    'Restore archived habits',
    'Charts & statistics',
    'All home-screen widgets',
    'Import & export your data',
  ];

  Future<void> _buy() async {
    setState(() => _busy = true);
    final ok = await context.read<EntitlementProvider>().buy(_selected);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome to Habibi Pro! (${_selected.label})')),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _restore() async {
    await context.read<EntitlementProvider>().restore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No previous purchases found (demo)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habibi Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                children: [
                  Icon(Icons.workspace_premium, size: 56, color: cs.primary),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Unlock everything',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Free includes 3 habits & unlimited challenges',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final f in _features) _FeatureRow(text: f),
                  const SizedBox(height: 24),
                  for (final plan in ProPlan.values)
                    _PlanTile(
                      plan: plan,
                      selected: _selected == plan,
                      onTap: () => setState(() => _selected = plan),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _busy ? null : _buy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Continue · ${_selected.priceLabel}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _restore,
              child: const Text('Restore purchases'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Demo purchase — no real payment is made.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final ProPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color:
            selected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? cs.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                      selected ? cs.primary : cs.onSurface.withValues(alpha: 0.35),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      if (plan.badge != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          plan.badge!,
                          style: TextStyle(fontSize: 12, color: cs.primary),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  plan.priceLabel,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
