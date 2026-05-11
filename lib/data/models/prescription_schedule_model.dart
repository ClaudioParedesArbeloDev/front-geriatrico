class PrescriptionSchedule {
  final int id;
  final int medicalPrescriptionId;
  final String scheduledTime; 
  final String? label;       

  const PrescriptionSchedule({
    required this.id,
    required this.medicalPrescriptionId,
    required this.scheduledTime,
    this.label,
  });

  factory PrescriptionSchedule.fromJson(Map<String, dynamic> json) {
    return PrescriptionSchedule(
      id: json['id'],
      medicalPrescriptionId: json['medical_prescription_id'],
    
      scheduledTime: (json['scheduled_time'] as String? ?? '').length > 5
          ? (json['scheduled_time'] as String).substring(0, 5)
          : json['scheduled_time'] ?? '',
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() => {
        'scheduled_time': scheduledTime,
        if (label != null) 'label': label,
      };
}
