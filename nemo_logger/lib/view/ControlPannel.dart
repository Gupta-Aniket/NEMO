import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nemo_logger/view/QrcodeDialog.dart';
import 'dart:convert';
import 'dart:io';
import '../states/SessionState.dart';
import '../service/WebSocketService.dart';

class ControlPanel extends StatelessWidget {
  final SessionState sessionState;
  final WebSocketService webSocketService;

  const ControlPanel({
    super.key,
    required this.sessionState,
    required this.webSocketService,
  });

  Future<void> _exportSession(BuildContext context) async {
    try {
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Session',
        fileName: 'nemo_session_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (path != null) {
        final exportData = sessionState.exportSession();
        final jsonString = const JsonEncoder.withIndent(
          '  ',
        ).convert(exportData);
        final file = File(path);
        await file.writeAsString(jsonString);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session exported successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _showQrCode(BuildContext context) {
    if (sessionState.connectionUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Server not started yet')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => QrCodeDialog(
            connectionUrl: sessionState.connectionUrl!,
            ipAddress: sessionState.serverIp ?? 'localhost',
            port: sessionState.serverPort ?? 8080,
          ),
    );
  }

  void _copyConnectionUrl(BuildContext context) {
    if (sessionState.connectionUrl != null) {
      Clipboard.setData(ClipboardData(text: sessionState.connectionUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection URL copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'NEMO Viewer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'WebSocket Debug Tool',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildConnectionStatus(),
          const SizedBox(height: 16),
          _buildServerInfo(context),
          const SizedBox(height: 24),
          if (sessionState.metadata != null) ...[
            _buildSessionInfo(),
            const SizedBox(height: 24),
          ],
          _buildControlButtons(context),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 8),
          if (sessionState.serverPort != null)
            Text(
              'Server Port: ${sessionState.serverPort}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sessionState.isConnected ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sessionState.isConnected ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            sessionState.isConnected ? Icons.check_circle : Icons.cancel,
            color: sessionState.isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            sessionState.isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  sessionState.isConnected
                      ? Colors.green[900]
                      : Colors.red[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerInfo(BuildContext context) {
    if (sessionState.connectionUrl == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Starting server...', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Container(
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
              const Icon(Icons.wifi, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Server Running',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.qr_code_2, size: 20),
                onPressed: () => _showQrCode(context),
                tooltip: 'Show QR Code',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _copyConnectionUrl(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sessionState.connectionUrl!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap URL to copy • Tap QR icon to show QR code',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    final metadata = sessionState.metadata!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Info',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Device', metadata.device),
          _buildInfoRow('OS', metadata.os),
          _buildInfoRow('Build', metadata.build),
          if (sessionState.currentSessionId != null) ...[
            const SizedBox(height: 4),
            Text(
              'ID: ${sessionState.currentSessionId}',
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed:
              sessionState.isConnected && !sessionState.isRecording
                  ? () => webSocketService.startRecording()
                  : null,
          icon: const Icon(Icons.fiber_manual_record),
          label: const Text('Start Recording'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed:
              sessionState.isConnected && sessionState.isRecording
                  ? () => webSocketService.stopRecording()
                  : null,
          icon: const Icon(Icons.stop),
          label: const Text('Stop Recording'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed:
              sessionState.events.isNotEmpty
                  ? () => sessionState.clearLogs()
                  : null,
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear Logs'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed:
              sessionState.events.isNotEmpty
                  ? () => _exportSession(context)
                  : null,
          icon: const Icon(Icons.download),
          label: const Text('Export Session'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
