import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lottie Animation Asset Parsing Tests', () {
    test('screen_terang.json parses and loads composition correctly', () async {
      final file = File('assets/animations/screen_terang.json');
      expect(file.existsSync(), isTrue);
      final jsonString = await file.readAsString();
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      final composition = await LottieComposition.fromBytes(
        utf8.encode(jsonString),
      );

      expect(composition.duration.inMilliseconds, greaterThan(2000));
      expect(composition.bounds.width, 1280.0);
      expect(composition.bounds.height, 720.0);
      expect(map['assets'], isNotEmpty);
    });

    test('screen_gelap.json parses and loads composition correctly', () async {
      final file = File('assets/animations/screen_gelap.json');
      expect(file.existsSync(), isTrue);
      final jsonString = await file.readAsString();
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      final composition = await LottieComposition.fromBytes(
        utf8.encode(jsonString),
      );

      expect(composition.duration.inMilliseconds, greaterThan(2000));
      expect(composition.bounds.width, 1280.0);
      expect(composition.bounds.height, 720.0);
      expect(map['assets'], isNotEmpty);
    });
  });
}
