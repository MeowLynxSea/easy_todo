import 'package:easy_todo/widgets/responsive_web_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResponsiveWebFrame passes through on non-web', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ResponsiveWebFrame(child: Text('framed'))),
    );

    expect(find.text('framed'), findsOneWidget);
  });
}
