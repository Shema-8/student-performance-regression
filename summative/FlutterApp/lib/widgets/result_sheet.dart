import 'package:flutter/material.dart';
import '../services/prediction_service.dart';
import '../theme/app_theme.dart';
import 'result_gauge.dart';

Color _flagColor(String flag) {
  final f = flag.toLowerCase();
  if (f.contains('below average')) return AppColors.risk;
  if (f.contains('above average')) return AppColors.good;
  return AppColors.warn; // plain "Average"
}

IconData _flagIcon(String flag) {
  final f = flag.toLowerCase();
  if (f.contains('below average')) return Icons.warning_rounded;
  if (f.contains('above average')) return Icons.check_circle_rounded;
  return Icons.visibility_rounded; // plain "Average"
}

Future<void> showResultSheet(BuildContext context, PredictionResult result) {
  final color = _flagColor(result.performanceFlag);
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: GlassContainer(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 22),
              const Text('Predicted Average Score',
                  style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
              const SizedBox(height: 10),
              ResultGauge(predictedAverageScore: result.predictedAverageScore, color: color),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_flagIcon(result.performanceFlag), color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      result.performanceFlag,
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Model used: ${result.modelUsed}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.glassBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Simple error sheet for network / validation failures.
void showErrorSheet(BuildContext context, String message) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassContainer(
        radius: 28,
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.risk, size: 40),
            const SizedBox(height: 14),
            const Text('Prediction failed',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
