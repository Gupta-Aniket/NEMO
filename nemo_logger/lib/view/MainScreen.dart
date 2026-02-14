import 'package:flutter/material.dart';
import 'package:nemo_logger/view/ControlPannel.dart';
import 'package:nemo_logger/view/PermissionHelperDialog.dart';
import 'dart:io';
import '../states/SessionState.dart';
import '../service/WebSocketService.dart';

import '../view/EventListPanel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final SessionState _sessionState;
  late final WebSocketService _webSocketService;
  bool _isStarting = true;
  String? _startupError;
  bool _hasShownPermissionHelper = false;

  @override
  void initState() {
    super.initState();
    _sessionState = SessionState();
    _webSocketService = WebSocketService(_sessionState);
    _showPermissionHelperIfNeeded();
  }

  Future<void> _showPermissionHelperIfNeeded() async {
    if (!_hasShownPermissionHelper) {
      _hasShownPermissionHelper = true;

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PermissionHelperDialog(),
        );

        if (shouldContinue == true) {
          _startServer();
        } else {
          setState(() {
            _isStarting = false;
            _startupError = 'Setup cancelled by user';
          });
        }
      }
    } else {
      _startServer();
    }
  }

  bool _isPermissionError(String error) {
    final lowerError = error.toLowerCase();
    return lowerError.contains('permission') ||
        lowerError.contains('denied') ||
        lowerError.contains('firewall') ||
        lowerError.contains('not allowed') ||
        lowerError.contains('blocked');
  }

  Future<void> _openMacOSSecuritySettings() async {
    try {
      await Process.run('open', [
        'x-apple.systempreferences:com.apple.preference.security?Firewall',
      ]);
    } catch (e) {
      print('Could not open system preferences: $e');
    }
  }

  Future<void> _startServer() async {
    setState(() {
      _isStarting = true;
      _startupError = null;
    });

    try {
      await _webSocketService.start();
      setState(() {
        _isStarting = false;
      });
    } catch (e) {
      final errorString = e.toString();
      final isPermissionIssue = _isPermissionError(errorString);

      setState(() {
        _isStarting = false;
        _startupError = errorString;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      isPermissionIssue
                          ? Icons.shield_outlined
                          : Icons.error_outline,
                      color: isPermissionIssue ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPermissionIssue
                          ? 'Permission Required'
                          : 'Server Startup Failed',
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPermissionIssue) ...[
                      const Text(
                        'macOS is blocking network connections.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'You need to allow NEMO Viewer to accept incoming network connections.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Quick Fix:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. Click "Open Security Settings" below\n'
                              '2. Click the lock 🔒 to make changes\n'
                              '3. Click "Firewall Options"\n'
                              '4. Add NEMO Viewer or allow all incoming connections\n'
                              '5. Click "Retry" here',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error: $e',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Could not start the WebSocket server.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error: $e',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Possible solutions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Close other apps using ports 8080-8089'),
                      const Text('• Check your firewall settings'),
                      const Text('• Restart the application'),
                      const Text('• Run with administrator/sudo privileges'),
                    ],
                  ],
                ),
                actions: [
                  if (isPermissionIssue && Platform.isMacOS)
                    TextButton.icon(
                      onPressed: () {
                        _openMacOSSecuritySettings();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Open Security Settings'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      if (isPermissionIssue) {
                        _hasShownPermissionHelper = false;
                        await _showPermissionHelperIfNeeded();
                      } else {
                        await _startServer();
                      }
                    },
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  void dispose() {
    _webSocketService.stop();
    _sessionState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Starting NEMO Viewer...',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Finding available port...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_startupError != null) {
      final isPermissionIssue = _isPermissionError(_startupError!);

      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPermissionIssue
                      ? Icons.shield_outlined
                      : Icons.error_outline,
                  size: 64,
                  color: isPermissionIssue ? Colors.orange : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  isPermissionIssue
                      ? 'Permission Required'
                      : 'Failed to Start Server',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (isPermissionIssue) ...[
                  const Text(
                    'macOS is blocking network connections',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click below to open Security Settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ] else ...[
                  Text(
                    _startupError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPermissionIssue && Platform.isMacOS)
                      ElevatedButton.icon(
                        onPressed: _openMacOSSecuritySettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Security Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    if (isPermissionIssue && Platform.isMacOS)
                      const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isPermissionIssue) {
                          setState(() {
                            _startupError = null;
                            _hasShownPermissionHelper = false;
                          });
                          _showPermissionHelperIfNeeded();
                        } else {
                          _startServer();
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isPermissionIssue) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Steps to Fix:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Click "Open Security Settings" above\n'
                          '2. Click the lock 🔒 icon (enter password)\n'
                          '3. Click "Firewall Options" button\n'
                          '4. Add this app or allow all connections\n'
                          '5. Click "Retry" button above',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          ListenableBuilder(
            listenable: _sessionState,
            builder: (context, child) {
              return ControlPanel(
                sessionState: _sessionState,
                webSocketService: _webSocketService,
              );
            },
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _sessionState,
              builder: (context, child) {
                return EventListPanel(sessionState: _sessionState);
              },
            ),
          ),
        ],
      ),
    );
  }
}
