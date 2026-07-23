import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_input.dart';


const String kApiBaseUrl = 'https://student-academic-performance-api-tj7i.onrender.com';

class PredictionResult {
  final double predictedAverageScore;
  final String modelUsed;
  final String performanceFlag;

  PredictionResult({
    required this.predictedAverageScore,
    required this.modelUsed,
    required this.performanceFlag,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      predictedAverageScore: (json['predicted_average_score'] as num).toDouble(),
      modelUsed: json['model_used'] as String,
      performanceFlag: json['performance_flag'] as String,
    );
  }
}

/// Thrown for both network failures and API-side validation errors (422),
/// with a human-readable message ready to show in the UI.
class PredictionException implements Exception {
  final String message;
  PredictionException(this.message);
  @override
  String toString() => message;
}

class PredictionService {
  static Future<PredictionResult> predict(StudentInput input) async {
    final uri = Uri.parse('$kApiBaseUrl/predict');

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(input.toJson()),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw PredictionException(
        'Could not reach the prediction server. Check your internet '
        'connection or try again in a moment.',
      );
    }

    if (response.statusCode == 200) {
      return PredictionResult.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 422) {
      // FastAPI/Pydantic validation error — surface the first message.
      try {
        final body = jsonDecode(response.body);
        final detail = body['detail'];
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          final field = (first['loc'] as List).last;
          throw PredictionException('Invalid value for "$field": ${first['msg']}');
        }
      } catch (_) {
        // fall through to generic message below
      }
      throw PredictionException('One or more values are out of the allowed range.');
    }

    throw PredictionException('Server error (${response.statusCode}). Please try again.');
  }
}
