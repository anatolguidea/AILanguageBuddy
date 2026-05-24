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
}
