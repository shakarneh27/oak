import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('official logo asset renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Image(image: AssetImage('assets/images/logo.png')),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nouri mascot SVG parses and renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SvgPicture.asset('assets/images/nouri.svg', width: 60, height: 60),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
