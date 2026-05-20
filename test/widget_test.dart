import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokoshots/src/controllers/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kokoshots/src/app.dart';
import 'package:kokoshots/src/services/database_service.dart';
import 'package:kokoshots/src/services/gemini_service.dart';
import 'package:kokoshots/src/services/media_service.dart';
import 'package:kokoshots/src/services/rate_limiter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('KokoShots home renders setup state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith((ref) {
            return AppController(
              database: DatabaseService(),
              media: MediaService(),
              gemini: GeminiService(),
              rateLimiter: RateLimiter(),
              initialStatusText: 'No screenshots indexed yet',
              isLoading: false,
            );
          }),
        ],
        child: const KokoShotsApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('KokoShots'), findsOneWidget);
    expect(find.text('SCREENSHOT MEMORY'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });
}
