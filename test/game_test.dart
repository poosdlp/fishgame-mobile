import 'package:flutter_test/flutter_test.dart';
import 'package:fishgame_mobile/screens/game.dart';

void main() {
  group('calculateMagnitude', () {
    test('returns correct magnitude for simple vector', () {
      final result = calculateMagnitude(3, 4, 0);

      expect(result, closeTo(5.0, 0.0001));
    });

    test('returns 0 for the zero vector', () {
      final result = calculateMagnitude(0, 0, 0);

      expect(result, 0.0);
    });

    test('returns correct magnitude for a 3D vector', () {
      final result = calculateMagnitude(1, 2, 2);

      expect(result, closeTo(3.0, 0.0001));
    });
  });

  group('calculateMotion', () {
    test('returns 0 when magnitude equals gravity', () {
      final result = calculateMotion(0, 0, 9.8);

      expect(result, closeTo(0.0, 0.0001));
    });

    test('returns positive motion when magnitude exceeds gravity', () {
      final result = calculateMotion(0, 0, 12.0);

      expect(result, closeTo(2.2, 0.0001));
    });

    test('clamps motion to 0 when magnitude is below gravity', () {
      final result = calculateMotion(0, 0, 5.0);

      expect(result, 0.0);
    });
  });

  group('canUseMotion', () {
    test('returns true during casting when socket is ready and unlocked', () {
      final result = canUseMotion(
        isConnected: true,
        isReady: true,
        flow: GameFlow.casting,
        motionLocked: false,
      );

      expect(result, isTrue);
    });

    test('returns true during waiting when socket is ready and unlocked', () {
      final result = canUseMotion(
        isConnected: true,
        isReady: true,
        flow: GameFlow.waiting,
        motionLocked: false,
      );

      expect(result, isTrue);
    });

    test('returns true during bite when socket is ready and unlocked', () {
      final result = canUseMotion(
        isConnected: true,
        isReady: true,
        flow: GameFlow.bite,
        motionLocked: false,
      );

      expect(result, isTrue);
    });

    test('returns false when not connected', () {
      final result = canUseMotion(
        isConnected: false,
        isReady: true,
        flow: GameFlow.casting,
        motionLocked: false,
      );

      expect(result, isFalse);
    });

    test('returns false when not ready', () {
      final result = canUseMotion(
        isConnected: true,
        isReady: false,
        flow: GameFlow.casting,
        motionLocked: false,
      );

      expect(result, isFalse);
    });

    test('returns false when motion is locked', () {
      final result = canUseMotion(
        isConnected: true,
        isReady: true,
        flow: GameFlow.casting,
        motionLocked: true,
      );

      expect(result, isFalse);
    });

    test('returns false during minigame', () {
      final result = canUseMotion(
        isConnected: true,
        isReady: true,
        flow: GameFlow.minigame,
        motionLocked: false,
      );

      expect(result, isFalse);
    });

    test('returns false after a fish is caught', () {
      final result = canUseMotion(
        isConnected: true,
        isReady: true,
        flow: GameFlow.caught,
        motionLocked: false,
      );

      expect(result, isFalse);
    });
  });
}
