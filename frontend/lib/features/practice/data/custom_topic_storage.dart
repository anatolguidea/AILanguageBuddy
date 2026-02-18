import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/custom_topic.dart';

const String _kCustomTopicsKey = 'custom_topics';

Future<List<CustomTopic>> loadCustomTopics() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = prefs.getStringList(_kCustomTopicsKey);
  if (jsonList == null || jsonList.isEmpty) return [];
  return jsonList
      .map((s) => CustomTopic.fromJson(jsonDecode(s) as Map<String, dynamic>))
      .toList();
}

Future<void> saveCustomTopics(List<CustomTopic> topics) async {
  final prefs = await SharedPreferences.getInstance();
  final list = topics.map((t) => jsonEncode(t.toJson())).toList();
  await prefs.setStringList(_kCustomTopicsKey, list);
}
