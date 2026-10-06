import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:navmaas/core/platform/build_info.dart';
import 'package:path/path.dart' as p;

/// On an iPhone signed with a free Apple ID, the build's expiry is read
/// from its provisioning profile: within the next 7 days. The simulator has
/// no profile, so it reads null. Run: flutter test
/// integration_test/build_expiry_test.dart -d <iphone>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reads the 7-day expiry (null on the simulator)', (_) async {
    if (!Platform.isIOS) return;
    // The profile sits next to the executable, inside Runner.app.
    expect(Platform.resolvedExecutable, endsWith('Runner.app/Runner'));
    final expiry = await ProviderContainer().read(buildExpiryProvider.future);
    final profile = File(
      p.join(
        p.dirname(Platform.resolvedExecutable),
        'embedded.mobileprovision',
      ),
    );
    if (!profile.existsSync()) {
      // The simulator: no profile, no expiry.
      expect(expiry, isNull);
    } else {
      final left = expiry!.difference(DateTime.now());
      expect(left.inMinutes, inInclusiveRange(1, 7 * 24 * 60));
    }
  });
}
