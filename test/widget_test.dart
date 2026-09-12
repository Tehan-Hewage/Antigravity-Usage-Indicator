import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antigravity_usage_indicator/app/app.dart';
import 'package:antigravity_usage_indicator/features/settings/data/settings_repository.dart';
import 'package:antigravity_usage_indicator/features/settings/presentation/providers/settings_provider.dart';

void main() {
  testWidgets('AntigravityApp launches and renders compact floating pill', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = await SettingsRepository.create();
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AntigravityApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify presence of Gemini model label
    expect(find.text('Gemini'), findsOneWidget);

    // Explicitly dispose container to cancel all background timers
    container.dispose();
  });
}
