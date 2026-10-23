import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Writes screenshots taken by integration_test/store_screenshots_test.dart to
/// $SHOT_DIR (default: store/screenshots/raw/device).
Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final dir = Platform.environment['SHOT_DIR'] ?? 'store/screenshots/raw/device';
        final file = File('$dir/$name.png')..createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        return true;
      },
    );
