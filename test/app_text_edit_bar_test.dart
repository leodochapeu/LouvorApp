import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/core/widgets/inputs/app_text_editing.dart';

void main() {
  Widget wrap({
    required Widget child,
    TargetPlatform platform = TargetPlatform.android,
  }) {
    return MaterialApp(
      theme: ThemeData(platform: platform, useMaterial3: true),
      home: AppTextEditBar(child: Scaffold(body: child)),
    );
  }

  testWidgets('shows paste on Android when a text field is focused', (tester) async {
    await tester.pumpWidget(wrap(child: const TextField()));

    expect(find.byKey(appTextEditBarKey), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.byKey(appTextEditBarKey), findsOneWidget);
    expect(find.byIcon(Icons.content_paste), findsOneWidget);
  });

  testWidgets('shows cut and copy after selecting text', (tester) async {
    final controller = TextEditingController(text: 'cifra');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(child: TextField(controller: controller)));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.content_cut), findsNothing);
    expect(find.byIcon(Icons.content_copy), findsNothing);

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    expect(find.byIcon(Icons.content_cut), findsOneWidget);
    expect(find.byIcon(Icons.content_copy), findsOneWidget);
    expect(find.byIcon(Icons.content_paste), findsOneWidget);

    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pump();

    expect(find.byKey(appTextEditBarKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not show the bar on desktop platforms', (tester) async {
    await tester.pumpWidget(
      wrap(platform: TargetPlatform.macOS, child: const TextField()),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.byKey(appTextEditBarKey), findsNothing);
  });

  testWidgets('hides cut and copy for obscured password fields', (tester) async {
    final controller = TextEditingController(text: 'secret');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(child: TextField(controller: controller, obscureText: true)),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    await tester.pump();

    expect(find.byIcon(Icons.content_cut), findsNothing);
    expect(find.byIcon(Icons.content_copy), findsNothing);
    expect(find.byIcon(Icons.content_paste), findsOneWidget);
  });
}
