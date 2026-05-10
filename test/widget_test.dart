// Smart Waste Sorting — Basic Widget Test
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_11/app.dart';
import 'package:flutter_application_11/providers/scan_provider.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ScanProvider(),
        child: const SmartWasteApp(),
      ),
    );

    expect(find.text('Smart Waste Sorting — Stage 1 Complete'), findsOneWidget);
  });
}
