/// Safety helpers: local emergency number, local currency, and the alert
/// sent to trusted contacts.
library;

const _emergency = {
  'US': '911', 'CA': '911', 'MX': '911', 'PH': '911', 'AR': '911',
  'GB': '999', 'IE': '112', 'HK': '999', 'MY': '999', 'SG': '995',
  'AU': '000', 'NZ': '111', 'JP': '110', 'KR': '112', 'CN': '110',
  'IN': '112', 'BR': '190', 'ZA': '10111', 'AE': '999', 'SA': '911',
};

/// 112 also reaches emergency services from most mobile phones worldwide.
String emergencyNumber(String? country) => _emergency[country?.toUpperCase()] ?? '112';

const _currency = {
  'US': r'$', 'CA': r'$', 'AU': r'$', 'NZ': r'$', 'MX': r'$', 'SG': r'$',
  'IN': '₹', 'GB': '£', 'JP': '¥', 'CN': '¥', 'KR': '₩', 'BR': r'R$',
  'AE': 'AED ', 'ZA': 'R', 'CH': 'CHF ', 'PH': '₱', 'NG': '₦',
};
const _euro = {'FR', 'DE', 'ES', 'IT', 'NL', 'IE', 'PT', 'BE', 'AT', 'FI', 'GR'};

String currencySymbol(String? country) {
  final c = country?.toUpperCase();
  if (_euro.contains(c)) return '€';
  return _currency[c] ?? r'$';
}

String formatMoney(int cents, String? country) =>
    '${currencySymbol(country)}${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

const defaultAlertMessage =
    "I'm on a date and I don't feel safe. Please call me. My location:";

String alertText(String message, {double? lat, double? lng}) =>
    lat == null || lng == null ? message : '$message https://maps.google.com/?q=$lat,$lng';

/// One SMS to everyone (Android separates numbers with ';', iOS with ',').
Uri smsUri(List<String> phones, String body, {required bool android}) =>
    Uri.parse('sms:${phones.join(android ? ';' : ',')}${android ? '?' : '&'}body=${Uri.encodeComponent(body)}');
