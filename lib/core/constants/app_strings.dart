class AppStrings {
  AppStrings._();

  static const String appName = 'Indopo Partner';
  static const String splashTagline = 'Medical Partner Platform';

  // Login Screen
  static const String selectRoleHeader = 'Select your role to continue';
  static const String emailUsernameLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String confirmLoginButton = 'Confirm & Login';
  static const String selectRoleHint = 'Please select your role first';
  static const String credentialsMismatchError =
      'Credentials do not match the selected role';
  static const String invalidCredentialsError = 'Invalid email or password';
  static const String forgotPassword = 'Forgot Password?';
  static const String emailAddress = 'Email Address';
  static const String forgotPasswordDescription =
      'Enter your email address and we will send you a link to reset your password.';
  static const String sendResetLink = 'Send Reset Link';

  // Roles
  static const String doctor = 'Doctor';
  static const String medical = 'Medical';
  static const String laboratory = 'Laboratory';
  static const String imagingCenter = 'Imaging Center';

  // Request Dashboard
  static const String tabNew = 'New';
  static const String tabInProgress = 'In Progress';
  static const String tabCompleted = 'Completed';

  // Detail & Appointment
  static const String rejectButton = 'Reject';
  static const String acceptButton = 'Accept';
  static const String appointmentConfirmedToast = 'Appointment #{id} confirmed';
}
