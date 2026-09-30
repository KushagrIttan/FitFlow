import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../data/purchases_service.dart';

/// Full-screen RevenueCat Paywall for the current offering
/// (Lifetime + Yearly + Monthly packages, remotely configured).
///
/// NOTE: per RevenueCat docs, [PaywallView] must live directly in the widget
/// tree — never inside a modal or bottom sheet. Pro status refreshes via the
/// CustomerInfo listener wired in main(); [onDismiss] also fires after a
/// successful purchase, so we just pop and let the listener update the UI.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Fit Pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // PaywallView fills the page; the dashboard paywall provides its own
      // close affordance, the AppBar back button is a second exit.
      body: SafeArea(
        child: PaywallView(
          onRestoreCompleted: (_) {
            ref.invalidate(isProProvider);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchases restored')),
              );
            }
          },
          onDismiss: () {
            ref.invalidate(isProProvider);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
