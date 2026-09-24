import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pill_reminder/core/responsive.dart';

void main() {
  group('Responsive Breakpoint Tests', () {
    testWidgets('Detects mobile screen correctly (< 600)', (tester) async {
      tester.view.physicalSize = const Size(375 * 2, 812 * 2);
      tester.view.devicePixelRatio = 2.0;

      late bool isMob;
      late bool isTab;
      late bool isDesk;
      late bool isSmallMob;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isMob = Responsive.isMobile(context);
              isTab = Responsive.isTablet(context);
              isDesk = Responsive.isDesktop(context);
              isSmallMob = Responsive.isSmallMobile(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isMob, isTrue);
      expect(isTab, isFalse);
      expect(isDesk, isFalse);
      expect(isSmallMob, isFalse);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('Detects small mobile screen (< 360)', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;

      late bool isSmallMob;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isSmallMob = Responsive.isSmallMobile(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isSmallMob, isTrue);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('Detects tablet screen (600 - 1024)', (tester) async {
      tester.view.physicalSize = const Size(768 * 2, 1024 * 2);
      tester.view.devicePixelRatio = 2.0;

      late bool isMob;
      late bool isTab;
      late bool isDesk;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isMob = Responsive.isMobile(context);
              isTab = Responsive.isTablet(context);
              isDesk = Responsive.isDesktop(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isMob, isFalse);
      expect(isTab, isTrue);
      expect(isDesk, isFalse);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('Detects desktop screen (>= 1024)', (tester) async {
      tester.view.physicalSize = const Size(1440 * 1, 900 * 1);
      tester.view.devicePixelRatio = 1.0;

      late bool isMob;
      late bool isTab;
      late bool isDesk;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isMob = Responsive.isMobile(context);
              isTab = Responsive.isTablet(context);
              isDesk = Responsive.isDesktop(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isMob, isFalse);
      expect(isTab, isFalse);
      expect(isDesk, isTrue);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });

  group('Responsive Helper Utilities', () {
    test('calculateColumnsForWidth computes correct columns', () {
      expect(Responsive.calculateColumnsForWidth(320, minItemWidth: 260), 1);
      expect(Responsive.calculateColumnsForWidth(550, minItemWidth: 260), 2);
      expect(Responsive.calculateColumnsForWidth(850, minItemWidth: 260), 3);
      expect(Responsive.calculateColumnsForWidth(1200, minItemWidth: 260), 4);
    });

    testWidgets('Responsive.value returns correct value per device', (tester) async {
      tester.view.physicalSize = const Size(800 * 1, 600 * 1);
      tester.view.devicePixelRatio = 1.0;

      late int val;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              val = Responsive.value(
                context,
                mobile: 1,
                tablet: 2,
                desktop: 3,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(val, equals(2));

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });

  group('Responsive Widgets Layout Constraints', () {
    testWidgets('ResponsiveContentWrapper constrains maxWidth', (tester) async {
      tester.view.physicalSize = const Size(1920 * 1, 1080 * 1);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ResponsiveContentWrapper(
                maxWidth: 1200,
                child: SizedBox(
                  width: double.infinity,
                  height: 100,
                  key: Key('content_box'),
                ),
              ),
            ),
          ),
        ),
      );

      final renderBox = tester.renderObject<RenderBox>(find.byKey(const Key('content_box')));
      expect(renderBox.size.width, lessThanOrEqualTo(1200));

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('ResponsiveFormContainer constrains maxWidth to 640 by default', (tester) async {
      tester.view.physicalSize = const Size(1440 * 1, 900 * 1);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveFormContainer(
              child: SizedBox(
                width: double.infinity,
                height: 100,
                key: Key('form_box'),
              ),
            ),
          ),
        ),
      );

      final renderBox = tester.renderObject<RenderBox>(find.byKey(const Key('form_box')));
      expect(renderBox.size.width, lessThanOrEqualTo(640));

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
