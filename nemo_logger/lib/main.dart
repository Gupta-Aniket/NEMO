import 'package:flutter/material.dart';
import 'package:nemo_logger/view/MainScreen.dart';

void main() {
  runApp(const NemoViewerApp());
}

class NemoViewerApp extends StatelessWidget {
  const NemoViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEMO Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
