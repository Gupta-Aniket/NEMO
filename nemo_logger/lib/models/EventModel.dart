class EventModel {
  final String type;
  final String sessionId;
  final int timestamp;
  final String? level;
  final String? file;
  final int? line;
  final String? function;
  final String? message;
  final Map<String, dynamic>? payload;

  EventModel({
    required this.type,
    required this.sessionId,
    required this.timestamp,
    this.level,
    this.file,
    this.line,
    this.function,
    this.message,
    this.payload,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    try {
      return EventModel(
        type: json['type'] as String,
        sessionId: json['sessionId'] as String,
        timestamp: json['timestamp'] as int,
        level: json['level'] as String?,
        file: json['file'] as String?,
        line: json['line'] as int?,
        function: json['function'] as String?,
        message: json['message'] as String?,
        payload: json['payload'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw FormatException('Invalid event format: $e');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type,
      'sessionId': sessionId,
      'timestamp': timestamp,
    };
    
    if (level != null) data['level'] = level;
    if (file != null) data['file'] = file;
    if (line != null) data['line'] = line;
    if (function != null) data['function'] = function;
    if (message != null) data['message'] = message;
    if (payload != null) data['payload'] = payload;
    
    return data;
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}