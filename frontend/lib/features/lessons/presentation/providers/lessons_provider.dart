import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/lesson.dart';
import '../../data/lessons_repository.dart';
import '../../../settings/presentation/providers/language_provider.dart';

final lessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  final language = ref.watch(languageProvider); 
  return repository.getLessons(languageCode: language.code);
});
