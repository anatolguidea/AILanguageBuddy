import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/language_provider.dart';
import '../../domain/entities/lesson.dart';
import '../../data/lessons_repository.dart';

final lessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final currentLanguage = ref.watch(languageProvider);
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getLessons(currentLanguage.code);
});
