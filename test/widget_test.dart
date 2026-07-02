import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}