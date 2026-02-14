import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/EventModel.dart';
import '../models/SessionMetadataModel.dart';
import '../states/SessionState.dart';

class WebSocketService {
  static const int preferredPort = 8080;
  static const int maxPortAttempts = 10;

  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final SessionState sessionState;
  int? _actualPort;
  String? _localIpAddress;

  WebSocketService(this.sessionState);

  int? get actualPort => _actualPort;
  String? get localIpAddress => _localIpAddress;

  String? get connectionUrl {
    if (_localIpAddress != null && _actualPort != null) {
      return 'ws://$_localIpAddress:$_actualPort/ws';
    }
    return null;
  }

  Future<void> start({int startPort = preferredPort}) async {
    await _findLocalIpAddress();

    for (int port = startPort; port < startPort + maxPortAttempts; port++) {
      try {
        _server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          port,
          shared: false,
        );
        _actualPort = port;
        print('WebSocket server started on port $port');
        print('Local IP: $_localIpAddress');
        print('Connection URL: $connectionUrl');

        _server!.listen((HttpRequest request) {
          if (request.uri.path == '/ws') {
            WebSocketTransformer.upgrade(request).then((WebSocket socket) {
              _handleClient(socket);
            }).catchError((e) {
              print('WebSocket upgrade error: $e');
            });
          } else if (request.uri.path == '/health') {
            request.response
              ..statusCode = HttpStatus.ok
              ..write('NEMO Viewer Server Running')
              ..close();
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..write('Not found')
              ..close();
          }
        });

        sessionState.setServerInfo(_actualPort!, _localIpAddress);
        return;
      } catch (e) {
        if (e is SocketException && 
            (e.message.contains('Address already in use') ||
             e.message.contains('bind'))) {
          print('Port $port is in use, trying next port...');
          continue;
        } else {
          print('Failed to start server on port $port: $e');
          rethrow;
        }
      }
    }

    throw Exception(
        'Could not start server: all ports from $startPort to ${startPort + maxPortAttempts - 1} are in use');
  }

  Future<void> _findLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final octets = addr.address.split('.');
            if (octets[0] == '192' || octets[0] == '10' || 
                (octets[0] == '172' && int.parse(octets[1]) >= 16 && int.parse(octets[1]) <= 31)) {
              _localIpAddress = addr.address;
              print('Found local IP: $_localIpAddress on interface ${interface.name}');
              return;
            }
          }
        }
      }

      if (_localIpAddress == null && interfaces.isNotEmpty) {
        for (var interface in interfaces) {
          if (interface.addresses.isNotEmpty) {
            final addr = interface.addresses.first;
            if (!addr.isLoopback) {
              _localIpAddress = addr.address;
              print('Using IP: $_localIpAddress from ${interface.name}');
              return;
            }
          }
        }
      }

      _localIpAddress = 'localhost';
      print('Could not find local IP, using localhost');
    } catch (e) {
      print('Error finding local IP: $e');
      _localIpAddress = 'localhost';
    }
  }

  void _handleClient(WebSocket socket) {
    _clients.add(socket);
    sessionState.setConnected(true);
    print('Client connected. Total clients: ${_clients.length}');

    socket.listen(
      (dynamic message) {
        _handleMessage(message.toString());
      },
      onDone: () {
        _clients.remove(socket);
        if (_clients.isEmpty) {
          sessionState.setConnected(false);
        }
        print('Client disconnected. Total clients: ${_clients.length}');
      },
      onError: (error) {
        print('WebSocket error: $error');
        _clients.remove(socket);
        if (_clients.isEmpty) {
          sessionState.setConnected(false);
        }
      },
      cancelOnError: true,
    );
  }

  void _handleMessage(String message) {
    try {
      final Map<String, dynamic> json = jsonDecode(message);
      final String type = json['type'] as String;

      switch (type) {
        case 'session_start':
          _handleSessionStart(json);
          break;
        case 'log':
          _handleLogEvent(json);
          break;
        case 'session_end':
          _handleSessionEnd(json);
          break;
        default:
          print('Unknown message type: $type');
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _handleSessionStart(Map<String, dynamic> json) {
    try {
      final sessionId = json['sessionId'] as String;
      final metadataJson = json['metadata'] as Map<String, dynamic>?;

      final metadata = metadataJson != null
          ? SessionMetadata.fromJson(metadataJson)
          : SessionMetadata(
              device: 'Unknown',
              os: 'Unknown',
              build: 'Unknown',
            );

      sessionState.startSession(sessionId, metadata);
      print('Session started: $sessionId');
    } catch (e) {
      print('Error handling session_start: $e');
    }
  }

  void _handleLogEvent(Map<String, dynamic> json) {
    try {
      final event = EventModel.fromJson(json);
      sessionState.addEvent(event);
    } catch (e) {
      print('Error handling log event: $e');
    }
  }

  void _handleSessionEnd(Map<String, dynamic> json) {
    try {
      sessionState.endSession();
      print('Session ended');
    } catch (e) {
      print('Error handling session_end: $e');
    }
  }

  void sendCommand(String command) {
    final message = jsonEncode({'command': command});
    for (var client in _clients) {
      try {
        client.add(message);
      } catch (e) {
        print('Error sending command to client: $e');
      }
    }
  }

  void startRecording() {
    sessionState.setRecording(true);
    sendCommand('start_recording');
  }

  void stopRecording() {
    sessionState.setRecording(false);
    sendCommand('stop_recording');
  }

  Future<void> stop() async {
    for (var client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close();
    _server = null;
    sessionState.setConnected(false);
    print('WebSocket server stopped');
  }
}