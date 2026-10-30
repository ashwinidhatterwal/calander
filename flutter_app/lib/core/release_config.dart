class ReleaseConfig {
  const ReleaseConfig._();

  static const String appVersion = '1.0.0';
  static const String developerName = String.fromEnvironment('DEVELOPER_NAME',
      defaultValue: 'Ashwini Dhatterwal');
  static const String developerEmail = supportEmail;
  static const String supportUpiId = String.fromEnvironment('SUPPORT_UPI_ID');
  static const String supportPayeeName = String.fromEnvironment(
    'SUPPORT_PAYEE_NAME',
    defaultValue: 'Hindu Calendar Developer',
  );
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  static bool get supportConfigured => supportUpiId.trim().isNotEmpty;
  static bool get noteRequestConfigured => supportEmail.trim().isNotEmpty;
}
