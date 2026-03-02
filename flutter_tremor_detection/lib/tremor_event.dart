class TremorEvent {
  final int? id;
  final DateTime timestamp;
  final double magnitude;
  final double duration;
  final String severity;

  TremorEvent({
    this.id,
    required this.timestamp,
    required this.magnitude,
    required this.duration,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'magnitude': magnitude,
      'duration': duration,
      'severity': severity,
    };
  }

  factory TremorEvent.fromMap(Map<String, dynamic> map) {
    return TremorEvent(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      magnitude: map['magnitude'],
      duration: map['duration'],
      severity: map['severity'],
    );
  }
}