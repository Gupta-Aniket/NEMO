class SessionMetadata {
  final String device;
  final String os;
  final String build;

  SessionMetadata({
    required this.device,
    required this.os,
    required this.build,
  });

  factory SessionMetadata.fromJson(Map<String, dynamic> json) {
    try {
      return SessionMetadata(
        device: json['device'] as String? ?? 'Unknown',
        os: json['os'] as String? ?? 'Unknown',
        build: json['build'] as String? ?? 'Unknown',
      );
    } catch (e) {
      throw FormatException('Invalid metadata format: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'os': os,
      'build': build,
    };
  }
}