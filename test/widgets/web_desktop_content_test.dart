import 'package:easy_todo/widgets/web_desktop_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WebDesktopContent passes through on non-web', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WebDesktopContent(child: Text('content'))),
    );

    expect(find.text('content'), findsOneWidget);
  });
}
