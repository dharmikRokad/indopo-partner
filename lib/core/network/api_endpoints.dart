class ApiEndpoints {
  // Base API URL — update this to your production backend URL
  static const String baseUrl = 'https://indopo-beta.onrender.com/api';

  static const String login = '/partner-auth/login';
  static const String changePassword = '/partner-auth/change-password';
  static const String deactivate = '/partner-auth/deactivate';
  static const String availability = '/partner-auth/availability';
  static const String profile = '/partner-auth/profile';
  static const String refreshToken = '/auth/refresh-token';
  static const String dropDownValue = '/dropdown-values';

  static const String appointmentsList = '/appointments/partner/list';
  static String appointmentStatus(String id) => '/appointments/$id/status';
  static String appointmentConfirm(String requestId) =>
      '/appointments/partner/$requestId/confirm';
  static String appointmentDetail(String id) => '/appointments/$id';

  // Prescription Chat & Thread Endpoints
  static const String prescriptionThreadInit = '/chat/prescription-thread';
  static const String myChats = '/chat/my-chats';
  static String chatMessages(String chatId) => '/chat/$chatId/messages';
  static String chatThreadReplies(String parentMessageId) => '/chat/thread/$parentMessageId';
  static const String sendMessage = '/chat/send';
}
