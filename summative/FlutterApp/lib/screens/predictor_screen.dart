import 'package:flutter/material.dart';
import '../models/student_input.dart';
import '../services/prediction_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';
import '../widgets/result_sheet.dart';

class PredictorScreen extends StatefulWidget {
  const PredictorScreen({super.key});

  @override
  State<PredictorScreen> createState() => _PredictorScreenState();
}

class _PredictorScreenState extends State<PredictorScreen> {
  final _formKey = GlobalKey<FormState>();
  final StudentInput _input = StudentInput();
  bool _loading = false;

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await PredictionService.predict(_input);
      if (!mounted) return;
      await showResultSheet(context, result);
    } on PredictionException catch (e) {
      if (!mounted) return;
      showErrorSheet(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorSheet(context, 'Something unexpected happened. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _backgroundSection(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _PredictButton(loading: _loading, onPressed: _submit),
      ),
    );
  }

  // --- Section -------------------------------------------------------

  Widget _backgroundSection() {
    return FormSection(
      title: 'Student Background',
      icon: Icons.person_rounded,
      initiallyExpanded: true,
      children: [
        LabeledDropdown(
          label: 'Gender',
          value: _input.gender.toString(),
          options: const {'0': 'Female', '1': 'Male'},
          onChanged: (v) => setState(() => _input.gender = int.parse(v)),
        ),
        LabeledDropdown(
          label: 'Race / Ethnicity Group',
          value: _input.raceEthnicity,
          options: const {
            'group A': 'Group A',
            'group B': 'Group B',
            'group C': 'Group C',
            'group D': 'Group D',
            'group E': 'Group E',
          },
          onChanged: (v) => setState(() => _input.raceEthnicity = v),
        ),
        LabeledDropdown(
          label: 'Parental Level of Education',
          value: _input.parentalEducation,
          options: const {
            'some high school': 'Some High School',
            'high school': 'High School',
            'some college': 'Some College',
            "associate's degree": "Associate's Degree",
            "bachelor's degree": "Bachelor's Degree",
            "master's degree": "Master's Degree",
          },
          onChanged: (v) => setState(() => _input.parentalEducation = v),
        ),
        LabeledDropdown(
          label: 'Lunch Type',
          value: _input.lunch.toString(),
          options: const {'0': 'Free / Reduced', '1': 'Standard'},
          onChanged: (v) => setState(() => _input.lunch = int.parse(v)),
        ),
        YesNoSwitch(
          label: 'Completed test-preparation course',
          icon: Icons.menu_book_rounded,
          value: _input.testPreparationCourse == 1,
          onChanged: (v) => setState(() => _input.testPreparationCourse = v ? 1 : 0),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentSoft],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Student Performance\nPredictor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Fill in a student\u2019s background to predict their average exam '
            'score before any exam is taken.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PredictButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _PredictButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accentSoft],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: loading ? null : onPressed,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_graph_rounded, color: Colors.black),
                          SizedBox(width: 10),
                          Text(
                            'Predict',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
