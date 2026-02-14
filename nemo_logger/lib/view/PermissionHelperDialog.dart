import 'package:flutter/material.dart';
import 'dart:io';

class PermissionHelperDialog extends StatelessWidget {
  const PermissionHelperDialog({super.key});

  Future<void> _openMacOSSecuritySettings() async {
    try {
      await Process.run('open', [
        'x-apple.systempreferences:com.apple.preference.security?Firewall'
      ]);
    } catch (e) {
      print('Could not open system preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: Colors.blue[700]),
          const SizedBox(width: 12),
          const Text('Network Permission Required'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NEMO Viewer needs permission to accept network connections.',
              style: TextStyle(fontSize: 14),
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
                      Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'What to expect:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (Platform.isMacOS) ...[
                    const Text(
                      'macOS will show a dialog:\n'
                      '"Do you want the application to accept incoming network connections?"',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Click "Allow" when prompted',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (Platform.isWindows) ...[
                    const Text(
                      'Windows Defender Firewall will show:\n'
                      '"Windows Defender Firewall has blocked some features..."',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Check "Private networks" and click "Allow access"',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, size: 18, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'If you miss the prompt:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (Platform.isMacOS)
                    const Text(
                      'You can manually allow it in:\n'
                      'System Preferences → Security & Privacy → Firewall',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    )
                  else if (Platform.isWindows)
                    const Text(
                      'You can manually allow it in:\n'
                      'Windows Security → Firewall & network protection',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (Platform.isMacOS)
          TextButton.icon(
            onPressed: () {
              _openMacOSSecuritySettings();
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings First'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}