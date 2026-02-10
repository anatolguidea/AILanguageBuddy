class Scenario {
  final String id;
  final String title;
  final String description;
  final String emoji;

  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });

  static const List<Scenario> all = [
    Scenario(id: 'general', title: 'General Chat', description: 'Just a friendly chat', emoji: '💬'),
    Scenario(id: 'cafe', title: 'At the Café', description: 'Order coffee and snacks', emoji: '☕'),
    Scenario(id: 'airport', title: 'Airport Check-in', description: 'Travel vocabulary', emoji: '✈️'),
    Scenario(id: 'doctor', title: 'Doctor Visit', description: 'Describe symptoms', emoji: '👨‍⚕️'),
    Scenario(id: 'job_interview', title: 'Job Interview', description: 'Professional setting', emoji: '💼'),
    Scenario(id: 'market', title: 'At the Market', description: 'Buying groceries', emoji: '🍎'),
    Scenario(id: 'friend', title: 'Casual Friend', description: 'Catching up', emoji: '👋'),
  ];
}
