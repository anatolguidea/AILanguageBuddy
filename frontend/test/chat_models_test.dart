import 'package:ailanguageapp/features/chat/data/models/chat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatAskRequest', () {
    test('uses backend-safe compact defaults', () {
      final request = ChatAskRequest(
        message: 'Hello',
        targetLanguage: 'English',
      );

      expect(request.toJson()['level'], 'B1');
      expect(request.toJson()['mode'], 'general');
    });
  });

  group('ChatAskResponse', () {
    test('parses structured corrections', () {
      final response = ChatAskResponse.fromJson({
        'replyText': 'Good try!',
        'corrections': [
          {
            'original': 'I goes home',
            'corrected': 'I go home',
            'explanation': 'Use go with I in the present simple.',
          },
        ],
      });

      expect(response.corrections, hasLength(1));
      expect(response.corrections.first.original, 'I goes home');
      expect(response.corrections.first.corrected, 'I go home');
      expect(
        response.corrections.first.explanation,
        'Use go with I in the present simple.',
      );
    });
  });
}
