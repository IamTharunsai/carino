import 'package:carino/models/safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emergency number follows the country', () {
    expect(emergencyNumber('US'), '911');
    expect(emergencyNumber('IN'), '112');
    expect(emergencyNumber('GB'), '999');
    expect(emergencyNumber('AU'), '000');
    expect(emergencyNumber(null), '112'); // works on most phones worldwide
  });

  test('money shows the local currency', () {
    expect(formatMoney(1250, 'US'), r'$12.50');
    expect(formatMoney(1250, 'IN'), '₹12.50');
    expect(formatMoney(1250, 'GB'), '£12.50');
    expect(formatMoney(1250, 'FR'), '€12.50');
    expect(formatMoney(5, 'US'), r'$0.05');
  });

  test('alert text carries the custom message and a map link', () {
    final t = alertText('I need help', lat: 39.96, lng: -83.0);
    expect(t, startsWith('I need help'));
    expect(t, contains('https://maps.google.com/?q=39.96,-83.0'));
    expect(alertText('Hi', lat: null, lng: null), 'Hi');
  });

  test('sms link lists every contact', () {
    final u = smsUri(['+1555', '+1666'], 'hey', android: true);
    expect(u.toString(), startsWith('sms:+1555;+1666'));
    expect(smsUri(['+1555', '+1666'], 'hey', android: false).toString(), startsWith('sms:+1555,+1666'));
  });
}
