import 'package:flutter/material.dart';
import 'package:quizz_generator/theme/colors.dart';
import 'package:quizz_generator/widgets/localization_extensions.dart';

class DashboardMetric {
  const DashboardMetric({
    required this.labelKey,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String labelKey;
  final String value;
  final IconData icon;
  final Color color;

  static List<DashboardMetric> getInstructorMetrics() {
    return const [
      DashboardMetric(
        labelKey: 'activeQuizzes',
        value: '06',
        icon: Icons.play_circle_outline,
        color: AppColors.teal,
      ),
      DashboardMetric(
        labelKey: 'attempts',
        value: '128',
        icon: Icons.groups_outlined,
        color: AppColors.inkBlue,
      ),
      DashboardMetric(
        labelKey: 'passRate',
        value: '84%',
        icon: Icons.trending_up,
        color: AppColors.saffron,
      ),
    ];
  }

  static List<DashboardMetric> getStudentMetrics() {
    return const [
      DashboardMetric(
        labelKey: 'availableNow',
        value: '01',
        icon: Icons.assignment_turned_in_outlined,
        color: AppColors.teal,
      ),
      DashboardMetric(
        labelKey: 'completed',
        value: '04',
        icon: Icons.task_alt_outlined,
        color: AppColors.inkBlue,
      ),
      DashboardMetric(
        labelKey: 'averageScore',
        value: '88%',
        icon: Icons.workspace_premium_outlined,
        color: AppColors.saffron,
      ),
    ];
  }

  static List<DashboardMetric> getAdminMetrics() {
    return const [
      DashboardMetric(
        labelKey: 'totalUsers',
        value: '148',
        icon: Icons.people_outline,
        color: AppColors.inkBlue,
      ),
      DashboardMetric(
        labelKey: 'activeSessions',
        value: '12',
        icon: Icons.online_prediction_outlined,
        color: AppColors.teal,
      ),
      DashboardMetric(
        labelKey: 'systemLoad',
        value: '100%',
        icon: Icons.dns_outlined,
        color: AppColors.saffron,
      ),
    ];
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.metric,
    this.note,
    super.key,
  });
  final DashboardMetric metric;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final supportingNote = note;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored top edge
          Container(height: 4, color: metric.color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Label
                      Expanded(
                        child: Text(
                          context.text(metric.labelKey),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Icon square
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: metric.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(metric.icon, size: 18, color: metric.color),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Prominent Value
                  Text(
                    metric.value,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkBlue,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Supporting Note
                  if (supportingNote != null && supportingNote.isNotEmpty)
                    Text(
                      supportingNote,
                      style: TextStyle(
                        fontSize: 12,
                        color: metric.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Signal Line
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: metric.color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.75, // Visual signal line progression
                      child: Container(
                        decoration: BoxDecoration(
                          color: metric.color,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
