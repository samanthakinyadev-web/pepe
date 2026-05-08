import 'package:flutter/material.dart';
import 'package:elimupepe/core/theme/app_theme.dart';
import 'package:elimupepe/core/services/user_data_service.dart';
import 'package:elimupepe/core/utils/error_feedback.dart';

class GradebookScreen extends StatefulWidget {
  const GradebookScreen({super.key});

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _gradebook;

  @override
  void initState() {
    super.initState();
    _loadGradebook();
  }

  Future<void> _loadGradebook() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gradebook = await UserDataService.instance.fetchStudentGradebook();
      if (!mounted) return;
      setState(() {
        _gradebook = gradebook;
        _isLoading = false;
      });
    } catch (e) {
      // Catch the specific exception from the API service and display
      // a user-friendly message.
      if (!mounted) return;
      setState(() {
        _error = ErrorFeedback.userMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _gradebook?['student'] as Map<String, dynamic>?;
    final gradeHistories =
        (_gradebook?['grade_histories'] as List?)?.whereType<Map>().toList() ??
        const [];
    final yearSummaries =
        (_gradebook?['year_summaries'] as List?)?.whereType<Map>().toList() ??
        const [];
    final pathwayScores =
        (_gradebook?['pathway_scores'] as List?)?.whereType<Map>().toList() ??
        const [];
    final assessments =
        (_gradebook?['assessment_results'] as List?)
            ?.whereType<Map>()
            .toList() ??
        const [];

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.white,
        title: const Text('Grade Book'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGradebook,
        color: AppColors.brandGreen,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.lightGreen),
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  ErrorFeedback.buildInlineError(
                    context: context,
                    title: 'Grade book unavailable',
                    error: _error,
                    onRetry: _loadGradebook,
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStudentCard(student),
                  const SizedBox(height: 16),
                  _buildSummaryGrid(
                    gradeHistories.length,
                    yearSummaries.length,
                    pathwayScores.length,
                    assessments.length,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Grade Histories',
                    gradeHistories,
                    (item) => _twoLineTile(
                      title:
                          item['academic_year']?.toString() ?? 'Academic Year',
                      subtitle:
                          item['term']?.toString() ?? 'Term not specified',
                      trailing:
                          item['average_score']?.toString() ??
                          item['score']?.toString(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Year Summaries',
                    yearSummaries,
                    (item) => _twoLineTile(
                      title:
                          item['academic_year']?.toString() ?? 'Academic Year',
                      subtitle:
                          item['remarks']?.toString() ?? 'No remarks available',
                      trailing: item['overall_proficiency_level_id']
                          ?.toString(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Pathway Scores',
                    pathwayScores,
                    (item) => _twoLineTile(
                      title: 'Pathway ${item['pathway_id']?.toString() ?? '-'}',
                      subtitle:
                          item['created_at']?.toString() ?? 'No date provided',
                      trailing: item['score']?.toString(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Assessment Results',
                    assessments,
                    (item) => _twoLineTile(
                      title:
                          'Evidence ${item['evidence_item_id']?.toString() ?? '-'}',
                      subtitle:
                          item['created_at']?.toString() ?? 'No date provided',
                      trailing:
                          item['proficiency_level_id']?.toString() ??
                          item['score']?.toString(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic>? student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandGreen, AppColors.lightGreen],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Profile',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            student?['name']?.toString() ?? 'Student',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            student?['grade']?.toString() ?? 'Grade not assigned',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(
    int histories,
    int summaries,
    int pathways,
    int assessments,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _statCard('Histories', histories.toString(), Icons.history_edu_rounded),
        _statCard('Summaries', summaries.toString(), Icons.summarize_rounded),
        _statCard('Pathways', pathways.toString(), Icons.route_rounded),
        _statCard(
          'Assessments',
          assessments.toString(),
          Icons.fact_check_rounded,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.brandGreen),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<Map> items,
    Widget Function(Map<String, dynamic>) builder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.brandGreen,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'No records available yet.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          ...items.map((item) => builder(Map<String, dynamic>.from(item))),
      ],
    );
  }

  Widget _twoLineTile({
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: trailing == null
            ? null
            : Text(
                trailing,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandGreen,
                ),
              ),
      ),
    );
  }
}
