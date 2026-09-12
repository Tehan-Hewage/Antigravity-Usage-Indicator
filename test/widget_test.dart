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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: const AntigravityApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify presence of Gemini model label
    expect(find.text('Gemini'), findsOneWidget);
  });
}
