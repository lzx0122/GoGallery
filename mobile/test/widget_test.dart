// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // 必須使用 ProviderScope 包裹 App，因為我們使用了 Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: GoGalleryApp(),
      ),
    );

    // 驗證是否顯示了 App 標題 "GoGallery"
    expect(find.text('GoGallery'), findsOneWidget);
    
    // 驗證是否顯示了 "Sign in with Google" 按鈕
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
