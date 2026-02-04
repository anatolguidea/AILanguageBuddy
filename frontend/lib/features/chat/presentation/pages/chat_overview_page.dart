import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class ChatOverviewPage extends StatelessWidget {
  const ChatOverviewPage({super.key});

  final List<Map<String, dynamic>> _scenarios = const [
    {
      'id': 'coffee_shop',
      'title': 'Coffee Shop',
      'description': 'Order your favorite drink and a snack.',
      'icon': FontAwesomeIcons.mugHot,
      'color': Color(0xFFC0392B),
    },
    {
      'id': 'airport',
      'title': 'At the Airport',
      'description': 'Check in and find your gate.',
      'icon': FontAwesomeIcons.plane,
      'color': Color(0xFF2980B9),
    },
    {
      'id': 'doctor',
      'title': 'Doctor Visit',
      'description': 'Explain your symptoms to the doctor.',
      'icon': FontAwesomeIcons.userDoctor,
      'color': Color(0xFF27AE60),
    },
    {
      'id': 'interview',
      'title': 'Job Interview',
      'description': 'Answer common interview questions.',
      'icon': FontAwesomeIcons.briefcase,
      'color': Color(0xFF8E44AD),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scenarios')),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppDimensions.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppDimensions.md,
          mainAxisSpacing: AppDimensions.md,
          childAspectRatio: 0.85,
        ),
        itemCount: _scenarios.length,
        itemBuilder: (context, index) {
          final scenario = _scenarios[index];
          return GestureDetector(
            onTap: () {
               context.go('/chat/session/${scenario['id']}');
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: (scenario['color'] as Color).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (scenario['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      scenario['icon'] as IconData,
                      size: 32,
                      color: scenario['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    scenario['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      scenario['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
