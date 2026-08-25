import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kyoto_travel_app/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('ログイン画面が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('メールアドレス'), findsOneWidget);
    expect(find.text('パスワード'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'ログイン'), findsOneWidget);
  });
}
