import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/custom_topic_storage.dart';
import '../../domain/entities/custom_topic.dart';

final customTopicsProvider =
    StateNotifierProvider<CustomTopicsNotifier, AsyncValue<List<CustomTopic>>>(
  (ref) => CustomTopicsNotifier(),
);

class CustomTopicsNotifier extends StateNotifier<AsyncValue<List<CustomTopic>>> {
  CustomTopicsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await loadCustomTopics();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(String title, {String? description}) async {
    final current = state.valueOrNull ?? [];
    final topic = CustomTopic(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      createdAt: DateTime.now(),
    );
    final updated = [topic, ...current];
    await saveCustomTopics(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> remove(String id) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((t) => t.id != id).toList();
    await saveCustomTopics(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> update(CustomTopic topic) async {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((t) => t.id == topic.id);
    if (index < 0) return;
    final updated = [...current];
    updated[index] = topic;
    await saveCustomTopics(updated);
    state = AsyncValue.data(updated);
  }
}
