class AppointmentModel {
  final String id;
  final String requestId;
  final String appointmentNumber;
  final DateTime date;
  final String? time;
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.requestId,
    required this.appointmentNumber,
    required this.date,
    this.time,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    String? rawTime = json['time'] as String? ??
        json['appointmentTime'] as String? ??
        json['appointment_time'] as String?;
    if (rawTime == '0' ||
        rawTime == '00:00' ||
        rawTime == '00:00:00' ||
        (rawTime != null && rawTime.trim().isEmpty)) {
      rawTime = null;
    }

    return AppointmentModel(
      id: json['id'] as String? ?? '',
      requestId: json['request_id'] as String? ??
          json['requestId'] as String? ??
          '',
      appointmentNumber: json['appointment_number'] as String? ??
          json['appointmentNumber'] as String? ??
          json['tokenNumber'] as String? ??
          '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : (json['appointmentDate'] != null
              ? DateTime.parse(json['appointmentDate'] as String)
              : DateTime.now()),
      time: rawTime,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'appointment_number': appointmentNumber,
      'date': date.toIso8601String(),
      'time': time,
      'notes': notes,
    };
  }
}
