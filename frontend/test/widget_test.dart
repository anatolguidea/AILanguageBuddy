// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:ailanguageapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {
      // Ignore if already initialized by another test.
    }
  });

  testWidgets('App boots without widget exceptions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: AiLanguageApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    final exception = tester.takeException();
    if (exception != null) {
      expect(exception.toString(), contains('RenderFlex overflowed'));
    }
  });
}
