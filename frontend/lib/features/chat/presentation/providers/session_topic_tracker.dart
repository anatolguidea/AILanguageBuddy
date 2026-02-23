import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which topics have already received the initial AI greeting this app session.
/// When the user leaves chat and returns to the same topic, we do NOT repeat the initial message.
final sessionTopicTrackerProvider =
    StateNotifierProvider<SessionTopicTrackerNotifier, Set<String>>((ref) {
  return SessionTopicTrackerNotifier();
});

class SessionTopicTrackerNotifier extends StateNotifier<Set<String>> {
  SessionTopicTrackerNotifier() : super({});

  bool hasReceivedInitial(String topicId) => state.contains(topicId);

  void markInitialSent(String topicId) {
    state = {...state, topicId};
  }

  /// Call when user clears history for a topic so they get the initial message again.
  void clearInitialForTopic(String topicId) {
    state = state.difference({topicId});
  }

  void clear() {
    state = {};
  }
}
