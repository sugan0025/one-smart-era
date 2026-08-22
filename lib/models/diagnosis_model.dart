/// Crop Doctor AI Pathology and Diagnosis Models
class DiagnosisEntry {
  final String id;
  final String imagePath;
  final String cropName;
  final String diseaseName;
  final String severity; // 'Low', 'Moderate', 'High', 'Critical'
  final String symptoms;
  final String organicTreatment;
  final String chemicalTreatment;
  final String prevention;
  final String rawResponse;
  final DateTime timestamp;

  DiagnosisEntry({
    required this.id,
    required this.imagePath,
    this.cropName = 'Plant',
    required this.diseaseName,
    this.severity = 'Moderate',
    this.symptoms = '',
    this.organicTreatment = '',
    this.chemicalTreatment = '',
    this.prevention = '',
    required this.rawResponse,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'imagePath': imagePath,
    'cropName': cropName,
    'diseaseName': diseaseName,
    'severity': severity,
    'symptoms': symptoms,
    'organicTreatment': organicTreatment,
    'chemicalTreatment': chemicalTreatment,
    'prevention': prevention,
    'rawResponse': rawResponse,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DiagnosisEntry.fromMap(Map<String, dynamic> map) {
    return DiagnosisEntry(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: map['imagePath'] as String? ?? '',
      cropName: map['cropName'] as String? ?? 'Plant',
      diseaseName: map['diseaseName'] as String? ?? 'Crop Disease Analysis',
      severity: map['severity'] as String? ?? 'Moderate',
      symptoms: map['symptoms'] as String? ?? '',
      organicTreatment: map['organicTreatment'] as String? ?? '',
      chemicalTreatment: map['chemicalTreatment'] as String? ?? '',
      prevention: map['prevention'] as String? ?? '',
      rawResponse: map['rawResponse'] as String? ?? (map['diagnosis'] as String? ?? ''),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
