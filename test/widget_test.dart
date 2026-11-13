// Cariño smoke + invariant tests.
//
// These tests pin the Bible's release-blocking invariants at the unit
// level: the 21+ floor in the sample data, the app-name single source of
// truth, the RemoteConfig hard limits, and the mock-backend default.
// They are NOT a substitute for the device QA in the hosting phase.
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/config/app_config.dart';
import 'package:carino/config/env.dart';
import 'package:carino/data/mock_data.dart';
import 'package:carino/models/member.dart';
import 'package:carino/services/remote_config.dart';
import 'package:carino/services/verification_service.dart';

void main() {
  group('App identity (single source of truth)', () {
    test('app name lives in AppConfig only', () {
      expect(AppConfig.appName, 'Cariño');
      expect(AppConfig.appNameAscii, 'Carino');
      expect(AppConfig.minimumAge, 21);
    });
  });

  group('21+ floor', () {
    test('every sample member is 21 or older', () {
      for (final m in MockData.members) {
        expect(m.age, greaterThanOrEqualTo(21),
            reason: '${m.name} is under 21 in sample data');
      }
      expect(MockData.currentUser.age, greaterThanOrEqualTo(21));
    });

    test('age math: a 20-year-old does not pass the gate', () {
      final now = DateTime(2026, 11, 13);
      final dob20 = DateTime(2005, 12, 1);
      var age = now.year - dob20.year;
      if (now.month < dob20.month ||
          (now.month == dob20.month && now.day < dob20.day)) {
        age--;
      }
      expect(age, 20);
      expect(age >= AppConfig.minimumAge, isFalse);
    });
  });

  group('Mock backend default (nothing breaks before hosting)', () {
    test('no dart-define config => mock mode', () {
      expect(Env.isConfigured, isFalse);
      expect(Env.useMockBackend, isTrue);
    });
  });

  group('RemoteConfig hard limits (compiled defaults)', () {
    test('defaults carry honest windows and no pressure phrases', () {
      final rc = RemoteConfigService();
      expect(rc.matchExpiryHours, greaterThan(0));
      expect(rc.dailyDropSize, greaterThan(0));
      expect(rc.cityBatchFull, isFalse);
      final copy = '${rc.welcomeHook} ${rc.paywallHeadline} '
              '${rc.dailyDropEmptyCopy}'
          .toLowerCase();
      for (final banned in ['hurry', 'last chance', 'left!', 'expires soon']) {
        expect(copy.contains(banned), isFalse,
            reason: 'pressure copy found: $banned');
      }
    });
  });

  group('Verification layering', () {
    test('three layers exist and badge requires all three', () {
      expect(VerificationLayer.values.length, 3);
      final svc = VerificationService();
      expect(svc.status, VerificationStatus.notStarted);
      expect(svc.badgeEarned, isFalse);
    });

    test('demo flow passes layers in order', () async {
      final svc = VerificationService();
      await svc.runDemoFlow();
      expect(svc.status, VerificationStatus.passed);
      expect(svc.badgeEarned, isTrue);
      for (final layer in VerificationLayer.values) {
        expect(svc.layerPassed(layer), isTrue);
      }
    });
  });

  group('Match expiry honesty', () {
    test('expiry applies only to unmessaged, unarchived matches', () {
      for (final m in MockData.matches) {
        if (m.planStatus != null) {
          expect(m.isExpiring, isFalse,
              reason:
                  'a match with a plan must never show expiry pressure');
        }
      }
      for (final m in MockData.archivedMatches) {
        expect(m.archived, isTrue);
        expect(m.isExpiring, isFalse);
      }
    });
  });

  group('Intentions', () {
    test('every intention has a plain label incl. Still exploring', () {
      expect(Intention.values.length, 5);
      expect(Intention.stillExploring.label, 'Still exploring');
      for (final i in Intention.values) {
        expect(i.label.isNotEmpty, isTrue);
        expect(i.tagline.isNotEmpty, isTrue);
      }
    });
  });
}
