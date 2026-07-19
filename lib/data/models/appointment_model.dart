class AppointmentModel {
  final String id;
  final String requestId;
  final String appointmentNumber;
  final DateTime date;
  final String time;
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.requestId,
    required this.appointmentNumber,
    required this.date,
    required this.time,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      appointmentNumber: json['appointment_number'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      time: json['time'] as String? ?? '',
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
