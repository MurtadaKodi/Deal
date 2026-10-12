import 'package:deal/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Deal app shows role selection and buyer entry', (tester) async {
    await tester.pumpWidget(const DealApp());

    expect(find.text('Deal'), findsWidgets);
    expect(find.text('البائع'), findsOneWidget);
    expect(find.text('المشتري'), findsOneWidget);
  });
}
