// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greenify_mobile/main.dart';

void main() {
  testWidgets('GreenifyApp smoke test', (WidgetTester tester) async {
    // Set a phone screen resolution
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build Greenify app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: GreenifyApp()));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the Greenify login screen mounts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
