// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:deal/main.dart';
import 'package:deal/services/firebase/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Deal app shows role selection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DealApp());

    expect(find.text('Deal'), findsWidgets);
    expect(find.text('اختر نوع الحساب'), findsOneWidget);
    expect(find.text('البائع'), findsOneWidget);
    expect(find.text('المشتري'), findsOneWidget);
  });

  test('username login uses a stable deal.app email alias', () {
    expect(DealAuthService.usernameToEmail('seller1'), 'seller1@deal.app');
    expect(DealAuthService.usernameToEmail('seller1@deal.app'), 'seller1@deal.app');
    expect(DealAuthService.usernameToEmail('seller1@gmail.com'), 'seller1@gmail.com');
  });
}
