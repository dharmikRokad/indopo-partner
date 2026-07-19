import 'package:flutter_test/flutter_test.dart';
import 'package:indopo_partner/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validateEmail allows valid emails and usernames', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('john@example.com'), null);
      expect(Validators.validateEmail('john_doe'), null); // Username without @
    });

    test('validatePassword validates length', () {
      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword('123456'), null);
    });

    test('validatePhone checks format', () {
      expect(Validators.validatePhone(''), isNotNull);
      expect(Validators.validatePhone('+15551234567'), null);
      expect(Validators.validatePhone('555-1234'), isNotNull); // invalid format
    });
  });
}
