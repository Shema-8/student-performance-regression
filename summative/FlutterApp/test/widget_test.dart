import 'package:flutter_test/flutter_test.dart';
import 'package:student_predictor/main.dart';

void main() {
  testWidgets(
    'Student Academic Performance Predictor loads correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(const StudentPredictorApp());

      expect(find.byType(StudentPredictorApp), findsOneWidget);
    },
  );
}