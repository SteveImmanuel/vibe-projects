import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitnotes_plus/main.dart';

void main() {
  testWidgets('App boots and shows the placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitNotesApp()));
    expect(find.text('FitNotes++'), findsOneWidget);
  });
}
