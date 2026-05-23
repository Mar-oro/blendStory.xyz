import 'package:flutter_test/flutter_test.dart';
import 'package:blend_story_xyz/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BlendStoryApp());
    expect(find.byType(BlendStoryApp), findsOneWidget);
  });
}
