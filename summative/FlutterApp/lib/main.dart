import 'package:flutter/material.dart';
import 'screens/predictor_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StudentPredictorApp());
}

class StudentPredictorApp extends StatelessWidget {
  const StudentPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Early-Warning Predictor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const PredictorScreen(),
    );
  }
}
