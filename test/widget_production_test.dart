import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/widgets/widgets_exports.dart';
import '../lib/widgets/production_config.dart';
import '../lib/widgets/widget_validator.dart';
import '../lib/widgets/performance_optimizer.dart';

/// Integration tests for all Crystal Social widgets
/// Ensures all widgets are production-ready and function correctly
void main() {
  group('Widget Production Readiness Tests', () {
    
    setUpAll(() {
      // Initialize production configuration
      WidgetProductionConfig.configureLogging();
    });
    
    testWidgets('Message Bubble Widget Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleEnhanced(
              text: 'Test message',
              isMe: true,
              timestamp: DateTime.now(),
              username: 'Test User',
              auraColor: 'blue',
            ),
          ),
        ),
      );
      
      expect(find.text('Test message'), findsOneWidget);
    });
    
    testWidgets('Debug Widgets Hidden in Release', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PushNotificationTestButton(),
                DeviceUserTrackingDebugWidget(),
              ],
            ),
          ),
        ),
      );
      
      // In release mode, debug widgets should be hidden
      if (WidgetProductionConfig.environmentName == 'production') {
        expect(find.byType(PushNotificationTestButton), findsNothing);
        expect(find.byType(DeviceUserTrackingDebugWidget), findsNothing);
      }
    });
    
    test('Production Configuration Test', () {
      expect(WidgetProductionConfig.environmentName, isNotNull);
      expect(WidgetProductionConfig.networkTimeout, isA<Duration>());
      expect(WidgetProductionConfig.maxCacheSize, isA<int>());
      
      // Test feature flags
      expect(WidgetProductionConfig.isFeatureEnabled('message_bubble'), true);
      expect(WidgetProductionConfig.isFeatureEnabled('emoticon_picker'), true);
      expect(WidgetProductionConfig.isFeatureEnabled('sticker_picker'), true);
    });
    
    test('Widget Configuration Test', () {
      final stickerConfig = WidgetProductionConfig.getWidgetConfig('sticker_picker');
      expect(stickerConfig, isA<Map<String, dynamic>>());
      expect(stickerConfig['enableAnimations'], isA<bool>());
      expect(stickerConfig['maxStickersPerCategory'], isA<int>());
      
      final emoticonConfig = WidgetProductionConfig.getWidgetConfig('emoticon_picker');
      expect(emoticonConfig, isA<Map<String, dynamic>>());
      expect(emoticonConfig['maxFavorites'], isA<int>());
    });
    
    test('Release Readiness Validation', () async {
      final report = await WidgetValidator.generateReport();
      
      expect(report, isA<ReleaseReadinessReport>());
      expect(report.dependencies, isA<Map<String, bool>>());
      expect(report.widgets, isA<Map<String, String>>());
      expect(report.generatedAt, isA<DateTime>());
      
      // Generate text report
      final textReport = report.generateTextReport();
      expect(textReport, contains('CRYSTAL SOCIAL WIDGET RELEASE READINESS REPORT'));
      
      // Generate JSON report
      final jsonReport = report.toJson();
      expect(jsonReport, isA<Map<String, dynamic>>());
      expect(jsonReport['isReady'], isA<bool>());
    });
    
    group('Performance Optimization Tests', () {
      testWidgets('Optimized ListView Test', (WidgetTester tester) async {
        final items = List.generate(100, (index) => 'Item $index');
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WidgetPerformanceOptimizer.optimizedListView(
                itemCount: items.length,
                itemBuilder: (context, index) => ListTile(title: Text(items[index])),
              ),
            ),
          ),
        );
        
        expect(find.byType(ListView), findsOneWidget);
      });
      
      testWidgets('Debounced Search Field Test', (WidgetTester tester) async {
        String? lastSearch;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WidgetPerformanceOptimizer.debouncedSearchField(
                onSearchChanged: (value) => lastSearch = value,
                hintText: 'Search...',
              ),
            ),
          ),
        );
        
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search...'), findsOneWidget);
        
        // Test debouncing
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump(const Duration(milliseconds: 100));
        expect(lastSearch, isNull); // Should not trigger immediately
        
        await tester.pump(const Duration(milliseconds: 500));
        expect(lastSearch, 'test'); // Should trigger after debounce period
      });
      
      testWidgets('Lazy Widget Test', (WidgetTester tester) async {
        bool widgetBuilt = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WidgetPerformanceOptimizer.lazyWidget(
                builder: () {
                  widgetBuilt = true;
                  return const Text('Lazy Content');
                },
                placeholder: const Text('Loading...'),
              ),
            ),
          ),
        );
        
        expect(widgetBuilt, true);
        expect(find.text('Lazy Content'), findsOneWidget);
      });
    });
    
    group('Helper Function Tests', () {
      testWidgets('Debug Only Helper Test', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: debugOnly(() => const Text('Debug Widget')),
            ),
          ),
        );
        
        // Should only show in debug mode
        if (WidgetProductionConfig.enableDebugFeatures) {
          expect(find.text('Debug Widget'), findsOneWidget);
        } else {
          expect(find.text('Debug Widget'), findsNothing);
        }
      });
      
      test('Safe Print Test', () {
        // Should not throw in any mode
        expect(() => safePrint('Test message'), returnsNormally);
      });
      
      test('Safe Assert Test', () {
        // Should not throw in release mode
        expect(() => safeAssert(false, 'Test assertion'), returnsNormally);
      });
    });
  });
}
