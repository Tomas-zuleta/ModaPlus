import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modaplus/pages/explore_view.dart';
import 'package:modaplus/widgets/collection_card.dart';

void main() {
  testWidgets('Explore cards use the same centered category layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ExploreView(onOpenCategory: (_) {})),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CollectionCard &&
            widget.title == 'Camisas' &&
            widget.buttonText == 'Camisas',
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CollectionCard &&
            widget.title == 'Pantalones' &&
            widget.buttonText == 'Pantalones',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CollectionCard &&
            widget.title == 'Vestidos' &&
            widget.buttonText == 'Vestidos',
      ),
      findsOneWidget,
    );
  });
}
