import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_info.g.dart';

/// `ExpirationDate` from a provisioning profile. The profile is a signed
/// envelope around a plain XML plist, so the date can be found as text.
DateTime? parseProvisionExpiry(List<int> profile) {
  final match = RegExp(r'<key>ExpirationDate</key>\s*<date>([^<]+)</date>')
      .firstMatch(latin1.decode(profile, allowInvalid: true));
  return match == null ? null : DateTime.tryParse(match.group(1)!.trim());
}

/// When this iPhone build stops opening (ARCHITECTURE §12): a free Apple ID
/// signs for 7 days. The profile sits next to the app's executable. Null on
/// Android, the simulator and App Store builds, which have no such limit.
@Riverpod(keepAlive: true)
Future<DateTime?> buildExpiry(Ref ref) async {
  if (!Platform.isIOS) return null;
  final profile = File(
    p.join(p.dirname(Platform.resolvedExecutable), 'embedded.mobileprovision'),
  );
  if (!profile.existsSync()) return null;
  return parseProvisionExpiry(await profile.readAsBytes());
}
