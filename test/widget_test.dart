import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapplication/main.dart';

void main() {
  testWidgets('Noobie shows the main settlement dashboard', (tester) async {
    await tester.pumpWidget(const NoobieApp());

    expect(
        find.text('Land safer, rent smarter, settle faster.'), findsOneWidget);
    expect(find.text('Rental Import'), findsOneWidget);
    expect(find.text('Rooms worth inspecting'), findsOneWidget);
  });
}
