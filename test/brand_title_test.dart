import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modaplus/widgets/brand_title.dart';

void main() {
  testWidgets('ModaPlus brand is visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: BrandTitle())),
    ));
    expect(find.text('MODA'), findsOneWidget);
    expect(find.text('PLUS'), findsOneWidget);
  });
}
