import 'package:flutter_test/flutter_test.dart';
import '../tool/verify_festival_rules.dart' as verification;

void main() {
  test(
    'published festival dates, annual completeness and tithi boundaries',
    () {
      expect(verification.verifyFestivalRules(), greaterThan(1000));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
