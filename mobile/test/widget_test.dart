import 'package:flutter_test/flutter_test.dart';
import 'package:ems_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EmsApp());
    await tester.pumpAndSettle();

    // Verify that AuthScreen is shown (it has 'AKH' text or logo)
    // Note: Since we use SvgPicture.asset, it might need special handling in tests or just find by Type.
    // We'll just look for a widget that we know is there, like the Text 'AKH'.

    expect(find.text('AKH'), findsOneWidget);
  });
}
