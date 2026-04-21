import 'package:flutter_test/flutter_test.dart';
import 'package:fishgame_mobile/screens/game.dart';

void main() {
  
  print("Running tests on game.dart");

  group('calculateMagnitude', () {
    test('returns correct magnitude for simple vector', () {
      final result = calculateMagnitude(3, 4, 0);
      expect(result, closeTo(5.0, 0.0001));
    });

    test('returns correct magnitude for zero vector', () {
      final result = calculateMagnitude(0, 0, 0);
      expect(result, 0.0);
    });

    test('returns correct magnitude for 3D vector', () {
      final result = calculateMagnitude(1, 2, 2);
      expect(result, closeTo(3.0, 0.0001));
    });
  });

  group('calculateMotion', () {
    test('returns 0 when magnitude equals gravity (rest state)', () {
      final result = calculateMotion(0, 0, 9.8);
      expect(result, closeTo(0.0, 0.0001));
    });

    test('returns positive motion when magnitude exceeds gravity', () {
      final result = calculateMotion(0, 0, 12.0);
      expect(result, greaterThan(0));
    });

    test('clamps negative motion to 0', () {
      final result = calculateMotion(0, 0, 5.0);
      expect(result, 0.0);
    });
  });

  group('canCast', () {
    test('returns true when all conditions are met', () {
      final result = canCast(
        isConnected: true,
        isReady: true,
        flow: GameFlow.armed,
        hasCast: false,
      );

      expect(result, true);
    });

    test('returns false if not connected', () {
      final result = canCast(
        isConnected: false,
        isReady: true,
        flow: GameFlow.armed,
        hasCast: false,
      );

      expect(result, false);
    });

    test('returns false if not ready', () {
      final result = canCast(
        isConnected: true,
        isReady: false,
        flow: GameFlow.armed,
        hasCast: false,
      );

      expect(result, false);
    });

    test('returns false if flow is not armed', () {
      final result = canCast(
        isConnected: true,
        isReady: true,
        flow: GameFlow.waitingForBite,
        hasCast: false,
      );

      expect(result, false);
    });

    test('returns false if already cast', () {
      final result = canCast(
        isConnected: true,
        isReady: true,
        flow: GameFlow.armed,
        hasCast: true,
      );

      expect(result, false);
    });
  });
}