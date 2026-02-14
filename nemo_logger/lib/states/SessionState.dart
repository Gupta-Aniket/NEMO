import 'package:flutter/foundation.dart';
import '../models/EventModel.dart';
import '../models/SessionMetadataModel.dart';

class SessionState extends ChangeNotifier {
  bool _isConnected = false;
  bool _isRecording = false;
  String? _currentSessionId;
  SessionMetadata? _metadata;
  final List<EventModel> _events = [];

  String _levelFilter = 'All';
  String _searchQuery = '';
  bool _autoScroll = true;

  int? _serverPort;
  String? _serverIp;

  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;
  String? get currentSessionId => _currentSessionId;
  SessionMetadata? get metadata => _metadata;
  List<EventModel> get events => _getFilteredEvents();
  String get levelFilter => _levelFilter;
  String get searchQuery => _searchQuery;
  bool get autoScroll => _autoScroll;
  int? get serverPort => _serverPort;
  String? get serverIp => _serverIp;

  String? get connectionUrl {
    if (_serverIp != null && _serverPort != null) {
      return 'ws://$_serverIp:$_serverPort/ws';
    }
    return null;
  }

  void setConnected(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  void setRecording(bool recording) {
    _isRecording = recording;
    notifyListeners();
  }

  void setServerInfo(int port, String? ip) {
    _serverPort = port;
    _serverIp = ip;
    notifyListeners();
  }

  void startSession(String sessionId, SessionMetadata metadata) {
    _currentSessionId = sessionId;
    _metadata = metadata;
    _events.clear();
    notifyListeners();
  }

  void endSession() {
    _isRecording = false;
    notifyListeners();
  }

  void addEvent(EventModel event) {
    _events.add(event);
    notifyListeners();
  }

  void clearLogs() {
    _events.clear();
    notifyListeners();
  }

  void setLevelFilter(String level) {
    _levelFilter = level;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setAutoScroll(bool enabled) {
    _autoScroll = enabled;
    notifyListeners();
  }

  List<EventModel> _getFilteredEvents() {
    List<EventModel> filtered = _events;

    if (_levelFilter != 'All') {
      filtered = filtered
          .where((e) => e.level == _levelFilter.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        final message = e.message?.toLowerCase() ?? '';
        final file = e.file?.toLowerCase() ?? '';
        final function = e.function?.toLowerCase() ?? '';
        return message.contains(query) ||
            file.contains(query) ||
            function.contains(query);
      }).toList();
    }

    return filtered;
  }

  Map<String, dynamic> exportSession() {
    return {
      'metadata': _metadata?.toJson(),
      'events': _events.map((e) => e.toJson()).toList(),
    };
  }
}